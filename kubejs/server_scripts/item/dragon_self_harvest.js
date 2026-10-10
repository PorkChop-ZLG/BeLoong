// 该脚本用于 龙之生存玩家 自取冰火龙血/龙鳞（潜行 + 右键使用 龙关怀的针筒/剪刀）
// 数值参照冰火传说龙尸体的采集产出（龙鳞/龙血）；伤害为最大生命值百分比（最低 1%），生命值不足时禁止使用

const SelfHarvestDragonState = Java.loadClass('by.dragonsurvivalteam.dragonsurvival.common.capability.DragonStateProvider')
const SelfHarvestLivingEntity = Java.loadClass('net.minecraft.world.entity.LivingEntity')

// 龙种 -> 龙血 / 龙鳞（依据技能图标的元素与配色）；未列出的龙种无法自取
const SELF_HARVEST_SPECIES = {
  'dragonsurvival:cave_dragon': { blood: 'iceandfire:fire_dragon_blood', scales: 'iceandfire:dragonscales_red' },
  'dragonsurvival:tundra_dragon': { blood: 'iceandfire:ice_dragon_blood', scales: 'iceandfire:dragonscales_white' },
  'dragonsurvival:frostfire_dragon': { blood: 'iceandfire:ice_dragon_blood', scales: 'iceandfire:dragonscales_blue' },
  'dragonsurvival:sea_dragon': { blood: 'iceandfire:lightning_dragon_blood', scales: 'iceandfire:dragonscales_electric' },
  'dragonsurvival:night_striker': { blood: 'iceandfire:lightning_dragon_blood', scales: 'iceandfire:dragonscales_black' },
  'dragonsurvival:wing_kirin': { blood: 'iceandfire:lightning_dragon_blood', scales: 'iceandfire:dragonscales_copper' }
}

// 按成长值分档（整合包各龙种阶段区间一致），对应冰火龙 25/50/75/100/125 天龄；成长值 < 50（幼龙）不可自取
// shears: 每次剪下相当于冰火龙尸体一次采集（数量 天龄/25 起，上限取 4 倍），冷却 cd 秒，伤害 dmg%
// syringe: 窗口 window 秒内最多 uses 次（= 同龄冰火龙尸体最多可取龙血数），之后冷却 cd 秒，伤害 dmg%
const SELF_HARVEST_TIERS = [
  { minGrowth: 250, shears: { min: 5, max: 20, cd: 240, dmg: 1 }, syringe: { uses: 12, window: 1200, cd: 1200, dmg: 6 } },
  { minGrowth: 200, shears: { min: 4, max: 16, cd: 300, dmg: 1 }, syringe: { uses: 10, window: 1200, cd: 1200, dmg: 8 } },
  { minGrowth: 150, shears: { min: 3, max: 12, cd: 360, dmg: 2 }, syringe: { uses: 7, window: 1200, cd: 1200, dmg: 10 } },
  { minGrowth: 100, shears: { min: 2, max: 8, cd: 480, dmg: 3 }, syringe: { uses: 5, window: 1200, cd: 1200, dmg: 12 } },
  { minGrowth: 50, shears: { min: 1, max: 4, cd: 600, dmg: 4 }, syringe: { uses: 2, window: 1200, cd: 1200, dmg: 15 } }
]

// 冷却存于玩家持久数据（键名前缀），重进/重启/死亡后保留
const SELF_HARVEST_KEY = 'beloong_self_harvest_'

// 针筒与剪刀来自 Dragon Care，未安装时不注册（整个功能关闭）
if (Platform.isLoaded('dragoncare')) {
  ItemEvents.rightClicked('dragoncare:dragon_blood_syringe', selfHarvestSyringe)
  ItemEvents.rightClicked('dragoncare:scale_shears', selfHarvestShears)
}

function selfHarvestSyringe(event) {
  const ctx = selfHarvestContext(event)
  if (!ctx) return
  const { player, mapping, tier, data, now } = ctx
  if (!tier) {
    player.setStatusMessage(Text.translatable('message.kubejs.self_harvest.too_young_blood').yellow())
    return
  }
  const cfg = tier.syringe

  let windowStart = Number(data.getLong(SELF_HARVEST_KEY + 'syringe_window'))
  let uses = data.getInt(SELF_HARVEST_KEY + 'syringe_uses')
  let cooldownEnd = Number(data.getLong(SELF_HARVEST_KEY + 'syringe_cd'))
  if (cooldownEnd > now) {
    player.setStatusMessage(Text.translatable('message.kubejs.self_harvest.blood_cooldown', selfHarvestTimer(cooldownEnd - now)).red())
    return
  }

  const bottleSlot = selfHarvestFindBottle(player)
  if (bottleSlot < 0) {
    player.setStatusMessage(Text.translatable('message.kubejs.self_harvest.no_bottle').red())
    return
  }
  if (!selfHarvestCanPay(player, cfg.dmg)) return

  // 与 Dragon Care 一致：窗口过期或冷却结束后重新计数
  if ((cooldownEnd > 0 && cooldownEnd <= now) || (cooldownEnd == 0 && now - windowStart >= cfg.window * 20)) {
    windowStart = now
    uses = 0
    cooldownEnd = 0
  }
  uses++
  if (uses >= cfg.uses) cooldownEnd = now + cfg.cd * 20
  data.putLong(SELF_HARVEST_KEY + 'syringe_window', windowStart)
  data.putInt(SELF_HARVEST_KEY + 'syringe_uses', uses)
  data.putLong(SELF_HARVEST_KEY + 'syringe_cd', cooldownEnd)

  player.getInventory().getItem(bottleSlot).shrink(1)
  selfHarvestPay(player, cfg.dmg)
  player.give(Item.of(mapping.blood, 1))
  selfHarvestFinish(event)
}

function selfHarvestShears(event) {
  const ctx = selfHarvestContext(event)
  if (!ctx) return
  const { player, mapping, tier, data, now } = ctx
  if (!tier) {
    player.setStatusMessage(Text.translatable('message.kubejs.self_harvest.too_young_scales').yellow())
    return
  }
  const cfg = tier.shears

  const cooldownEnd = Number(data.getLong(SELF_HARVEST_KEY + 'shears_cd'))
  if (cooldownEnd > now) {
    player.setStatusMessage(Text.translatable('message.kubejs.self_harvest.scales_cooldown', selfHarvestTimer(cooldownEnd - now)).red())
    return
  }
  if (!selfHarvestCanPay(player, cfg.dmg)) return

  data.putLong(SELF_HARVEST_KEY + 'shears_cd', now + cfg.cd * 20)
  selfHarvestPay(player, cfg.dmg)
  player.give(Item.of(mapping.scales, cfg.min + Math.floor(Math.random() * (cfg.max - cfg.min + 1))))
  selfHarvestFinish(event)
}

// 返回 null 表示不处理（未潜行 / 不是龙 / 龙种不可自取）
// 对冰火龙右键时 Dragon Care 的实体交互先生效，不会触发物品使用，因此无需判断准星目标
function selfHarvestContext(event) {
  const player = event.player
  if (!player.isShiftKeyDown()) return null
  const state = SelfHarvestDragonState.getData(player)
  if (!state.isDragon()) return null
  const mapping = SELF_HARVEST_SPECIES[state.speciesKey().location().toString()]
  if (!mapping) {
    player.setStatusMessage(Text.translatable('message.kubejs.self_harvest.incompatible').gray())
    return null
  }
  const growth = state.getGrowth()
  return {
    player: player,
    mapping: mapping,
    tier: SELF_HARVEST_TIERS.find(t => growth >= t.minGrowth),
    data: player.persistentData,
    // KubeJS 将 Level#getGameTime 重映射为 getTime
    now: Number(player.level.getTime())
  }
}

function selfHarvestCost(player, percent) {
  return player.getMaxHealth() * Math.max(percent, 1) / 100
}

// 生命值须高于消耗，否则禁止使用
function selfHarvestCanPay(player, percent) {
  const cost = selfHarvestCost(player, percent)
  if (player.getHealth() > cost) return true
  player.setStatusMessage(Text.translatable('message.kubejs.self_harvest.not_enough_health', cost.toFixed(1)).red())
  return false
}

// 直接扣除生命值：精确百分比，不经过护甲/附魔/效果减免，也不触发受伤类技能
function selfHarvestPay(player, percent) {
  player.setHealth(player.getHealth() - selfHarvestCost(player, percent))
}

function selfHarvestFinish(event) {
  const player = event.player
  if (!player.isCreative()) event.item.hurtAndBreak(1, player, SelfHarvestLivingEntity.getSlotForHand(event.hand))
  player.getCooldowns().addCooldown(event.item.getItem(), 20)
  player.swing(event.hand, true)
}

function selfHarvestFindBottle(player) {
  const inventory = player.getInventory()
  for (let i = 0; i < inventory.getContainerSize(); i++) {
    if (inventory.getItem(i).id == 'minecraft:glass_bottle') return i
  }
  return -1
}

// 剩余冷却（整数秒，向上取整，避免冷却中显示 0）
function selfHarvestTimer(ticks) {
  return Math.ceil(ticks / 20)
}

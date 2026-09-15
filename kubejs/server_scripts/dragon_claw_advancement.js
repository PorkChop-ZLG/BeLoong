// 『化龙』龙之利爪 —— 空手击杀检测
//
// ============================ 为什么需要脚本 ============================
// 进度要求「主手为空时击杀任意生物」，这一条**无法用纯数据包表达**：
//
//  1. 原版 55 个进度触发器里没有条件能表达「主手为空」。
//     EntityEquipmentPredicate 的 mainhand 字段类型是 ItemPredicate，而
//     ItemPredicate.test() 在 items 缺省时恒返回 true（已核对原版源码），
//     它只能表达「是某个物品」，无法表达「没有任何物品」。
//
//  2. KubeJS 2101 也不能注册自定义判定触发器（已核对 KubeJS 源码）：
//       - RegistryEventHandler 只处理 Registries.ATTRIBUTE
//       - BuiltinKubeJSPlugin.registerServerRegistries 不含 Registries.TRIGGER_TYPE
//       - KubeJSPlugin.registerClasses 是空实现
//     而 trigger_type 是代码注册表，数据包只能引用、不能定义。
//
// 故采用等效实现：事件监听 + minecraft:impossible 触发器。
// 脚本判定通过后调用玩家 unlockAdvancement() 解锁进度。
//
// ============================ 换手机制的处理 ============================
// 龙之生存对玩家 Player.attack() 做了整体换手，这是本脚本存在的核心理由：
//   PlayerStartMixin (priority = 1,     attack HEAD)   → 爪牙槽有剑时把剑放进主手，
//                                                        原主手存入 storedMainHandTool
//   PlayerEndMixin   (priority = 10000, attack RETURN) → 把原主手放回
// 源码注释原文：「Sets the claw sword to the main hand when attacking」。
// 即：**徒手攻击且爪牙槽有剑时，整个 attack() 期间主手是爪牙剑**。
// 击杀事件落在该窗口内，此时读 mainHandItem 会读到剑而不是「空手」，
// 本该达成的进度会被误判为失败 —— 这正是要防止的。
//
// 对策（完全不涉及爪牙槽，符合「不检查爪牙槽」的要求）：
//   attack() 不会跨越 tick 边界，而 PlayerEvents.tick 在 tick 边界调用。
//   因此「上一 tick 末记录的主手」在时间上早于本 tick 内的任何 attack() 换手，
//   等价于「下次攻击换手前的主手」。据此：
//
//     主手为空                          → 空手击杀，通过
//     主手非空 且 上一 tick 主手为空    → 本 tick 发生了「空手 → 有物」的变化，
//                                          而 attack() 的换手正是这种形状
//                                          （换手把爪牙剑从爪牙槽放进主手），通过
//     其余情况                          → 不通过
//
// 为什么第二种情况不会把「握械击杀」误判为空手：
//   DS 的换手是 attack() 内成对的（放入→还原）。若玩家攻击前握着武器 T，
//   则换手结束、本次 tick 末尾记录的主手就是 T，与击杀瞬间一致，
//   不会出现「上一 tick 为空」的形状。因此只有原本空手、被换手填入剑的那次才会命中。
// ========================================================================

const CLAW_ADVANCEMENT = 'beloong:beloong/dragon_claw'

// 上一 tick 末的主手物品 id（'' 表示空手）
const NBT_PREV_HAND = 'beloongClawPrevHand'

/** 读取物品 id，空手返回空串。 */
function handId(stack) {
  if (!stack) return ''
  const id = stack.id
  return id === null || id === undefined ? '' : String(id)
}

/** 判断是否为服务端玩家。 */
function isServerPlayer(player) {
  if (!player) return false
  if (typeof player.isServerSide !== 'function') return false
  return player.isServerSide()
}

/**
 * 记录每 tick 末的主手状态。
 * 只在状态真正变化时写入，避免每 tick 无谓改动持久化数据。
 */
PlayerEvents.tick(event => {
  const player = event.player
  if (!isServerPlayer(player)) return

  const tag = player.persistentData
  const now = handId(player.mainHandItem)
  const prev = tag.contains(NBT_PREV_HAND) ? String(tag.getString(NBT_PREV_HAND)) : null

  // prev 为 null 表示首次记录：写入但不参与判定（下一次 tick 起才有意义）
  if (prev !== now) {
    tag.putString(NBT_PREV_HAND, now)
  }
})

EntityEvents.death(event => {
  // 击杀者必须是服务端玩家（按要求不检查龙种）
  const killer = event.source ? event.source.player : null
  if (!isServerPlayer(killer)) return

  // 已解锁就不再重复处理
  if (typeof killer.isAdvancementDone === 'function'
      && killer.isAdvancementDone(CLAW_ADVANCEMENT)) {
    return
  }

  const tag = killer.persistentData
  if (!tag.contains(NBT_PREV_HAND)) return      // 尚无历史记录，本轮不判定

  const now = handId(killer.mainHandItem)
  const prev = String(tag.getString(NBT_PREV_HAND))

  // 情形一：击杀瞬间主手为空 —— 直接的空手击杀
  if (now === '') {
    killer.unlockAdvancement(CLAW_ADVANCEMENT)
    return
  }

  // 情形二：主手非空，但上一 tick 末是空的。
  // 这正是 DS 「空手 → 换入爪牙剑 → attack()」的形状。
  // 由于换手只在 attack() 内成对发生、不跨 tick，
  // 握械击杀不会呈现这种形状（见文件头说明）。
  if (prev === '') {
    killer.unlockAdvancement(CLAW_ADVANCEMENT)
  }
})

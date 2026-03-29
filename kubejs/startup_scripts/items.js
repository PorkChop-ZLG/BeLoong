// 该脚本用于 批量注册整合包专属物品 ，重启游戏后才能生效
// 贴图存放位置 kubejs\assets\kubejs\textures\item
// 本地化文件位置 kubejs\assets\kubejs\lang
StartupEvents.registry("item", (event) => {
  event.create("kubejs:tundra_icon").rarity("rare")
  event.create("kubejs:tundra_full_icon").rarity("rare")
  event.create("kubejs:slime_crown").rarity("rare").tooltip([Text.translatable('item.kubejs.slime_crown.tooltip')])
  event.create("kubejs:suspicious_looking_eye").rarity("rare").tooltip([Text.translatable('item.kubejs.suspicious_looking_eye.tooltip')])
  event.create("kubejs:worm_food").rarity("rare").tooltip([Text.translatable('item.kubejs.worm_food.tooltip')])
  event.create("kubejs:bloody_spine").rarity("rare").tooltip([Text.translatable('item.kubejs.bloody_spine.tooltip')])
  event.create("kubejs:abeemination").rarity("rare").tooltip([Text.translatable('item.kubejs.abeemination.tooltip')])
  event.create("kubejs:cave_dragon_heart").rarity("uncommon").tooltip([Text.translatable('item.kubejs.cave_dragon_heart.tooltip')])
  event.create("kubejs:forest_dragon_heart").rarity("uncommon").tooltip([Text.translatable('item.kubejs.forest_dragon_heart.tooltip')])
  event.create("kubejs:sea_dragon_heart").rarity("uncommon").tooltip([Text.translatable('item.kubejs.sea_dragon_heart.tooltip')])
  event.create("kubejs:tundra_dragon_heart").rarity("uncommon").tooltip([Text.translatable('item.kubejs.tundra_dragon_heart.tooltip')])
  event.create("kubejs:aether_dragon_heart").rarity("uncommon").tooltip([Text.translatable('item.kubejs.aether_dragon_heart.tooltip')])
  event.create("kubejs:astral_dragon_heart").rarity("uncommon").tooltip([Text.translatable('item.kubejs.astral_dragon_heart.tooltip')])
  event.create("kubejs:crystcursed_dragon_heart").rarity("uncommon").tooltip([Text.translatable('item.kubejs.crystcursed_dragon_heart.tooltip')])
  event.create("kubejs:wing_kirin_heart").rarity("uncommon").tooltip([Text.translatable('item.kubejs.wing_kirin_heart.tooltip')])
  event.create("kubejs:progenitor_dragon_heart").rarity("epic").tooltip([Text.translatable('item.kubejs.progenitor_dragon_heart.tooltip.1')]).tooltip([Text.translatable('item.kubejs.progenitor_dragon_heart.tooltip.2')])
  event.create("kubejs:progenitor_dragon_power").rarity("epic").maxStackSize(1).tooltip([Text.translatable('item.kubejs.progenitor_dragon_power.tooltip.1')]).tooltip([Text.translatable('item.kubejs.progenitor_dragon_power.tooltip.2')])
  event.create("kubejs:progenitor_dragon_scale").rarity("epic").maxStackSize(1).tooltip([Text.translatable('item.kubejs.progenitor_dragon_scale.tooltip.1')]).tooltip([Text.translatable('item.kubejs.progenitor_dragon_scale.tooltip.2')])
  event.create("kubejs:progenitor_dragon_ball").rarity("epic").maxStackSize(1).tooltip([Text.translatable('item.kubejs.progenitor_dragon_ball.tooltip.1')]).tooltip([Text.translatable('item.kubejs.progenitor_dragon_ball.tooltip.2')])
  event.create("kubejs:progenitor_dragon_breath").rarity("epic").maxStackSize(1).tooltip([Text.translatable('item.kubejs.progenitor_dragon_breath.tooltip.1')]).tooltip([Text.translatable('item.kubejs.progenitor_dragon_breath.tooltip.2')])
  // 永恒星光命名空间
  event.create("eternal_starlight:glacite_ingot").tooltip([Text.translatable('item.eternal_starlight.glacite_ingot.tooltip')])
})

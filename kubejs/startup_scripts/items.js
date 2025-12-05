// 贴图存放位置 kubejs\assets\kubejs\textures\item
// 本地化文件位置 kubejs\assets\kubejs\lang
StartupEvents.registry("item", (event) => {
  event.create("kubejs:tundra_icon").rarity("rare")
  event.create("kubejs:tundra_full_icon").rarity("rare")
  event.create("kubejs:slime_crown").rarity("epic").tooltip([Text.translatable('item.kubejs.slime_crown.tooltip')])
  event.create("kubejs:suspicious_looking_eye").rarity("epic").tooltip([Text.translatable('item.kubejs.suspicious_looking_eye.tooltip')])
  event.create("kubejs:worm_food").rarity("epic").tooltip([Text.translatable('item.kubejs.worm_food.tooltip')])
  event.create("kubejs:bloody_spine").rarity("epic").tooltip([Text.translatable('item.kubejs.bloody_spine.tooltip')])
  event.create("kubejs:abeemination").rarity("epic").tooltip([Text.translatable('item.kubejs.abeemination.tooltip')])
  event.create("kubejs:cave_dragon_heart").rarity("uncommon").tooltip([Text.translatable('item.kubejs.cave_dragon_heart.tooltip')])
  event.create("kubejs:forest_dragon_heart").rarity("uncommon").tooltip([Text.translatable('item.kubejs.forest_dragon_heart.tooltip')])
  event.create("kubejs:sea_dragon_heart").rarity("uncommon").tooltip([Text.translatable('item.kubejs.sea_dragon_heart.tooltip')])
  event.create("kubejs:tundra_dragon_heart").rarity("uncommon").tooltip([Text.translatable('item.kubejs.tundra_dragon_heart.tooltip')])
  event.create("kubejs:aether_dragon_heart").rarity("uncommon").tooltip([Text.translatable('item.kubejs.aether_dragon_heart.tooltip')])
  event.create("kubejs:astral_dragon_heart").rarity("uncommon").tooltip([Text.translatable('item.kubejs.astral_dragon_heart.tooltip')])
})

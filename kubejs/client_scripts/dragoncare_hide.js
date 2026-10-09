// 该脚本用于 在 JEI 中隐藏 龙之关怀 已关闭功能的物品
// 对应 config/dragoncare-common.toml：灰烬中毒、龙的污垢、猎人建筑均已关闭；若重新开启，需同步移除此处对应物品

if (Platform.isLoaded('dragoncare')) {
  RecipeViewerEvents.removeEntries('item', event => {
    [
      'dragoncare:ash_sensor', // 灰烬探测器（灰烬中毒）
      'dragoncare:ash_tablets', // 神秘药片（灰烬中毒）
      'dragoncare:dragon_brush', // 龙刷（龙的污垢）
      'dragoncare:burnt_sheet' // 烧焦的纸页（仅生成于猎人建筑）
    ].forEach(id => event.remove(id))
  })
}

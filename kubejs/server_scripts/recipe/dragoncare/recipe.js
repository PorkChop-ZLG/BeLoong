// 该脚本用于魔改 龙之关怀 的配方
// 移除已关闭功能的物品配方（见 config/dragoncare-common.toml 与 client_scripts/dragoncare_hide.js）

if (Platform.isLoaded('dragoncare')) {
  ServerEvents.recipes(event => {
    // 灰烬探测器、神秘药片（灰烬中毒已关闭）
    event.remove({ output: 'dragoncare:ash_sensor' })
    event.remove({ output: 'dragoncare:ash_tablets' })
    // 龙刷（龙的污垢已关闭）
    event.remove({ output: 'dragoncare:dragon_brush' })
  })
}

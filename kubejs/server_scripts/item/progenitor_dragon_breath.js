// 该脚本用于 始祖龙息，效果是获得所有龙的铁魔法联动技能

// 检测物品的右键事件
ItemEvents.rightClicked(event => {
  // 一些常量
  const item = event.item
  const player = event.player
  const server = event.server
  // 如果不是目标物品，忽略
  if (item.id !== "kubejs:progenitor_dragon_breath") return
  // 判断是否为创造模式
  if (!player.isCreative()) {
    // 不是创造模式，消耗物品
    item.count--
    // 执行函数，位置 kubejs\data\beloong\function\progenitor_dragon_power.mcfunction
    server.runCommandSilent(`execute as ${player.getName().getString()} at @s run function beloong:progenitor_dragon_breath`)
  }
})
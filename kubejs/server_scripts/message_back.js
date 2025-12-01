// 该脚本用于 玩家重生后发生信息提示
PlayerEvents.respawned(event => {
  const player = event.player
  // 本地化键名位置\kubejs\assets\kubejs\lang
  const message = Component.translatable("message.kubejs.back")
    .color("red")
  // 发送消息提示
  player.tell(message)
  // 给予 10s 抗性提升5
  player.potionEffects.add("minecraft:resistance", 200, 5)
  // 给予 10s 抗火
  player.potionEffects.add("minecraft:fire_resistance", 200, 0)
})
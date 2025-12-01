// 该脚本用于 一键生成 - 新手小屋
// 分三步执行：消耗物品，发送信息，传送玩家
ItemEvents.rightClicked(event => {
  const item = event.item
  const player = event.player
  // 获取玩家坐标，用于传送
  const x = player.x
  const y = player.y
  const z = player.z
  // 本地化键名位置\kubejs\assets\kubejs\lang
  const message = Component.translatable("message.kubejs.starter_hut")
    .color("gold")

  // 如果不是目标物品，忽略
  if (!item.id.equals("yuushya:octagon_pavilion")) return
  if (player.level.isClientSide()) return

  // 消耗 1 个物品
  item.count--

  // 发送消息
  player.tell(message)

  // 将玩家向上传送 13 格，防止卡在建筑里
  player.teleportTo(x, y + 13, z)
})
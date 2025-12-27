// 该脚本用于 修改物品的最大堆叠数量
ItemEvents.modification(event => {
  // 瓶中沙暴可堆叠到 64
  event.modify('cataclysm:sandstorm_in_a_bottle', item => {
    item.maxStackSize = 64
  })
})

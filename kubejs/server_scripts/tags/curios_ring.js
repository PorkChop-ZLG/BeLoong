// 该脚本用于 添加 戒指 饰品兼容
ServerEvents.tags('item', event => {
  event.add('curios:ring', 'cataclysm:ring_of_grudged')
})
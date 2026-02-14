// 该脚本用于 添加 腰带 饰品兼容
ServerEvents.tags('item', event => {
  event.add('curios:belt', 'cataclysm:belt_of_beginner')
  event.add('curios:belt', 'cataclysm:belt_of_monstrosity')
})
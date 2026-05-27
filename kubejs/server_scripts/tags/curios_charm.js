// 该脚本用于 添加 护符 饰品兼容
ServerEvents.tags('item', event => {
  event.add('curios:charm', 'artifacts:charm_of_sinking')
  event.add('curios:charm', 'artifacts:charm_of_shrinking')
})

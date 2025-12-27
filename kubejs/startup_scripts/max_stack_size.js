// 该脚本用于 修改物品的最大堆叠数量
ItemEvents.modification(event => {
  // 瓶中沙暴可堆叠到 64
  event.modify('cataclysm:sandstorm_in_a_bottle', item => {
    item.maxStackSize = 64
  })
  // 龙铠不再能堆叠
  // 铁龙铠
  event.modify('iceandfire:dragonarmor_iron_head', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_iron_neck', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_iron_body', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_iron_tail', item => {
    item.maxStackSize = 1
  })
  // 铜龙铠
  event.modify('iceandfire:dragonarmor_copper_head', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_copper_neck', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_copper_body', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_copper_tail', item => {
    item.maxStackSize = 1
  })
  // 银龙铠
  event.modify('iceandfire:dragonarmor_silver_head', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_silver_neck', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_silver_body', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_silver_tail', item => {
    item.maxStackSize = 1
  })
  // 金龙铠
  event.modify('iceandfire:dragonarmor_gold_head', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_gold_neck', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_gold_body', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_gold_tail', item => {
    item.maxStackSize = 1
  })
  // 钻石龙铠
  event.modify('iceandfire:dragonarmor_diamond_head', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_diamond_neck', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_diamond_body', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_diamond_tail', item => {
    item.maxStackSize = 1
  })
  // 下界合金龙铠
  event.modify('iceandfire:dragonarmor_netherite_head', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_netherite_neck', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_netherite_body', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_netherite_tail', item => {
    item.maxStackSize = 1
  })
  // 炎钢龙铠
  event.modify('iceandfire:dragonarmor_dragon_steel_fire_head', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_dragon_steel_fire_neck', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_dragon_steel_fire_body', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_dragon_steel_fire_tail', item => {
    item.maxStackSize = 1
  })
  // 霜钢龙铠
  event.modify('iceandfire:dragonarmor_dragon_steel_ice_head', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_dragon_steel_ice_neck', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_dragon_steel_ice_body', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_dragon_steel_ice_tail', item => {
    item.maxStackSize = 1
  })
  // 霆钢龙铠
  event.modify('iceandfire:dragonarmor_dragon_steel_lightning_head', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_dragon_steel_lightning_neck', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_dragon_steel_lightning_body', item => {
    item.maxStackSize = 1
  })
  event.modify('iceandfire:dragonarmor_dragon_steel_lightning_tail', item => {
    item.maxStackSize = 1
  })
})

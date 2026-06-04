// 该脚本用于批量魔改 物品的基础属性

// 攻击伤害
ItemEvents.modification(event => {
  // 暮色森林
  event.modify('twilightforest:ironwood_sword', item => {
    item.attackDamage = 8.0
  })
  event.modify('twilightforest:steeleaf_sword', item => {
    item.attackDamage = 9.5
  })
  event.modify('twilightforest:knightmetal_sword', item => {
    item.attackDamage = 9.5
  })
  event.modify('twilightforest:fiery_sword', item => {
    item.attackDamage = 11.0
  })
  event.modify('twilightforest:gold_minotaur_axe', item => {
    item.attackDamage = 9.5
  })
  event.modify('twilightforest:diamond_minotaur_axe', item => {
    item.attackDamage = 14.0
  })
  event.modify('twilightforest:ice_sword', item => {
    item.attackDamage = 11.0
  })
  event.modify('twilightforest:giant_sword', item => {
    item.attackDamage = 17.0
  })
  event.modify('twilightforest:glass_sword', item => {
    item.attackDamage = 99.0
  })
  // 永恒星光
  event.modify('eternal_starlight:rage_of_stars', item => {
    item.attackDamage = 19.0
  })
  event.modify('eternal_starlight:thermal_springstone_sword', item => {
    item.attackDamage = 13.0
  })
  event.modify('eternal_starlight:glacite_sword', item => {
    item.attackDamage = 13.0
  })
  event.modify('eternal_starlight:starlit_diamond_sword', item => {
    item.attackDamage = 17.0
  })
  event.modify('eternal_starlight:deepsilver_sword', item => {
    item.attackDamage = 10.0
  })
  event.modify('eternal_starlight:malarite_sword', item => {
    item.attackDamage = 11.0
  })
  event.modify('eternal_starlight:starfire_sword', item => {
    item.attackDamage = 17.0
  })
  event.modify('eternal_starlight:flowglaze_sword', item => {
    item.attackDamage = 17.0
  })
  event.modify('eternal_starlight:amaramber_sword', item => {
    item.attackDamage = 14.0
  })
  event.modify('eternal_starlight:shattered_sword', item => {
    item.attackDamage = 12.0
  })
  event.modify('eternal_starlight:energy_sword', item => {
    item.attackDamage = 13.0
  })
  event.modify('eternal_starlight:golem_steel_greatsword', item => {
    item.attackDamage = 19.0
  })
  // 深暗之园
  event.modify('undergarden:cloggrum_battleaxe', item => {
    item.attackDamage = 26.5
  })
  event.modify('undergarden:cloggrum_sword', item => {
    item.attackDamage = 16.5
  })
  event.modify('undergarden:froststeel_sword', item => {
    item.attackDamage = 14.0
  })
  event.modify('undergarden:utherium_sword', item => {
    item.attackDamage = 18.0
  })
  event.modify('undergarden:forgotten_battleaxe', item => {
    item.attackDamage = 27.0
  })
  event.modify('undergarden:forgotten_sword', item => {
    item.attackDamage = 17.0
  })
  event.modify('undergarden:spear', item => {
    item.attackDamage = 16.0
  })
})

// 最大堆叠数量
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

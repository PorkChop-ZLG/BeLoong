// 该脚本用于批量魔改 物品 的 攻击伤害

ItemEvents.modification(event => {
  // 小烦维的剑
  event.modify('xfws_swords:sculk_katana', item => {
    item.attackDamage = 19.0
  })
  event.modify('xfws_swords:meowmere', item => {
    item.attackDamage = 29.0
  })
  event.modify('xfws_swords:star_wrath', item => {
    item.attackDamage = 39.0
  })
  event.modify('xfws_swords:ark_of_the_cosmos', item => {
    item.attackDamage = 49.0
  })
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
})


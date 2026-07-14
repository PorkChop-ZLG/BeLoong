// 该脚本用于批量魔改 物品的特殊属性
// 模版来自MC百科，作者：Kogasa

// 示例：弑龙者之刃，主手持有增加龙的技能伤害，副手持有增加飞行耐力
ItemEvents.modification(event => {
  event.modify("dragonsurvival:dragon_hunter_sword", item => {
    let modifiers = item
      .item()
      .getDefaultInstance() // 获取默认属性
      .getAttributeModifiers() // 获取属性修饰符
      .withModifierAdded( // 追加新的属性修饰符
        "dragonsurvival:dragon_ability_damage", // 例如"minecraft:generic.attack_damage"，具体查看wiki
        {
          "operation": 0, // 0 = add, 1 = add-multiply, 2 = multiply
          "amount": 0.5, // 数值
          "id": "kubejs:dragon_ability_damage" // 自定义字符串，例如""kubejs:attack_damage"
        },
        "mainhand" // 槽位ID，类似的有"any","mainhand","offhand","head".
      )
      .withModifierAdded( // 追加第二个属性修饰符，可以重复这段一直加下去
        "dragonsurvival:flight_stamina", // 例如"minecraft:generic.attack_damage"，具体查看wiki
        {
          "operation": 0, // 0 = add, 1 = add-multiply, 2 = multiply
          "amount": 1.0, // 数值
          "id": "kubejs:flight_stamina" // 自定义字符串，例如""kubejs:attack_damage"
        },
        "offhand" // 槽位ID，类似的有"mainhand","offhand","head".
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
})

// 正式修改
ItemEvents.modification(event => {
  // 龙之生存
  event.modify("dragonsurvival:light_dragon_helmet", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:mana",
        {
          "operation": 0,
          "amount": 1,
          "id": "kubejs:light_dragon_helmet_mana"
        },
        "head"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("dragonsurvival:light_dragon_chestplate", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:mana",
        {
          "operation": 0,
          "amount": 3,
          "id": "kubejs:light_dragon_chestplate_mana"
        },
        "chest"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("dragonsurvival:light_dragon_leggings", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:mana",
        {
          "operation": 0,
          "amount": 2,
          "id": "kubejs:light_dragon_leggings_mana"
        },
        "legs"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("dragonsurvival:light_dragon_boots", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:mana",
        {
          "operation": 0,
          "amount": 1,
          "id": "kubejs:light_dragon_boots_mana"
        },
        "feet"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("dragonsurvival:dark_dragon_helmet", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:mana_regeneration",
        {
          "operation": 0,
          "amount": 0.01,
          "id": "kubejs:dark_dragon_helmet_mana_regeneration"
        },
        "head"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("dragonsurvival:dark_dragon_chestplate", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:mana_regeneration",
        {
          "operation": 0,
          "amount": 0.03,
          "id": "kubejs:dark_dragon_chestplate_mana_regeneration"
        },
        "chest"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("dragonsurvival:dark_dragon_leggings", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:mana_regeneration",
        {
          "operation": 0,
          "amount": 0.02,
          "id": "kubejs:dark_dragon_leggings_mana_regeneration"
        },
        "legs"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("dragonsurvival:dark_dragon_boots", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:mana_regeneration",
        {
          "operation": 0,
          "amount": 0.01,
          "id": "kubejs:light_dragon_boots_mana_regeneration"
        },
        "feet"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  // 暮色森林
  event.modify("twilightforest:ironwood_sword", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.1,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("twilightforest:steeleaf_sword", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.1,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("twilightforest:knightmetal_sword", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.1,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("twilightforest:fiery_sword", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.3,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("twilightforest:gold_minotaur_axe", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.2,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("twilightforest:diamond_minotaur_axe", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.3,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("twilightforest:ice_sword", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.2,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("twilightforest:giant_sword", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.3,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("twilightforest:glass_sword", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 1.0,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  // 永恒星光
  event.modify("eternal_starlight:rage_of_stars", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.6,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("eternal_starlight:thermal_springstone_sword", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.4,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("eternal_starlight:glacite_sword", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.4,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("eternal_starlight:starlit_diamond_sword", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.5,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("eternal_starlight:deepsilver_sword", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.4,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("eternal_starlight:malarite_sword", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.4,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("eternal_starlight:starfire_sword", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.5,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("eternal_starlight:flowglaze_sword", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.5,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("eternal_starlight:amaramber_sword", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.4,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("eternal_starlight:shattered_sword", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.4,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("eternal_starlight:energy_sword", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.5,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
  event.modify("eternal_starlight:golem_steel_greatsword", item => {
    let modifiers = item
      .item()
      .getDefaultInstance()
      .getAttributeModifiers()
      .withModifierAdded(
        "dragonsurvival:dragon_ability_damage",
        {
          "operation": 0,
          "amount": 0.6,
          "id": "kubejs:dragon_ability_damage"
        },
        "offhand"
      )
      .modifiers();
    item.setAttributeModifiersWithTooltip(modifiers);
  })
})

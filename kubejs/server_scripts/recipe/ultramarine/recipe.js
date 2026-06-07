// 该脚本用于魔改 群青 的配方
ServerEvents.recipes(event => {
    // 东方秘术的玉 合成 群青的玉
    event.shapeless(
        Item.of('ultramarine:jade', 2),
        [
            'iss_magicfromtheeast:jade',
            'iss_magicfromtheeast:jade'
        ]
    )
    // 群青的玉 合成 东方秘术的玉
    event.shapeless(
        Item.of('iss_magicfromtheeast:jade', 2),
        [
            'ultramarine:jade',
            'ultramarine:jade'
        ]
    )
    // 粗赤铁 = 熔炉 = 铁锭
    event.smelting('minecraft:iron_ingot', 'ultramarine:raw_hematite', 0.7, 200)
    // 赤铁矿 = 熔炉 = 铁锭
    event.smelting('minecraft:iron_ingot', 'ultramarine:hematite_ore', 0.7, 200)
    // 深层赤铁矿 = 熔炉 = 铁锭
    event.smelting('minecraft:iron_ingot', 'ultramarine:deepslate_hematite_ore', 0.7, 200)
    // 粗赤铁 = 高炉 = 铁锭
    event.blasting('minecraft:iron_ingot', 'ultramarine:raw_hematite', 0.7, 100)
    // 赤铁矿 = 高炉 = 铁锭
    event.blasting('minecraft:iron_ingot', 'ultramarine:hematite_ore', 0.7, 100)
    // 深层赤铁矿 = 高炉 = 铁锭
    event.blasting('minecraft:iron_ingot', 'ultramarine:deepslate_hematite_ore', 0.7, 100)
    // 石英 + 白松石粉 = 砖窑 = 石英块
    event.custom(
        {
            "type": "ultramarine:composite_smelting",
            "cookingtime": 6000,
            "experience": 10.0,
            "primary_ingredient": {
                "item": "minecraft:quartz"
            },
            "result": {
                "count": 1,
                "id": "minecraft:quartz_block"
            },
            "secondary_ingredient": {
                "item": "ultramarine:magnesite_dust"
            }
        }
    )
    // 铁锭 + 赤铁粉 = 砖窑 = 铁块
    event.custom(
        {
            "type": "ultramarine:composite_smelting",
            "cookingtime": 6000,
            "experience": 10.0,
            "primary_ingredient": {
                "item": "minecraft:iron_ingot"
            },
            "result": {
                "count": 1,
                "id": "minecraft:iron_block"
            },
            "secondary_ingredient": {
                "item": "ultramarine:hematite_dust"
            }
        }
    )
    // 青金石 + 钴粉 = 砖窑 = 青金石块
    event.custom(
        {
            "type": "ultramarine:composite_smelting",
            "cookingtime": 6000,
            "experience": 10.0,
            "primary_ingredient": {
                "item": "minecraft:lapis_lazuli"
            },
            "result": {
                "count": 1,
                "id": "minecraft:lapis_block"
            },
            "secondary_ingredient": {
                "item": "ultramarine:cobalt_dust"
            }
        }
    )
})

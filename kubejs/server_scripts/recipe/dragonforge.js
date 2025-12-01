// 该脚本用于魔改 龙钢锻炉 的配方
ServerEvents.recipes(event => {
    // 移除原版 远古龙心 配方
    event.remove({ id: 'dragonsurvival:elder_dragon_heart' })
    // 下界合金锭 + 脆弱龙心 = 龙炎煅炉 = 远古龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 200,
            "input": {
                "item": "minecraft:netherite_ingot"
            },
            "blood": {
                "item": "dragonsurvival:weak_dragon_heart"
            },
            "result": {
                "id": "dragonsurvival:elder_dragon_heart"
            }
        }
    )
    // 下界合金锭 + 脆弱龙心 = 龙霜煅炉 = 远古龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 200,
            "input": {
                "item": "minecraft:netherite_ingot"
            },
            "blood": {
                "item": "dragonsurvival:weak_dragon_heart"
            },
            "result": {
                "id": "dragonsurvival:elder_dragon_heart"
            }
        }
    )
    // 下界合金锭 + 脆弱龙心 = 龙霆煅炉 = 远古龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 200,
            "input": {
                "item": "minecraft:netherite_ingot"
            },
            "blood": {
                "item": "dragonsurvival:weak_dragon_heart"
            },
            "result": {
                "id": "dragonsurvival:elder_dragon_heart"
            }
        }
    )
    // 绯夜脂锭 + 火龙血 = 龙炎煅炉 = 热泉石锭
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 300,
            "input": {
                "item": "eternal_starlight:amaramber_ingot"
            },
            "blood": {
                "item": "iceandfire:fire_dragon_blood"
            },
            "result": {
                "id": "eternal_starlight:thermal_springstone_ingot"
            }
        }
    )
    // 绯夜脂锭 + 冰龙血 = 龙霜煅炉 = 沼泽银锭
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 300,
            "input": {
                "item": "eternal_starlight:amaramber_ingot"
            },
            "blood": {
                "item": "iceandfire:ice_dragon_blood"
            },
            "result": {
                "id": "eternal_starlight:swamp_silver_ingot"
            }
        }
    )
    // 绯夜脂锭 + 电龙血 = 龙霆煅炉 = 天赐锭
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 300,
            "input": {
                "item": "eternal_starlight:amaramber_ingot"
            },
            "blood": {
                "item": "iceandfire:lightning_dragon_blood"
            },
            "result": {
                "id": "eternal_starlight:aethersent_ingot"
            }
        }
    )
})
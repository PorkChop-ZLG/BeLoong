// 该脚本用于魔改合成类型 龙钢锻炉

ServerEvents.recipes(event => {
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
    // 绯夜脂锭 + 冰龙血 = 龙霜煅炉 = 永冻石锭
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
                "id": "eternal_starlight:glacite_ingot"
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
    // 远古龙心 + 火魔源 = 龙炎煅炉 = 洞穴龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:fire_essence"
            },
            "result": {
                "id": "kubejs:cave_dragon_heart"
            }
        }
    )
    // 远古龙心 + 火魔源 = 龙霜煅炉 = 洞穴龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:fire_essence"
            },
            "result": {
                "id": "kubejs:cave_dragon_heart"
            }
        }
    )
    // 远古龙心 + 火魔源 = 龙霆煅炉 = 洞穴龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:fire_essence"
            },
            "result": {
                "id": "kubejs:cave_dragon_heart"
            }
        }
    )
    // 远古龙心 + 木魔源 = 龙炎煅炉 = 森林龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:wood_essence"
            },
            "result": {
                "id": "kubejs:forest_dragon_heart"
            }
        }
    )
    // 远古龙心 + 木魔源 = 龙霜煅炉 = 森林龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:wood_essence"
            },
            "result": {
                "id": "kubejs:forest_dragon_heart"
            }
        }
    )
    // 远古龙心 + 木魔源 = 龙霆煅炉 = 森林龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:wood_essence"
            },
            "result": {
                "id": "kubejs:forest_dragon_heart"
            }
        }
    )
    // 远古龙心 + 水魔源 = 龙炎煅炉 = 海洋龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:water_essence"
            },
            "result": {
                "id": "kubejs:sea_dragon_heart"
            }
        }
    )
    // 远古龙心 + 水魔源 = 龙霜煅炉 = 海洋龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:water_essence"
            },
            "result": {
                "id": "kubejs:sea_dragon_heart"
            }
        }
    )
    // 远古龙心 + 水魔源 = 龙霆煅炉 = 海洋龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:water_essence"
            },
            "result": {
                "id": "kubejs:sea_dragon_heart"
            }
        }
    )
    // 远古龙心 + 冰魔源 = 龙炎煅炉 = 苔原龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:ice_essence"
            },
            "result": {
                "id": "kubejs:tundra_dragon_heart"
            }
        }
    )
    // 远古龙心 + 冰魔源 = 龙霜煅炉 = 苔原龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:ice_essence"
            },
            "result": {
                "id": "kubejs:tundra_dragon_heart"
            }
        }
    )
    // 远古龙心 + 冰魔源 = 龙霆煅炉 = 苔原龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:ice_essence"
            },
            "result": {
                "id": "kubejs:tundra_dragon_heart"
            }
        }
    )
    // 远古龙心 + 风魔源 = 龙炎煅炉 = 以太龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:wind_essence"
            },
            "result": {
                "id": "kubejs:aether_dragon_heart"
            }
        }
    )
    // 远古龙心 + 风魔源 = 龙霜煅炉 = 以太龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:wind_essence"
            },
            "result": {
                "id": "kubejs:aether_dragon_heart"
            }
        }
    )
    // 远古龙心 + 风魔源 = 龙霆煅炉 = 以太龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:wind_essence"
            },
            "result": {
                "id": "kubejs:aether_dragon_heart"
            }
        }
    )
    // 远古龙心 + 土魔源 = 龙炎煅炉 = 地黄龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:earth_essence"
            },
            "result": {
                "id": "kubejs:dihuang_loong_heart"
            }
        }
    )
    // 远古龙心 + 土魔源 = 龙霜煅炉 = 地黄龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:earth_essence"
            },
            "result": {
                "id": "kubejs:dihuang_loong_heart"
            }
        }
    )
    // 远古龙心 + 土魔源 = 龙霆煅炉 = 地黄龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:earth_essence"
            },
            "result": {
                "id": "kubejs:dihuang_loong_heart"
            }
        }
    )
    // 远古龙心 + 暗魔源 = 龙炎煅炉 = 星界龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:dark_essence"
            },
            "result": {
                "id": "kubejs:astral_dragon_heart"
            }
        }
    )
    // 远古龙心 + 暗魔源 = 龙霜煅炉 = 星界龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:dark_essence"
            },
            "result": {
                "id": "kubejs:astral_dragon_heart"
            }
        }
    )
    // 远古龙心 + 暗魔源 = 龙霆煅炉 = 星界龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:dark_essence"
            },
            "result": {
                "id": "kubejs:astral_dragon_heart"
            }
        }
    )
    // 远古龙心 + 金魔源 = 龙炎煅炉 = 晶咒龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:metal_essence"
            },
            "result": {
                "id": "kubejs:crystcursed_dragon_heart"
            }
        }
    )
    // 远古龙心 + 金魔源 = 龙霜煅炉 = 晶咒龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:metal_essence"
            },
            "result": {
                "id": "kubejs:crystcursed_dragon_heart"
            }
        }
    )
    // 远古龙心 + 金魔源 = 龙霆煅炉 = 晶咒龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "beloong:metal_essence"
            },
            "result": {
                "id": "kubejs:crystcursed_dragon_heart"
            }
        }
    )
    // 远古龙心 + 通仙心 = 龙炎煅炉 = 麒麟之心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "wing_kirin:wing_kirin_upgrade"
            },
            "result": {
                "id": "kubejs:wing_kirin_heart"
            }
        }
    )
    // 远古龙心 + 通仙心 = 龙霜煅炉 = 麒麟之心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "wing_kirin:wing_kirin_upgrade"
            },
            "result": {
                "id": "kubejs:wing_kirin_heart"
            }
        }
    )
    // 远古龙心 + 通仙心 = 龙霆煅炉 = 麒麟之心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "wing_kirin:wing_kirin_upgrade"
            },
            "result": {
                "id": "kubejs:wing_kirin_heart"
            }
        }
    )
    // 始祖龙心 + 始祖龙鳞 = 龙炎煅炉 = 始祖之力
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 6000,
            "input": {
                "item": "kubejs:progenitor_dragon_heart"
            },
            "blood": {
                "item": "kubejs:progenitor_dragon_scale"
            },
            "result": {
                "id": "kubejs:progenitor_dragon_power"
            }
        }
    )
    // 始祖龙心 + 始祖龙鳞 = 龙霜煅炉 = 始祖之力
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 6000,
            "input": {
                "item": "kubejs:progenitor_dragon_heart"
            },
            "blood": {
                "item": "kubejs:progenitor_dragon_scale"
            },
            "result": {
                "id": "kubejs:progenitor_dragon_power"
            }
        }
    )
    // 始祖龙心 + 始祖龙鳞 = 龙霆煅炉 = 始祖之力
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 6000,
            "input": {
                "item": "kubejs:progenitor_dragon_heart"
            },
            "blood": {
                "item": "kubejs:progenitor_dragon_scale"
            },
            "result": {
                "id": "kubejs:progenitor_dragon_power"
            }
        }
    )
})

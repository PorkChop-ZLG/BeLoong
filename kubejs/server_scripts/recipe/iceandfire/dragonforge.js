// 该脚本用于魔改合成类型 龙钢锻炉

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
    // 远古龙心 + 烈焰之眼 = 龙炎煅炉 = 洞穴龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "bosses_of_mass_destruction:blazing_eye"
            },
            "result": {
                "id": "kubejs:cave_dragon_heart"
            }
        }
    )
    // 远古龙心 + 烈焰之眼 = 龙霜煅炉 = 洞穴龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "bosses_of_mass_destruction:blazing_eye"
            },
            "result": {
                "id": "kubejs:cave_dragon_heart"
            }
        }
    )
    // 远古龙心 + 烈焰之眼 = 龙霆煅炉 = 洞穴龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "bosses_of_mass_destruction:blazing_eye"
            },
            "result": {
                "id": "kubejs:cave_dragon_heart"
            }
        }
    )
    // 远古龙心 + 水晶果实 = 龙炎煅炉 = 森林龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "bosses_of_mass_destruction:crystal_fruit"
            },
            "result": {
                "id": "kubejs:forest_dragon_heart"
            }
        }
    )
    // 远古龙心 + 水晶果实 = 龙霜煅炉 = 森林龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "bosses_of_mass_destruction:crystal_fruit"
            },
            "result": {
                "id": "kubejs:forest_dragon_heart"
            }
        }
    )
    // 远古龙心 + 水晶果实 = 龙霆煅炉 = 森林龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "bosses_of_mass_destruction:crystal_fruit"
            },
            "result": {
                "id": "kubejs:forest_dragon_heart"
            }
        }
    )
    // 远古龙心 + 风暴精华 = 龙炎煅炉 = 海洋龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "cataclysm:essence_of_the_storm"
            },
            "result": {
                "id": "kubejs:sea_dragon_heart"
            }
        }
    )
    // 远古龙心 + 风暴精华 = 龙霜煅炉 = 海洋龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "cataclysm:essence_of_the_storm"
            },
            "result": {
                "id": "kubejs:sea_dragon_heart"
            }
        }
    )
    // 远古龙心 + 风暴精华 = 龙霆煅炉 = 海洋龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "cataclysm:essence_of_the_storm"
            },
            "result": {
                "id": "kubejs:sea_dragon_heart"
            }
        }
    )
    // 远古龙心 + 古代灵魂 = 龙炎煅炉 = 苔原龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "bosses_of_mass_destruction:ancient_anima"
            },
            "result": {
                "id": "kubejs:tundra_dragon_heart"
            }
        }
    )
    // 远古龙心 + 古代灵魂 = 龙霜煅炉 = 苔原龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "bosses_of_mass_destruction:ancient_anima"
            },
            "result": {
                "id": "kubejs:tundra_dragon_heart"
            }
        }
    )
    // 远古龙心 + 古代灵魂 = 龙霆煅炉 = 苔原龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "bosses_of_mass_destruction:ancient_anima"
            },
            "result": {
                "id": "kubejs:tundra_dragon_heart"
            }
        }
    )
    // 远古龙心 + 瓶中沙暴 = 龙炎煅炉 = 以太龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "cataclysm:sandstorm_in_a_bottle"
            },
            "result": {
                "id": "kubejs:aether_dragon_heart"
            }
        }
    )
    // 远古龙心 + 瓶中沙暴 = 龙霜煅炉 = 以太龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "cataclysm:sandstorm_in_a_bottle"
            },
            "result": {
                "id": "kubejs:aether_dragon_heart"
            }
        }
    )
    // 远古龙心 + 瓶中沙暴 = 龙霆煅炉 = 以太龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "cataclysm:sandstorm_in_a_bottle"
            },
            "result": {
                "id": "kubejs:aether_dragon_heart"
            }
        }
    )
    // 远古龙心 + 黑曜石之心 = 龙炎煅炉 = 星界龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "bosses_of_mass_destruction:obsidian_heart"
            },
            "result": {
                "id": "kubejs:astral_dragon_heart"
            }
        }
    )
    // 远古龙心 + 黑曜石之心 = 龙霜煅炉 = 星界龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "bosses_of_mass_destruction:obsidian_heart"
            },
            "result": {
                "id": "kubejs:astral_dragon_heart"
            }
        }
    )
    // 远古龙心 + 黑曜石之心 = 龙霆煅炉 = 星界龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "bosses_of_mass_destruction:obsidian_heart"
            },
            "result": {
                "id": "kubejs:astral_dragon_heart"
            }
        }
    )
    // 远古龙心 + 魔法水晶 = 龙炎煅炉 = 晶咒龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "eternal_starlight:mana_crystal"
            },
            "result": {
                "id": "kubejs:crystcursed_dragon_heart"
            }
        }
    )
    // 远古龙心 + 魔法水晶 = 龙霜煅炉 = 晶咒龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "eternal_starlight:mana_crystal"
            },
            "result": {
                "id": "kubejs:crystcursed_dragon_heart"
            }
        }
    )
    // 远古龙心 + 魔法水晶 = 龙霆煅炉 = 晶咒龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "eternal_starlight:mana_crystal"
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
    // 远古龙心 + 大地水晶 = 龙炎煅炉 = 地黄龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "fire",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "eternal_starlight:terra_crystal"
            },
            "result": {
                "id": "kubejs:dihuang_loong_heart"
            }
        }
    )
    // 远古龙心 + 大地水晶 = 龙霜煅炉 = 地黄龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "ice",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "eternal_starlight:terra_crystal"
            },
            "result": {
                "id": "kubejs:dihuang_loong_heart"
            }
        }
    )
    // 远古龙心 + 大地水晶 = 龙霆煅炉 = 地黄龙心
    event.custom(
        {
            "type": "iceandfire:dragonforge",
            "dragonType": "lightning",
            "cookTime": 2400,
            "input": {
                "item": "dragonsurvival:elder_dragon_heart"
            },
            "blood": {
                "item": "eternal_starlight:terra_crystal"
            },
            "result": {
                "id": "kubejs:dihuang_loong_heart"
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

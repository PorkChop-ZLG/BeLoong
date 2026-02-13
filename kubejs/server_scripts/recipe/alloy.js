// 该脚本用于魔改 合金炉 的配方
ServerEvents.recipes(event => {
    // 所有专属龙心 = 合金炉 = 始祖龙心
    event.custom(
        {
            "type": "eternal_starlight:alloy",
            "burn_time": 6000,
            "ingredients": [
                {
                    "item": "kubejs:cave_dragon_heart"
                },
                {
                    "item": "kubejs:forest_dragon_heart"
                },
                {
                    "item": "kubejs:sea_dragon_heart"
                },
                {
                    "item": "kubejs:tundra_dragon_heart"
                },
                {
                    "item": "kubejs:aether_dragon_heart"
                },
                {
                    "item": "kubejs:astral_dragon_heart"
                }
            ],
            "results": [
                {
                    "amount": 1,
                    "item": {
                        "count": 1,
                        "id": "kubejs:progenitor_dragon_heart"
                    }
                }
            ]
        }
    )
    // 3种龙鳞块 = 合金炉 = 始祖龙鳞
    event.custom(
        {
            "type": "eternal_starlight:alloy",
            "burn_time": 6000,
            "ingredients": [
                {
                    "tag": "iceandfire:storage_blocks/scales/dragon/fire"
                },
                {
                    "tag": "iceandfire:storage_blocks/scales/dragon/fire"
                },
                {
                    "tag": "iceandfire:storage_blocks/scales/dragon/fire"
                },
                {
                    "tag": "iceandfire:storage_blocks/scales/dragon/ice"
                },
                {
                    "tag": "iceandfire:storage_blocks/scales/dragon/ice"
                },
                {
                    "tag": "iceandfire:storage_blocks/scales/dragon/ice"
                },
                {
                    "tag": "iceandfire:storage_blocks/scales/dragon/lightning"
                },
                {
                    "tag": "iceandfire:storage_blocks/scales/dragon/lightning"
                },
                {
                    "tag": "iceandfire:storage_blocks/scales/dragon/lightning"
                }
            ],
            "results": [
                {
                    "amount": 1,
                    "item": {
                        "count": 1,
                        "id": "kubejs:progenitor_dragon_scale"
                    }
                }
            ]
        }
    )
})
// 该脚本用于魔改 砧板 的配方
ServerEvents.recipes(event => {
    // 石英硫块 = 砧板 = 石英硫碎片
    event.custom(
        {
            "type": "farmersdelight:cutting",
            "ingredients": [
                {
                    "item": "eternal_starlight:thioquartz_block"
                }
            ],
            "result": [
                {
                    "item": {
                        "count": 4,
                        "id": "eternal_starlight:thioquartz_shard"
                    }
                }
            ],
            "tool": {
                "type": "farmersdelight:item_ability",
                "action": "pickaxe_dig"
            }
        }
    )
    // 红色星辉水晶块 = 砧板 = 红色星辉水晶碎片
    event.custom(
        {
            "type": "farmersdelight:cutting",
            "ingredients": [
                {
                    "item": "eternal_starlight:red_starlight_crystal_block"
                }
            ],
            "result": [
                {
                    "item": {
                        "count": 4,
                        "id": "eternal_starlight:red_starlight_crystal_shard"
                    }
                }
            ],
            "tool": {
                "type": "farmersdelight:item_ability",
                "action": "pickaxe_dig"
            }
        }
    )
    // 蓝色星辉水晶块 = 砧板 = 蓝色星辉水晶碎片
    event.custom(
        {
            "type": "farmersdelight:cutting",
            "ingredients": [
                {
                    "item": "eternal_starlight:blue_starlight_crystal_block"
                }
            ],
            "result": [
                {
                    "item": {
                        "count": 4,
                        "id": "eternal_starlight:blue_starlight_crystal_shard"
                    }
                }
            ],
            "tool": {
                "type": "farmersdelight:item_ability",
                "action": "pickaxe_dig"
            }
        }
    )
})
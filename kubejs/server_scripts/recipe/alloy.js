// 该脚本用于魔改 合金炉 的配方
ServerEvents.recipes(event => {
    // 所有专属龙心 = 合金炉 = 始祖龙心
    event.custom(
        {
            "type": "eternal_starlight:alloy",
            "burn_time": 12000,
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
})
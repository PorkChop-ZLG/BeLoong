// 该脚本用于魔改 化龍整合包 的专属配方

ServerEvents.recipes(event => {
    // 专属龙心 换成 远古龙心
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:cave_dragon_heart'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:forest_dragon_heart'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:sea_dragon_heart'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:tundra_dragon_heart'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:aether_dragon_heart'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:astral_dragon_heart'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:crystcursed_dragon_heart'
        ]
    )
    // 泰拉BOSS召唤物 换成 远古龙心
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:slime_crown'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:suspicious_looking_eye'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:worm_food'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:bloody_spine'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:abeemination'
        ]
    )
})

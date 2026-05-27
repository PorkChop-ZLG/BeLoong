// 该脚本用于魔改 冰火传说社区版 的配方
ServerEvents.recipes(event => {
    // 异兽手记
    event.remove({ id: 'iceandfire:bestiary' })
    event.shaped(Item.of('iceandfire:bestiary', 1), [
        'AAA',
        'B  ',
        '   '
    ],
        {
            A: 'dragonsurvival:elder_dragon_dust',
            B: 'minecraft:book'
        }
    )
    // 三种龙血
    event.shapeless(
        Item.of('iceandfire:fire_dragon_blood', 2),
        [
            'iceandfire:fire_dragon_blood',
            'twilightforest:fiery_blood'
        ]
    )
    event.shapeless(
        Item.of('iceandfire:ice_dragon_blood', 2),
        [
            'iceandfire:ice_dragon_blood',
            'twilightforest:fiery_blood'
        ]
    )
    event.shapeless(
        Item.of('iceandfire:lightning_dragon_blood', 2),
        [
            'iceandfire:lightning_dragon_blood',
            'twilightforest:fiery_blood'
        ]
    )
})

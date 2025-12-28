// 该脚本用于魔改 我的世界原版 的配方
ServerEvents.recipes(event => {
    // 黄绿色染料
    event.shapeless(
        Item.of('minecraft:lime_dye', 1),
        [
            'minecraft:green_dye',
            'minecraft:white_dye'
        ]
    )
    // 珠光蛙明灯
    event.shaped(Item.of('minecraft:pearlescent_froglight', 8), [
        'AAA',
        'ABA',
        'AAA'
    ],
        {
            A: 'minecraft:ochre_froglight',
            B: 'minecraft:purple_dye'
        }
    )
    // 青翠蛙明灯
    event.shaped(Item.of('minecraft:verdant_froglight', 8), [
        'AAA',
        'ABA',
        'AAA'
    ],
        {
            A: 'minecraft:ochre_froglight',
            B: 'minecraft:green_dye'
        }
    )
})

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
    // 火把花种子
    event.shaped(Item.of('minecraft:torchflower_seeds', 8), [
        'AAA',
        'ABA',
        'AAA'
    ],
        {
            A: 'minecraft:torchflower',
            B: 'minecraft:torch'
        }
    )
    // 瓶子草荚果
    event.shaped(Item.of('minecraft:pitcher_pod', 8), [
        'AAA',
        'ABA',
        'AAA'
    ],
        {
            A: 'minecraft:pitcher_plant',
            B: 'minecraft:glass_bottle'
        }
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
    // 鞍
    event.shaped(Item.of('minecraft:saddle', 1), [
        ' B ',
        'BAB'
    ],
        {
            A: '#c:ingots/iron',
            B: '#c:leathers'
        }
    )
    // 命名牌
    event.shaped(Item.of('minecraft:name_tag', 1), [
        ' A ',
        'B  '
    ],
        {
            A: '#c:paper',
            B: '#c:nuggets'
        }
    )
})

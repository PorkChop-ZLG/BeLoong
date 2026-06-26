// 该脚本用于魔改 灾变 的配方

ServerEvents.recipes(event => {
    // 末影合金块 换成 末影合金锭
    event.shapeless(
        Item.of('cataclysm:enderite_ingot', 9),
        [
            'cataclysm:enderite_block'
        ]
    )
    // 末影合金锭 合成 末影合金块
    event.shaped(Item.of('cataclysm:enderite_block', 1), [
        'AAA',
        'AAA',
        'AAA'
    ],
        {
            A: 'cataclysm:enderite_ingot'
        }
    )
    // 紫水晶祭坛
    event.shaped(Item.of('cataclysm:altar_of_amethyst', 1), [
        ' A ',
        'BCB',
        'DEF'
    ],
        {
            A: 'twilightforest:coronation_carpet',
            B: 'minecraft:amethyst_cluster',
            C: 'dragonsurvival:amethyst_dragon_altar',
            D: 'cataclysm:ignitium_block',
            E: 'cataclysm:cursium_block',
            F: 'cataclysm:enderite_block'
        }
    )
})

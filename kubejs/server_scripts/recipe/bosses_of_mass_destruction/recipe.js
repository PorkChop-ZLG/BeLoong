// 该脚本用于魔改 祸乱鬼魅 的配方

ServerEvents.recipes(event => {
    // 升腾台座
    event.remove({ id: 'bosses_of_mass_destruction:levitation_block' })
    event.shaped(Item.of('bosses_of_mass_destruction:levitation_block', 1), [
        ' A ',
        'BCB',
        'DED'
    ],
        {
            A: 'bosses_of_mass_destruction:ancient_anima',
            B: 'bosses_of_mass_destruction:crystal_fruit',
            C: 'bosses_of_mass_destruction:blazing_eye',
            D: '#c:obsidians',
            E: 'bosses_of_mass_destruction:obsidian_heart'
        }
    )
})

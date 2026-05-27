// 该脚本用于魔改 我们走过的生物群系 的配方

ServerEvents.recipes(event => {
    // 花环
    event.remove({ id: 'biomeswevegone:wreath' })
    event.shaped(Item.of('biomeswevegone:wreath', 1), [
        'AAA',
        'A A',
        'AAA'
    ],
        {
            A: '#minecraft:leaves'
        }
    )
})

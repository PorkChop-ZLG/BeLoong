ServerEvents.recipes(event => {
    event.remove({ id: 'iceandfire:bestiary' })
    event.shaped(Item.of('iceandfire:bestiary', 1), [
        'AAA',
        'B  ',
        '   '
    ],
        {
            A: 'dragonsurvival:elder_dragon_dust',
            B: 'minecraft:book'
        })
})
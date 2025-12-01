ServerEvents.recipes(event => {
    event.shaped(Item.of('slide_show:projector', 1), [
        ' A ',
        'BCD',
        'EFE'
    ],
        {
            A: '#minecraft:stone_buttons',
            B: 'slide_show:slide_item',
            C: 'minecraft:observer',
            D: 'minecraft:spyglass',
            E: '#c:obsidians',
            F: 'minecraft:gold_block'
        })
    event.shapeless(Item.of('slide_show:slide_item', 1), [
        '#c:paper', 'minecraft:diamond'
    ])
})
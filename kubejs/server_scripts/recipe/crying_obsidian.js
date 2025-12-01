ServerEvents.recipes(event => {
    event.shaped(
        Item.of('minecraft:crying_obsidian', 4),
        [
            ' B ',
            'BAB',
            ' B '
        ],
        {
            A: 'dragonsurvival:star_bone',
            B: 'minecraft:obsidian'
        }
    )
})
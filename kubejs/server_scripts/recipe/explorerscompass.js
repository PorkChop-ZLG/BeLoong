ServerEvents.recipes(event => {
    event.remove({ id: 'explorerscompass:explorers_compass' })
    event.shaped(Item.of('explorerscompass:explorerscompass', 1), [
        'ABA',
        'BCB',
        'ABA'
    ],
        {
            A: 'minecraft:string',
            B: 'minecraft:crying_obsidian',
            C: 'minecraft:compass',
        })
})
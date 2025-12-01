ServerEvents.recipes(event => {
    event.remove({ id: 'transmog:void_fragment' })
    event.shaped(Item.of('transmog:void_fragment', 1), [
        'ABA',
        'BCB',
        'ABA'
    ],
        {
            A: 'dragonsurvival:elder_dragon_dust',
            B: 'minecraft:obsidian',
            C: 'minecraft:amethyst_shard'
        })
})
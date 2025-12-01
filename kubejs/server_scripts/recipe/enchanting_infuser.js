ServerEvents.recipes(event => {
    event.remove({ id: 'enchantinginfuser:enchanting_infuser' });
    event.shaped(Item.of('enchantinginfuser:enchanting_infuser', 1), [
        'ABA',
        'CDC',
        'DED'
    ],
        {
            A: 'dragonsurvival:elder_dragon_bone',
            B: 'minecraft:book',
            C: 'minecraft:amethyst_shard',
            D: 'minecraft:crying_obsidian',
            E: 'minecraft:enchanting_table'
        })
})
ServerEvents.recipes(event => {
    event.remove({ id: 'darkdoppelganger:shadow_orb' })
    event.shaped(Item.of('darkdoppelganger:shadow_orb', 1), [
        'ABA',
        'CDC',
        'AEA'
    ],
        {
            A: 'minecraft:echo_shard',
            B: 'minecraft:nether_star',
            C: 'dragonsurvival:elder_dragon_heart',
            D: 'irons_spellbooks:cooldown_upgrade_orb',
            E: 'minecraft:dragon_egg'
        })
})
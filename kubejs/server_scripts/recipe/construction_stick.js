ServerEvents.recipes(event => {
    event.remove({ id: 'constructionstick:wooden_stick' })
    event.remove({ id: 'constructionstick:copper_stick' })
    event.remove({ id: 'constructionstick:iron_stick' })
    event.remove({ id: 'constructionstick:diamond_stick' })
    event.remove({ id: 'constructionstick:netherite_stick' })
    event.shaped(Item.of('constructionstick:wooden_stick', 1), [
        ' AB',
        ' CA',
        'C  '
    ],
        {
            A: 'dragonsurvival:elder_dragon_dust',
            B: '#minecraft:planks',
            C: 'minecraft:stick'
        })
    event.shaped(Item.of('constructionstick:copper_stick', 1), [
        ' AB',
        ' CA',
        'C  '
    ],
        {
            A: 'dragonsurvival:elder_dragon_dust',
            B: 'minecraft:copper_ingot',
            C: 'minecraft:stick'
        })
    event.shaped(Item.of('constructionstick:iron_stick', 1), [
        ' AB',
        ' CA',
        'C  '
    ],
        {
            A: 'dragonsurvival:elder_dragon_dust',
            B: 'minecraft:iron_ingot',
            C: 'minecraft:stick'
        })
    event.shaped(Item.of('constructionstick:diamond_stick', 1), [
        ' AB',
        ' CA',
        'C  '
    ],
        {
            A: 'dragonsurvival:elder_dragon_dust',
            B: 'minecraft:diamond',
            C: 'minecraft:stick'
        })
    event.shaped(Item.of('constructionstick:netherite_stick', 1), [
        ' AB',
        ' CA',
        'C  '
    ],
        {
            A: 'dragonsurvival:elder_dragon_dust',
            B: 'minecraft:netherite_ingot',
            C: 'minecraft:stick'
        })
})
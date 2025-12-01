ServerEvents.recipes(event => {
    event.remove({ id: 'wands:stone_wand' })
    event.remove({ id: 'wands:stone_wand2' })
    event.remove({ id: 'wands:iron_wand' })
    event.remove({ id: 'wands:diamond_wand' })
    event.shaped(Item.of('wands:stone_wand', 1), [
        ' AB',
        ' CA',
        'C  '
    ],
        {
            A: 'dragonsurvival:elder_dragon_bone',
            B: '#c:cobblestones',
            C: 'minecraft:stick'
        })
    event.shaped(Item.of('wands:iron_wand', 1), [
        ' AB',
        ' CA',
        'C  '
    ],
        {
            A: 'dragonsurvival:elder_dragon_bone',
            B: 'minecraft:iron_ingot',
            C: 'minecraft:stick'
        })
    event.shaped(Item.of('wands:diamond_wand', 1), [
        ' AB',
        ' CA',
        'C  '
    ],
        {
            A: 'dragonsurvival:elder_dragon_bone',
            B: 'minecraft:diamond',
            C: 'minecraft:stick'
        })
    event.shaped(Item.of('wands:creative_wand', 1), [
        ' AB',
        ' CA',
        'C  '
    ],
        {
            A: 'dragonsurvival:elder_dragon_bone',
            B: 'minecraft:bedrock',
            C: 'minecraft:stick'
        })
})
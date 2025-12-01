ServerEvents.recipes(event => {
    event.remove({ id: 'dragonsurvival:skyrim_dragon_door' })
    event.shapeless(
        Item.of('dragonsurvival:skyrim_dragon_door', 1),
        [
            '#minecraft:head_armor',
            '#dragonsurvival:wooden_dragon_doors'
        ]
    )
})
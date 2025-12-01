ServerEvents.recipes(event => {
    event.remove({ id: 'terra_entity:terraprisma' })
    event.shapeless(
        Item.of('terra_entity:terraprisma', 1),
        [
            'terra_entity:summon_wooden_sword_staff',
            'terra_entity:summon_stone_sword_staff',
            'terra_entity:summon_iron_sword_staff',
            'terra_entity:summon_golden_sword_staff',
            'terra_entity:summon_diamond_sword_staff',
            'terra_entity:summon_netherite_sword_staff'
        ]
    )
})
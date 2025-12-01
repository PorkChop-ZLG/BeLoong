ServerEvents.recipes(event => {
    event.shapeless(
        Item.of('mystias_izakaya:niu_nai', 1),
        [
            'minecraft:milk_bucket'
        ]
    )
    event.shapeless(
        Item.of('minecraft:milk_bucket', 1),
        [
            'mystias_izakaya:niu_nai'
        ]
    )
    event.shapeless(
        Item.of('mystias_izakaya:ka_pei', 1),
        [
            'extradelight:coffee'
        ]
    )
})
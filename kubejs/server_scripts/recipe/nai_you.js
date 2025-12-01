ServerEvents.recipes(event => {
    event.remove({ id: 'mystias_izakaya:nai_you' })
    event.shapeless(
        Item.of('mystias_izakaya:nai_you', 4),
        [
            'minecraft:milk_bucket',
            'minecraft:sugar'
        ]
    ).replaceIngredient('minecraft:milk_bucket', 'minecraft:bucket')
})
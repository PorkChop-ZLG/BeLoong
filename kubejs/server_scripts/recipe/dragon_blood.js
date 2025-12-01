ServerEvents.recipes(event => {
    event.shapeless(
        Item.of('iceandfire:fire_dragon_blood', 2),
        [
            'iceandfire:fire_dragon_blood',
            'twilightforest:fiery_blood'
        ]
    )
    event.shapeless(
        Item.of('iceandfire:ice_dragon_blood', 2),
        [
            'iceandfire:ice_dragon_blood',
            'twilightforest:fiery_blood'
        ]
    )
    event.shapeless(
        Item.of('iceandfire:lightning_dragon_blood', 2),
        [
            'iceandfire:lightning_dragon_blood',
            'twilightforest:fiery_blood'
        ]
    )
})
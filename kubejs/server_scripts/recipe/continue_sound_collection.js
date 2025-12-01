ServerEvents.recipes(event => {
    event.remove({ id: 'melodymagic:continue_sound_collection' })
    event.shaped(Item.of('melodymagic:continue_sound_collection', 1), [
        'AAA',
        'ABA',
        'AAA'
    ],
        {
            A: 'dragonsurvival:elder_dragon_dust',
            B: 'melodymagic:sound_collection'
        })
})
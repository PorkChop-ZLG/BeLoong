ServerEvents.recipes(event => {
    event.remove({ id: 'irons_spellbooks:iron_spell_book' })
    event.shaped(Item.of('irons_spellbooks:iron_spell_book', 1), [
        'ABB',
        'ACD',
        'ABB'
    ],
        {
            A: 'minecraft:chain',
            B: 'minecraft:leather',
            C: 'irons_spellbooks:copper_spell_book',
            D: 'minecraft:paper'
        })
})
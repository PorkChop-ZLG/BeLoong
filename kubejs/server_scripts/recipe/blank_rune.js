ServerEvents.recipes(event => {
    event.shaped(Item.of('irons_spellbooks:blank_rune', 1), [
        'ABA',
        'BCB',
        'ABA'
    ],
        {
            A: 'irons_spellbooks:arcane_ingot',
            B: 'minecraft:netherite_ingot',
            C: 'irons_spellbooks:mithril_ingot'
        })
    event.shaped(Item.of('irons_spellbooks:blank_rune', 2), [
        'ABA',
        'ACA',
        'AAA'
    ],
        {
            A: 'irons_spellbooks:arcane_ingot',
            B: 'irons_spellbooks:blank_rune',
            C: 'irons_spellbooks:wisewood_bookshelf'
        })
})
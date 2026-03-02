// 该脚本用于魔改 书堆 的配方
ServerEvents.recipes(event => {
    // 美化的书堆
    event.remove({ id: 'beautify:bookstack' })
    event.shapeless(
        Item.of('beautify:bookstack', 1),
        [
            'minecraft:writable_book',
            'minecraft:writable_book',
            'minecraft:writable_book'
        ]
    )
    // 不同书堆互相转化
    event.shapeless(
        Item.of('beautify:bookstack', 1),
        [
            'irons_spellbooks:book_stack'
        ]
    )
    event.shapeless(
        Item.of('irons_spellbooks:book_stack', 1),
        [
            'beautify:bookstack'
        ]
    )
})
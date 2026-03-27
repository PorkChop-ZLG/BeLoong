// 该脚本用于魔改 方块小镇 的配方

ServerEvents.recipes(event => {
    // 实体葫芦
    event.shapeless(
        Item.of('yuushya:get_showblock_item', 1),
        [
            'yuushya:the_encyclopedia',
            'ultramarine:bottle_gourd'
        ]
    )
    // 文本方块
    event.shaped(Item.of('yuushya:textblock', 8), [
        'AAA',
        'ABA',
        'AAA'
    ],
        {
            A: 'yuushya:showblock',
            B: 'ultramarine:brush_and_inkstone'
        }
    )
})

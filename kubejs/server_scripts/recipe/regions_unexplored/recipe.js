// 该脚本用于魔改 未至之地 的配方

ServerEvents.recipes(event => {
    // 覆苔石头
    event.remove({ id: 'regions_unexplored:mossy_stone' })
    event.shapeless(
        Item.of('regions_unexplored:mossy_stone', 1),
        [
            'minecraft:stone',
            'regions_unexplored:kapok_vines'
        ]
    )
})
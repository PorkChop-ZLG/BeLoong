ServerEvents.recipes(event => {
    event.remove({ id: 'ds_aether_addon:relaxanttearecipe' })

    // 物品存在BUG，暂时禁用掉
    /*
    event.shapeless(
        Item.of('ds_aether_addon:relaxanttea', 1),
        [
            '#minecraft:flowers',
            'minecraft:potion',
            '#c:tea_leaves'
        ]
    )
    */
})

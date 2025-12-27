// 该脚本用于魔改 我的世界原版 的配方
ServerEvents.recipes(event => {
    // 黄绿色染料
    event.shapeless(
        Item.of('minecraft:lime_dye', 1),
        [
            'minecraft:green_dye',
            'minecraft:white_dye'
        ]
    )
})
    
// 该脚本用于魔改合成类型 切石机

// 下界合金锭 切成 下界合金碎片
ServerEvents.recipes(event => {
    event.stonecutting('4x minecraft:netherite_scrap', 'minecraft:netherite_ingot')
})
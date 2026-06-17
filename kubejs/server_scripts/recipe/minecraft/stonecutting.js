// 该脚本用于魔改合成类型 切石机

ServerEvents.recipes(event => {
    // 下界合金锭 切成 下界合金碎片
    event.stonecutting('2x minecraft:netherite_scrap', 'minecraft:netherite_ingot')
    // 始祖龙心 切成 专属龙心
    event.stonecutting('kubejs:cave_dragon_heart', 'kubejs:progenitor_dragon_heart')
    event.stonecutting('kubejs:forest_dragon_heart', 'kubejs:progenitor_dragon_heart')
    event.stonecutting('kubejs:sea_dragon_heart', 'kubejs:progenitor_dragon_heart')
    event.stonecutting('kubejs:tundra_dragon_heart', 'kubejs:progenitor_dragon_heart')
    event.stonecutting('kubejs:aether_dragon_heart', 'kubejs:progenitor_dragon_heart')
    event.stonecutting('kubejs:astral_dragon_heart', 'kubejs:progenitor_dragon_heart')
    event.stonecutting('kubejs:crystcursed_dragon_heart', 'kubejs:progenitor_dragon_heart')
})

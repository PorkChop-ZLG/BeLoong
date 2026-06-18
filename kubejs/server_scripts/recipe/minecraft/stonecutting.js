// 该脚本用于魔改合成类型 切石机

ServerEvents.recipes(event => {
    // 下界合金锭 切成 下界合金碎片
    event.stonecutting('4x minecraft:netherite_scrap', 'minecraft:netherite_ingot')
    // 高阶龙心 切成 低阶龙心
    event.stonecutting('2x dragonsurvival:weak_dragon_heart', 'dragonsurvival:elder_dragon_heart')
    event.stonecutting('4x dragonsurvival:heart_element', 'dragonsurvival:weak_dragon_heart')
    event.stonecutting('4x dragonsurvival:elder_dragon_bone', 'dragonsurvival:heart_element')
    event.stonecutting('4x dragonsurvival:elder_dragon_dust', 'dragonsurvival:elder_dragon_bone')

    // 始祖龙心 切成 专属龙心
    event.stonecutting('kubejs:cave_dragon_heart', 'kubejs:progenitor_dragon_heart')
    event.stonecutting('kubejs:forest_dragon_heart', 'kubejs:progenitor_dragon_heart')
    event.stonecutting('kubejs:sea_dragon_heart', 'kubejs:progenitor_dragon_heart')
    event.stonecutting('kubejs:tundra_dragon_heart', 'kubejs:progenitor_dragon_heart')
    event.stonecutting('kubejs:aether_dragon_heart', 'kubejs:progenitor_dragon_heart')
    event.stonecutting('kubejs:astral_dragon_heart', 'kubejs:progenitor_dragon_heart')
    event.stonecutting('kubejs:crystcursed_dragon_heart', 'kubejs:progenitor_dragon_heart')
    event.stonecutting('kubejs:dihuang_loong_heart', 'kubejs:progenitor_dragon_heart')
})

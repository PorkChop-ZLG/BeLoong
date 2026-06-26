// 该脚本用于魔改 化龍整合包 的专属配方

ServerEvents.recipes(event => {
    // 黎明曙光
    event.shaped(Item.of('beloong:dawn_light', 1), [
        'ABC',
        'DEF',
        'GHI'
    ],
        {
            A: 'cataclysm:lava_power_cell',
            B: 'cataclysm:witherite_ingot',
            C: 'cataclysm:void_core',
            D: 'cataclysm:ignitium_ingot',
            E: 'cataclysm:blessed_amethyst_crab_meat',
            F: 'cataclysm:cursium_ingot',
            G: 'cataclysm:crystallized_coral',
            H: 'cataclysm:ancient_metal_ingot',
            I: 'cataclysm:lacrima'
        }
    )
    // 专属龙心 换成 远古龙心
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:cave_dragon_heart'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:forest_dragon_heart'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:sea_dragon_heart'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:tundra_dragon_heart'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:aether_dragon_heart'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:astral_dragon_heart'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:crystcursed_dragon_heart'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:dihuang_loong_heart'
        ]
    )
    // 泰拉BOSS召唤物 换成 远古龙心
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:slime_crown'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:suspicious_looking_eye'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:worm_food'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:bloody_spine'
        ]
    )
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_heart', 1),
        [
            'kubejs:abeemination'
        ]
    )
    // 以太龙的佳肴
    event.shaped(Item.of('ds_aether_addon:aether_dragon_treat', 1), [
        'AAA',
        'ABA',
        'AAA'
    ],
        {
            A: 'dragonsurvival:elder_dragon_dust',
            B: 'ds_aether_addon:mistral'
        }
    )
    // 早茶
    event.remove({ id: 'ds_aether_addon:relaxanttearecipe' })
    event.shapeless(
        Item.of('ds_aether_addon:morning_tea', 1),
        [
            '#minecraft:flowers',
            'minecraft:potion',
            'twilightforest:steeleaf_ingot'
        ]
    )
    // 点心
    event.remove({ id: 'ds_aether_addon:zephyrrecipe' })
    event.shapeless(
        Item.of('ds_aether_addon:dim_sum', 1),
        [
            '#c:eggs',
            'minecraft:honeycomb',
            'ultramarine:baozi'
        ]
    )
    // 远古龙尘 换 奥术源质
    event.shaped(Item.of('irons_spellbooks:arcane_essence', 1), [
        'AA ',
        'AA ',
        '   '
    ],
        {
            A: 'dragonsurvival:elder_dragon_dust'
        }
    )
    // 奥术源质 换 远古龙尘
    event.shaped(Item.of('dragonsurvival:elder_dragon_dust', 1), [
        'AA ',
        'AA ',
        '   '
    ],
        {
            A: 'irons_spellbooks:arcane_essence'
        }
    )
    // 星尘 换成 奥术源质
    event.shapeless(
        Item.of('irons_spellbooks:arcane_essence', 2),
        [
            'star_dragon:stardust',
            'dragonsurvival:elder_dragon_dust'
        ]
    )
    // 星尘 换成 远古龙尘
    event.shapeless(
        Item.of('dragonsurvival:elder_dragon_dust', 2),
        [
            'star_dragon:stardust',
            'irons_spellbooks:arcane_essence'
        ]
    )
})

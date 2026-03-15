// 该脚本用于魔改 东方秘术 的配方
ServerEvents.recipes(event => {
    // 玉佩
    event.remove({ id: 'iss_magicfromtheeast:jade_pendant' })
    // 阴阳核心
    event.remove({ id: 'iss_magicfromtheeast:yin_yang_core' })
    event.shaped(Item.of('iss_magicfromtheeast:yin_yang_core', 1), [
        'AAB',
        'ACB',
        'ABB'
    ],
        {
            A: 'minecraft:flint',
            B: 'minecraft:quartz',
            C: '#c:raw_materials/jade'
        }
    )
    // 精炼玉锭
    event.remove({ id: 'iss_magicfromtheeast:refined_jade_ingot' })
    event.remove({ id: 'iss_magicfromtheeast:refined_jade_ingot_alternative' })
    event.shaped(Item.of('iss_magicfromtheeast:refined_jade_ingot', 1), [
        'AAA',
        'ABB',
        'BBC'
    ],
        {
            A: 'minecraft:emerald',
            B: '#c:raw_materials/jade',
            C: 'irons_spellbooks:cinder_essence'
        }
    )
    // 群青的铜钱 合成 东方秘术的一串铜钱
    event.remove({ id: 'iss_magicfromtheeast:copper_coins' })
    event.shaped(Item.of('iss_magicfromtheeast:copper_coins', 1), [
        ' AB',
        ' A ',
        'BA '
    ],
        {
            A: 'ultramarine:copper_cash_coin',
            B: 'iss_magicfromtheeast:red_string'
        }
    )
    // 东方秘术的一串铜钱 合成 群青的铜钱
    event.shapeless(
        Item.of('ultramarine:copper_cash_coin', 3),
        [
            'iss_magicfromtheeast:copper_coins'
        ]
    )
    // 锈蚀的铜钱剑
    event.shaped(Item.of('iss_magicfromtheeast:rusted_coins_sword', 1), [
        'AAA',
        'ABA',
        'AAA'
    ],
        {
            A: 'minecraft:oxidized_copper',
            B: 'iss_magicfromtheeast:coins_sword'
        }
    )
    // 村正 
    event.shaped(Item.of('iss_magicfromtheeast:muramasa', 1), [
        '  A',
        'CA ',
        'BC '
    ],
        {
            A: 'irons_spellbooks:blood_vial',
            B: 'iss_magicfromtheeast:red_shaft',
            C: 'minecraft:iron_ingot'
        }
    )
    // 奥术遗物
    event.shapeless(
        Item.of('iss_magicfromtheeast:arcane_relics', 3),
        [
            'irons_spellbooks:arcane_essence',
            '#c:raw_materials/jade',
            'iss_magicfromtheeast:bottle_of_souls'
        ]
    )
    // 道冠
    event.shaped(Item.of('iss_magicfromtheeast:taoist_helmet', 1), [
        'ABA',
        'A A',
        '   '
    ],
        {
            A: 'iss_magicfromtheeast:arcane_relics',
            B: 'iss_magicfromtheeast:yin_yang_core'
        }
    )
    // 道袍
    event.shaped(Item.of('iss_magicfromtheeast:taoist_chestplate', 1), [
        'A A',
        'ABA',
        'AAA'
    ],
        {
            A: 'iss_magicfromtheeast:arcane_relics',
            B: 'iss_magicfromtheeast:yin_yang_core'
        }
    )
    //  云袜
    event.shaped(Item.of('iss_magicfromtheeast:taoist_leggings', 1), [
        'ABA',
        'A A',
        'A A'
    ],
        {
            A: 'iss_magicfromtheeast:arcane_relics',
            B: 'iss_magicfromtheeast:yin_yang_core'
        }
    )
    // 云履
    event.shaped(Item.of('iss_magicfromtheeast:taoist_boots', 1), [
        '   ',
        'A A',
        'ABA'
    ],
        {
            A: 'iss_magicfromtheeast:arcane_relics',
            B: 'iss_magicfromtheeast:yin_yang_core'
        }
    )
    // 乌帽
    event.shaped(Item.of('iss_magicfromtheeast:onmyoji_helmet', 1), [
        'ABA',
        'A A',
        '   '
    ],
        {
            A: 'iss_magicfromtheeast:arcane_relics',
            B: 'iss_magicfromtheeast:crystallized_soul'
        }
    )
    // 狩衣
    event.shaped(Item.of('iss_magicfromtheeast:onmyoji_chestplate', 1), [
        'A A',
        'ABA',
        'AAA'
    ],
        {
            A: 'iss_magicfromtheeast:arcane_relics',
            B: 'iss_magicfromtheeast:crystallized_soul'
        }
    )
    //  指贯
    event.shaped(Item.of('iss_magicfromtheeast:onmyoji_leggings', 1), [
        'ABA',
        'A A',
        'A A'
    ],
        {
            A: 'iss_magicfromtheeast:arcane_relics',
            B: 'iss_magicfromtheeast:crystallized_soul'
        }
    )
    // 木屐
    event.shaped(Item.of('iss_magicfromtheeast:onmyoji_boots', 1), [
        '   ',
        'A A',
        'ABA'
    ],
        {
            A: 'iss_magicfromtheeast:arcane_relics',
            B: 'iss_magicfromtheeast:crystallized_soul'
        }
    )
})

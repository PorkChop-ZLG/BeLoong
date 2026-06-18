ServerEvents.recipes(event => {
    // 移除原版 龙之生存 配方
    event.remove({ id: 'dragonsurvival:elder_dragon_dust' })
    event.remove({ id: 'dragonsurvival:elder_dragon_bone' })
    event.remove({ id: 'dragonsurvival:heart_element' })
    event.remove({ id: 'dragonsurvival:weak_dragon_heart' })
    event.remove({ id: 'dragonsurvival:elder_dragon_heart' })
    event.remove({ id: 'dragonsurvival:dragon_heart_shard' })
    event.remove({ id: 'dragonsurvival:weak_dragon_heart_from_elder_dragon_heart' })
    event.remove({ id: 'dragonsurvival:weak_dragon_heart_to_dragon_shard' })
    event.remove({ id: 'dragonsurvival:elder_dragon_bone_from_heart_element' })
    // 远古龙骨
    event.shaped(Item.of('dragonsurvival:elder_dragon_bone', 1), [
        ' A ',
        'ABA',
        ' A '
    ],
        {
            A: 'dragonsurvival:elder_dragon_dust',
            B: 'minecraft:coal'
        }
    )
    // 龙心碎片
    event.shaped(Item.of('dragonsurvival:heart_element', 1), [
        ' A ',
        'ABA',
        ' A '
    ],
        {
            A: 'dragonsurvival:elder_dragon_bone',
            B: 'minecraft:gold_ingot'
        }
    )
    // 脆弱龙心
    event.shaped(Item.of('dragonsurvival:weak_dragon_heart', 1), [
        ' A ',
        'ABA',
        ' A '
    ],
        {
            A: 'dragonsurvival:elder_dragon_bone',
            B: 'minecraft:diamond'
        }
    )
})

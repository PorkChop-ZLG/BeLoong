ServerEvents.recipes(event => {
    // 移除原版永冻石配方
    event.remove({ id: 'eternal_starlight:glacite_sword' })
    event.remove({ id: 'eternal_starlight:glacite_pickaxe' })
    event.remove({ id: 'eternal_starlight:glacite_axe' })
    event.remove({ id: 'eternal_starlight:glacite_hoe' })
    event.remove({ id: 'eternal_starlight:glacite_shovel' })
    event.remove({ id: 'eternal_starlight:glacite_scythe' })
    event.remove({ id: 'eternal_starlight:glacite_helmet' })
    event.remove({ id: 'eternal_starlight:glacite_chestplate' })
    event.remove({ id: 'eternal_starlight:glacite_leggings' })
    event.remove({ id: 'eternal_starlight:glacite_boots' })
    event.remove({ id: 'eternal_starlight:glacite_shield' })
    // 永冻石剑
    event.shaped(Item.of('eternal_starlight:glacite_sword', 1), [
        ' A ',
        ' A ',
        ' B '
    ],
        {
            A: 'eternal_starlight:glacite_ingot',
            B: 'minecraft:stick'
        }
    )
    // 永冻石镐
    event.shaped(Item.of('eternal_starlight:glacite_pickaxe', 1), [
        'AAA',
        ' B ',
        ' B '
    ],
        {
            A: 'eternal_starlight:glacite_ingot',
            B: 'minecraft:stick'
        }
    )
    // 永冻石斧
    event.shaped(Item.of('eternal_starlight:glacite_axe', 1), [
        'AA ',
        'AB ',
        ' B '
    ],
        {
            A: 'eternal_starlight:glacite_ingot',
            B: 'minecraft:stick'
        }
    )
    // 永冻石锄
    event.shaped(Item.of('eternal_starlight:glacite_hoe', 1), [
        'AA ',
        ' B ',
        ' B '
    ],
        {
            A: 'eternal_starlight:glacite_ingot',
            B: 'minecraft:stick'
        }
    )
    // 永冻石锹
    event.shaped(Item.of('eternal_starlight:glacite_shovel', 1), [
        ' A ',
        ' B ',
        ' B '
    ],
        {
            A: 'eternal_starlight:glacite_ingot',
            B: 'minecraft:stick'
        }
    )
    // 永冻石战镰
    event.shaped(Item.of('eternal_starlight:glacite_scythe', 1), [
        'AAA',
        '  B',
        '  B'
    ],
        {
            A: 'eternal_starlight:glacite_ingot',
            B: 'minecraft:stick'
        }
    )
    // 永冻石头盔
    event.shaped(Item.of('eternal_starlight:glacite_helmet', 1), [
        'AAA',
        'A A',
        '   '
    ],
        {
            A: 'eternal_starlight:glacite_ingot'
        }
    )
    // 永冻石胸甲
    event.shaped(Item.of('eternal_starlight:glacite_chestplate', 1), [
        'A A',
        'AAA',
        'AAA'
    ],
        {
            A: 'eternal_starlight:glacite_ingot'
        }
    )
    // 永冻石护腿
    event.shaped(Item.of('eternal_starlight:glacite_leggings', 1), [
        'AAA',
        'A A',
        'A A'
    ],
        {
            A: 'eternal_starlight:glacite_ingot'
        }
    )
    // 永冻石靴子
    event.shaped(Item.of('eternal_starlight:glacite_boots', 1), [
        'A A',
        'A A',
        '   '
    ],
        {
            A: 'eternal_starlight:glacite_ingot'
        }
    )
    // 永冻石盾
    event.shaped(Item.of('eternal_starlight:glacite_shield', 1), [
        'BAB',
        'BBB',
        ' B '
    ],
        {
            A: 'eternal_starlight:glacite_ingot',
            B: '#minecraft:planks'
        }
    )
    // 永冻石块 = 熔炉 = 永冻石锭
    event.smelting('eternal_starlight:glacite_ingot', 'eternal_starlight:glacite_block', 1.0, 200)
    // 永冻石块 = 高炉 = 永冻石锭
    event.blasting('eternal_starlight:glacite_ingot', 'eternal_starlight:glacite_block', 1.0, 100)
})
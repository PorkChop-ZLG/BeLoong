// 该脚本用于魔改 夜雀食堂 的配方

ServerEvents.recipes(event => {
    // 奶油
    event.remove({ id: 'mystias_izakaya:nai_you' })
    event.shapeless(
        Item.of('mystias_izakaya:nai_you', 4),
        [
            'minecraft:milk_bucket',
            'minecraft:sugar'
        ]
    ).replaceIngredient('minecraft:milk_bucket', 'minecraft:bucket')
    // 牛奶
    event.shapeless(
        Item.of('mystias_izakaya:niu_nai', 1),
        [
            'minecraft:milk_bucket'
        ]
    )
    event.shapeless(
        Item.of('minecraft:milk_bucket', 1),
        [
            'mystias_izakaya:niu_nai'
        ]
    )
    // 蜂蜜
    event.remove({ id: 'mystias_izakaya:feng_mi' })
    event.shapeless(
        Item.of('mystias_izakaya:feng_mi', 1),
        [
            'minecraft:honeycomb',
            'minecraft:glass_bottle'
        ]
    )
    event.shapeless(
        Item.of('minecraft:honey_bottle', 1),
        [
            'mystias_izakaya:feng_mi'
        ]
    )
    // 可可豆
    event.remove({ id: 'mystias_izakaya:ke_ke_dou' })
    event.shapeless(
        Item.of('mystias_izakaya:ke_ke_dou', 1),
        [
            'extradelight:roasted_cocoa_beans'
        ]
    )
    event.shapeless(
        Item.of('minecraft:cocoa_beans', 1),
        [
            'mystias_izakaya:ke_ke_dou'
        ]
    )
    // 南瓜
    event.remove({ id: 'mystias_izakaya:nan_gua' })
    event.shapeless(
        Item.of('mystias_izakaya:nan_gua', 3),
        [
            'minecraft:pumpkin',
            'minecraft:pumpkin',
            'minecraft:pumpkin'
        ]
    )
    event.shapeless(
        Item.of('minecraft:pumpkin', 1),
        [
            'mystias_izakaya:nan_gua'
        ]
    )
    // 竹笋
    event.remove({ id: 'mystias_izakaya:zhu_sun' })
    event.shapeless(
        Item.of('mystias_izakaya:zhu_sun', 1),
        [
            'regions_unexplored:bamboo_sapling'
        ]
    )
    event.shapeless(
        Item.of('regions_unexplored:bamboo_sapling', 1),
        [
            'mystias_izakaya:zhu_sun'
        ]
    )
    // 咖啡
    event.shapeless(
        Item.of('mystias_izakaya:ka_pei', 1),
        [
            'extradelight:coffee'
        ]
    )
})
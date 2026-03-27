// 该脚本用于魔改合成类型 祭坛合成
ServerEvents.recipes(event => {
    // 空的魂符
    event.custom(
        {
            "type": "touhou_little_maid:altar_recipe_serializers",
            "category": "misc",
            "entity": "minecraft:item",
            "group": "altar_recipe",
            "ingredients": [
                {
                    "item": "ultramarine:xuan_paper"
                },
                {
                    "item": "iss_magicfromtheeast:bottle_of_souls"
                },
                {
                    "item": "extradelight:honey_cheesecake"
                },
                {
                    "item": "extradelight:apple_cheesecake"
                },
                {
                    "item": "extradelight:pumpkin_cheesecake"
                },
                {
                    "item": "extradelight:glow_berry_cheesecake"
                }
            ],
            "lang": "jei.touhou_little_maid.altar_craft.item_craft.result",
            "power": 0.5,
            "result": {
                "count": 1,
                "id": "touhou_little_maid:smart_slab_empty"
            }
        }
    )
    // 满的魂符
    event.custom(
        {
            "type": "touhou_little_maid:altar_recipe_serializers",
            "category": "misc",
            "entity": "minecraft:item",
            "group": "altar_recipe",
            "ingredients": [
                {
                    "item": "ultramarine:xuan_paper"
                },
                {
                    "item": "iss_magicfromtheeast:crystallized_soul"
                },
                {
                    "item": "extradelight:coffe_cake_feast"
                },
                {
                    "item": "extradelight:chocolate_cake_block"
                },
                {
                    "item": "extradelight:lemon_cucumber_cake_item"
                },
                {
                    "item": "extradelight:melon_layer_cake_item"
                }
            ],
            "lang": "jei.touhou_little_maid.altar_craft.item_craft.result",
            "power": 1.0,
            "result": {
                "count": 1,
                "id": "touhou_little_maid:smart_slab_init"
            }
        }
    )
})
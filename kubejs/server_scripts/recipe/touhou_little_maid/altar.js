// 该脚本用于魔改合成类型 祭坛合成
ServerEvents.recipes(event => {
    // 魂符
    event.custom(
        {
            "type": "touhou_little_maid:altar_recipe_serializers",
            "category": "misc",
            "entity": "minecraft:item",
            "group": "altar_recipe",
            "ingredients": [
                {
                    "tag": "minecraft:planks"
                },
                {
                    "tag": "minecraft:planks"
                },
                {
                    "tag": "minecraft:planks"
                },
                {
                    "tag": "minecraft:planks"
                },
                {
                    "item": "minecraft:stone"
                },
                {
                    "tag": "c:gems/diamond"
                }
            ],
            "lang": "jei.touhou_little_maid.altar_craft.item_craft.result",
            "power": 0.1,
            "result": {
                "count": 1,
                "id": "touhou_little_maid:bookshelf"
            }
        }
    )
})
// 该脚本用于魔改 凝注台 的配方
ServerEvents.recipes(event => {
    // 黏液块 + 澄腐团质 = 凝注台 = 史莱姆皇冠
    event.custom(
        {
            "type": "undergarden:infuser_conversion",
            "category": "purifying",
            "experience": 100.0,
            "infusing_time": 1200,
            "ingredient": {
                "item": "minecraft:slime_block"
            },
            "result": {
                "count": 1,
                "id": "kubejs:slime_crown"
            },
            "slot_type": "rogdorium"
        }
    )
    // 生眼球 + 御腐水晶 = 凝注台 = 可疑眼球
    event.custom(
        {
            "type": "undergarden:infuser_conversion",
            "category": "corrupting",
            "experience": 100.0,
            "infusing_time": 1200,
            "ingredient": {
                "item": "butchercraft:eyeball"
            },
            "result": {
                "count": 1,
                "id": "kubejs:suspicious_looking_eye"
            },
            "slot_type": "utherium"
        }
    )
    // 生大脑 + 御腐水晶 = 凝注台 = 血腥脊椎
    event.custom(
        {
            "type": "undergarden:infuser_conversion",
            "category": "corrupting",
            "experience": 100.0,
            "infusing_time": 1200,
            "ingredient": {
                "item": "butchercraft:brain"
            },
            "result": {
                "count": 1,
                "id": "kubejs:bloody_spine"
            },
            "slot_type": "utherium"
        }
    )
    // 腐肉干 + 御腐水晶 = 凝注台 = 蠕虫诱饵
    event.custom(
        {
            "type": "undergarden:infuser_conversion",
            "category": "corrupting",
            "experience": 100.0,
            "infusing_time": 1200,
            "ingredient": {
                "item": "eternal_starlight:rotten_flesh_jerky"
            },
            "result": {
                "count": 1,
                "id": "kubejs:worm_food"
            },
            "slot_type": "utherium"
        }
    )
    // 蜂蜜块 + 澄腐团质 = 凝注台 = 憎恶之蜂
    event.custom(
        {
            "type": "undergarden:infuser_conversion",
            "category": "purifying",
            "experience": 100.0,
            "infusing_time": 1200,
            "ingredient": {
                "item": "minecraft:honey_block"
            },
            "result": {
                "count": 1,
                "id": "kubejs:abeemination"
            },
            "slot_type": "rogdorium"
        }
    )
})
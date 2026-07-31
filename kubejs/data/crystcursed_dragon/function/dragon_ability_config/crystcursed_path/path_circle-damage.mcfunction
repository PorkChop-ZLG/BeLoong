##决定 圆形晶咒之径 造成的伤害
# 根据: 技能等级

##Determining the Damage Dealt by Circular Crystal Path
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main {\
    function: { \
            "type": "lookup", \
            "fallback": { \
                "type": "linear", \
                "base": 20.0, \
                "per_level_above_first": 50.0 \
            }, \
            "values": [ \
                20.0, \
                50.0, \
                100.0, \
                200.0, \
                500.0, \
                1000.0 \
            ] \
    } \
}
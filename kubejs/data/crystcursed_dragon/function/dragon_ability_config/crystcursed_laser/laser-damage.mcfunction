##决定 晶咒镭射 每次伤害判定所能造成的伤害
# 根据: 技能等级

##Determining the Damage per Hit for Crystcursed Laser
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main { \
    function: { \
            "type": "lookup", \
            "fallback": { \
                "type": "linear", \
                "base": 10.0, \
                "per_level_above_first": 10.0 \
            }, \
            "values": [ \
                10.0, \
                25.0, \
                50.0, \
                100.0 \
            ] \
    } \
}
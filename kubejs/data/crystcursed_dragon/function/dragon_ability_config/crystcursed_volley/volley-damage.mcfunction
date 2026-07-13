##决定 晶咒连矢 的伤害
# 根据: 技能等级

##Determining the Damage of Crystcursed Volley
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main { \
    function: { \
            "type": "lookup", \
            "fallback": { \
                "type": "linear", \
                "base": 15.0, \
                "per_level_above_first": 15.0 \
            }, \
            "values": [ \
                15.0, \
                15.0, \
                20.0, \
                30.0, \
                60.0, \
                120.0 \
            ] \
    } \
}
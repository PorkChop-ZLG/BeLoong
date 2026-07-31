##决定 晶咒雨 的持续时间 (tick)
# 根据: 技能等级

##Determining the Duration of Crystcursed Rain (in ticks)
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main { \
    function: { \
            "type": "lookup", \
            "fallback": { \
                "type": "linear", \
                "base": 40.0, \
                "per_level_above_first": 20.0 \
            }, \
            "values": [ \
                40.0, \
                50.0, \
                60.0, \
                70.0, \
                80.0, \
                100.0 \
            ] \
    } \
}
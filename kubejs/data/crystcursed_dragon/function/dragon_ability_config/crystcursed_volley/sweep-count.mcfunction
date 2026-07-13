##决定 追加横扫 的充能次数
# 根据: 技能等级

##Determining the Charge Count for Additional Sweep Attack
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main { \
    function: { \
            "type": "lookup", \
            "fallback": { \
                "type": "linear", \
                "base": 1.0, \
                "per_level_above_first": 1.0 \
            }, \
            "values": [ \
                1.0, \
                2.0, \
                3.0, \
                4.0, \
                5.0, \
                6.0 \
            ] \
    } \
}
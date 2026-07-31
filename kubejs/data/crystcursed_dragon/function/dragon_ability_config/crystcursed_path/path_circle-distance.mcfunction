##决定 圆形晶咒之径 每条路径的最大前进距离
# 根据: 技能等级

##Determining the Maximum Forward Distance of Each Path for Circular Crystal Path
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main {\
    function: { \
            "type": "lookup", \
            "fallback": { \
                "type": "linear", \
                "base": 4.0, \
                "per_level_above_first": 2.0 \
            }, \
            "values": [ \
                4.0, \
                6.0, \
                8.0, \
                10.0, \
                12.0, \
                14.0 \
            ] \
    } \
}
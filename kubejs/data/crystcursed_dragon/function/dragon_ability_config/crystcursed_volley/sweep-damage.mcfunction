##决定 追加横扫 造成的伤害（此处的结果将乘以晶咒连矢的伤害）
# 根据: 玩家当前的水晶数量

##Determining the Damage of the Additional Sweep Attack (This value multiplies with Crystcursed Volley's damage)
# Based on: Player's Current Crystal Count

function crystcursed_dragon:lib/level_based_value/main { \
    function: { \
            "type": "lookup", \
            "fallback": { \
                "type": "linear", \
                "base": 0.4, \
                "per_level_above_first": 0.2 \
            }, \
            "values": [ \
                0.4, \
                0.6, \
                0.8, \
                1.0, \
                1.2, \
                1.4 \
            ] \
    } \
}
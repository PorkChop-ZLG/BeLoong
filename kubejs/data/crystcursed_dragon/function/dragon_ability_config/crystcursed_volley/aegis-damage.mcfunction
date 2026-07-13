##决定 晶咒连矢 与 晶咒复仇 的 连携技 伤害
# 根据: 玩家当前的水晶数量

##Determining the Damage of the Coordinated Attack of Crystcursed Volley and Crystcursed Revenge
# Based on: Player's Current Crystal Count

function crystcursed_dragon:lib/level_based_value/main { \
    function: { \
        type: "linear", \
        base: 1f, \
        per_level_above_first: 1f \
    } \
}
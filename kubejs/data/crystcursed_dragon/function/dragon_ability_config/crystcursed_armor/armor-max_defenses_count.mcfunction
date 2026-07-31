##决定 晶咒护甲 消失前的最大受击次数
# 根据: 技能等级

##Determining the Maximum Hit Count Before Crystcursed Armor Disappears
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main {\
    function: { \
        type: "linear", \
        base: 2f, \
        per_level_above_first: 2f \
    } \
}
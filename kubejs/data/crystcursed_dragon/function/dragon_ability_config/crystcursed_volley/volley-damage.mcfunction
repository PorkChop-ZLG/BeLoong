##决定 晶咒连矢 的伤害
# 根据: 技能等级

##Determining the Damage of Crystcursed Volley
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main { \
    function: { \
        type: "linear", \
        base: 2f, \
        per_level_above_first: 2f \
    } \
}
##决定 圆形晶咒之径 造成的伤害
# 根据: 技能等级

##Determining the Damage Dealt by Circular Crystal Path
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main {\
    function: { \
        type: "linear", \
        base: 8f, \
        per_level_above_first: 8f \
    } \
}
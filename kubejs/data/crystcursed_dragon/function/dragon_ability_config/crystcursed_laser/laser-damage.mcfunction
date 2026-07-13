##决定 晶咒镭射 每次伤害判定所能造成的伤害
# 根据: 技能等级

##Determining the Damage per Hit for Crystcursed Laser
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main { \
    function: { \
        type: "clamped", \
        max: 6f, \
        min: 0f, \
        value: { \
            type: "linear", \
            base: 2f, \
            per_level_above_first: 2f \
        } \
    } \
}
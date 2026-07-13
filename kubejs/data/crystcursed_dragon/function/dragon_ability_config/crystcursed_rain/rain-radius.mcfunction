##决定 晶咒雨 的覆盖半径 (block)
# 根据: 技能等级

##Determining the Coverage Radius of Crystcursed Rain (in blocks)
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main { \
    function: { \
        type: "linear", \
        base: 4f, \
        per_level_above_first: 1f \
    } \
}
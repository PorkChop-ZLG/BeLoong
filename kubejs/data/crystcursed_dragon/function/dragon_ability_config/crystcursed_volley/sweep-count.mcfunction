##决定 追加横扫 的充能次数
# 根据: 技能等级

##Determining the Charge Count for Additional Sweep Attack
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main { \
    function: { \
        type: "linear", \
        base: 1f, \
        per_level_above_first: 1f \
    } \
}
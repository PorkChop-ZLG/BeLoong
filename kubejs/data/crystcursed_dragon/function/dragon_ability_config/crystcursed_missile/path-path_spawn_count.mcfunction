##决定 晶咒飞弹落地后 晶咒之径 的生成次数
# 根据: 技能等级

##Determining the Number of Path Spawns for the Crystal Path After Crystcursed Missile Lands
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main {\
    function: { \
        type: "linear", \
        base: 1f, \
        per_level_above_first: 1f \
    } \
}
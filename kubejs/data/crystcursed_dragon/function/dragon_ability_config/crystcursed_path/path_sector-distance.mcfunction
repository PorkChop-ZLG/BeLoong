##决定 扇形晶咒之径 每条路径的最大前进距离
# 根据: 技能等级

##Determining the Maximum Forward Distance of Each Path for Sector Crystal Path
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main {\
    function: { \
        type: "linear", \
        base: 6f, \
        per_level_above_first: 2f \
    } \
}
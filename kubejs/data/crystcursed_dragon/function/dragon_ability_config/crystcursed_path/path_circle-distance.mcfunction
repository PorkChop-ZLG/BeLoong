##决定 圆形晶咒之径 每条路径的最大前进距离
# 根据: 技能等级

##Determining the Maximum Forward Distance of Each Path for Circular Crystal Path
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main {\
    function: { \
        type: "linear", \
        base: 4f, \
        per_level_above_first: 2f \
    } \
}
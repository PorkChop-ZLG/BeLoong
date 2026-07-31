##决定 圆形晶咒之径 生成路径的条数
# 根据: 技能等级

##Determining the Number of Paths Generated for Circular Crystal Path
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main { \
    function: { \
        type: "lookup", \
        values: [10f,15f], \
        fallback: 20f \
    } \
}
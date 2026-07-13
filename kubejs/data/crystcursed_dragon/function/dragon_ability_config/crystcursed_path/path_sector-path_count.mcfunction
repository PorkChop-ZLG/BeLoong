##决定 扇形晶咒之径 生成路径的条数
# 根据: 技能等级

##Determining the Number of Paths Generated for Sector Crystal Path
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main { \
    function: { \
        type: "lookup", \
        values: [2f,2f], \
        fallback: 3f \
    } \
}
##决定 圆形晶咒之径 新路径生成时与上一条路径之间的夹角
# 根据: 技能等级

##Determining the Angle Between Consecutive Paths for Circular Crystal Path
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main { \
    function: { \
        type: "lookup", \
        values: [36f,24f], \
        fallback: 18f \
    } \
}
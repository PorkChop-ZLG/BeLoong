##决定 晶咒雨 的持续时间 (tick)
# 根据: 技能等级

##Determining the Duration of Crystcursed Rain (in ticks)
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main { \
    function: { \
        type: "lookup", \
        values: [40f,40f,50f], \
        fallback:60f \
    } \
}
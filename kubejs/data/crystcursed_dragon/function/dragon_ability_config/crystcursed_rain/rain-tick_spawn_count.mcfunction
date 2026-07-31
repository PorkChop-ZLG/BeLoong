##决定 晶咒雨 在单个tick内生成的水晶数量
# 根据: 技能等级

##Determining the Number of Crystals Spawned per Tick for Crystcursed Rain
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main {\
    function: { \
        type: "linear", \
        base: 1f, \
        per_level_above_first: 1f \
    } \
}
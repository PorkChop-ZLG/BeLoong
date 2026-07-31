##决定 晶咒镭射 的伤害判定频率
# 根据: 技能等级
# - ⚠️过低的值可能影响性能
# - 0f: 整个过程只判定一次
# - 1f: 1tick/次
# - 3f: 3tick/次

##Determining the Damage Check Frequency for Crystcursed Laser
# Based on: Skill Level
# - ⚠️ Too low a value may affect performance
# - 0f: Checks only once throughout the entire process
# - 1f: 1 tick per check
# - 3f: 3 ticks per check

function crystcursed_dragon:lib/level_based_value/main { \
    function: 4f, \
}
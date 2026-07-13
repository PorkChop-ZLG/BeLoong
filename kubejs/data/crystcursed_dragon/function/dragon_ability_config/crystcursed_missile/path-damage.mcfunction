##决定 晶咒飞弹落地后 产生的晶咒之径 能造成的伤害
# 根据: 技能等级

##Determining the Damage Dealt by the Crystal Path After Crystcursed Missile Lands
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main {\
    function: { \
        type: "linear", \
        base: 8f, \
        per_level_above_first: 8f \
    } \
}
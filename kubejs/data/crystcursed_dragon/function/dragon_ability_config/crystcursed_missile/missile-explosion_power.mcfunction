##决定 晶咒飞弹 消失时的爆炸强度
# 根据: 技能等级

##Determining the Explosion Power When Crystcursed Missile Disappears
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main {\
    function: { \
        type: "linear", \
        base: 2f, \
        per_level_above_first: 1f \
    } \
}
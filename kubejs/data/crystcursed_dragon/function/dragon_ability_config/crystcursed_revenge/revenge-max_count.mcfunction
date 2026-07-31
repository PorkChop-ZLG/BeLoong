##决定 晶咒复仇 的最大弹反统计次数（影响最大爆炸强度）
# 根据: 技能等级

##Determining the Maximum Parry Count for Crystcursed Revenge (Affects Maximum Explosion Power)
# Based on: Skill Level

function crystcursed_dragon:lib/level_based_value/main {\
    function: { \
        type: "linear", \
        base: 1f, \
        per_level_above_first: 1f \
    } \
}
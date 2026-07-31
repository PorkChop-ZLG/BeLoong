##决定 晶咒连矢 与 晶咒复仇 的 连携技 每次攻击实体将积攒的弹反计数
# 根据: `晶咒连矢`的技能等级

##Determining the Parry Count Accumulated per Entity Hit by the Coordinated Attack of Crystcursed Volley and Crystcursed Revenge
# Based on: `Crystcursed Volley`'s Skill Level

function crystcursed_dragon:lib/level_based_value/main { \
    function: { \
        type: "lookup", \
        values: [0f,0.3f,0.3f,0.3f], \
        fallback: 0.4f \
    } \
}
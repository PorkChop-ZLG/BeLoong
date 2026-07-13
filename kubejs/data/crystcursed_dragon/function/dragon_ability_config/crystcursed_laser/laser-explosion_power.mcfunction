##决定 晶咒镭射 末端产生的爆炸等级
# 根据: 技能等级
# - 需要启用数据包 `Crystcursed - Laser Hit Explosion` 此参数才有效
# - 已有世界可使用命令启用该数据包 `/datapack enable "mod/crystcursed_dragon:data/crystcursed_dragon/datapacks/laser_hit_explosion"`

##Determining the Explosion Power at the End of Crystcursed Laser
# Based on: Skill Level
# - Requires the datapack `Crystcursed - Laser Hit Explosion` to be enabled for this parameter to take effect
# - For existing worlds, enable it using `/datapack enable "mod/crystcursed_dragon:data/crystcursed_dragon/datapacks/laser_hit_explosion"`

function crystcursed_dragon:lib/level_based_value/main { \
    function: { \
        type: "clamped", \
        max: 3f, \
        min: 0f, \
        value: { \
            type: "linear", \
            base: 1f, \
            per_level_above_first: 1f \
        } \
    } \
}
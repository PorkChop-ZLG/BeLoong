# 该方程用于道具 始祖之力 给予 始祖之力技能

# 给予始祖之力
dragon-ability add @s dragonsurvival:progenitor_power
# 给予始祖庇护
dragon-ability add @s dragonsurvival:progenitor_shroud
# 龙息粒子效果
particle minecraft:dragon_breath ~ ~1 ~ 0.6 0.6 0.6 0.05 80 force @s
# 末影龙音效
playsound minecraft:entity.ender_dragon.growl master @s ~ ~ ~ 2 1
# 聊天提示,使用翻译键
tellraw @s {"translate":"message.kubejs.progenitor_power"}
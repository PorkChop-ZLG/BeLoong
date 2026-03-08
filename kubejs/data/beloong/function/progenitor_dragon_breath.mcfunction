# 该方程用于道具 始祖龙息 获得所有龙的铁魔法联动技能

dragon-ability add @s dragonsurvival:iss_fire3
dragon-ability add @s dragonsurvival:iss_fire4
dragon-ability add @s dragonsurvival:iss_nature3
dragon-ability add @s dragonsurvival:iss_nature4
dragon-ability add @s dragonsurvival:iss_lightning3
dragon-ability add @s dragonsurvival:iss_lightning4
dragon-ability add @s dragonsurvival:iss_ice3
dragon-ability add @s dragonsurvival:iss_ice4
dragon-ability add @s dragonsurvival:iss_ender3
dragon-ability add @s dragonsurvival:iss_ender4
dragon-ability add @s dragonsurvival:iss_jade3
dragon-ability add @s dragonsurvival:iss_jade4

# 村民粒子
particle minecraft:happy_villager ~ ~1 ~ 0.4 0.6 0.4 0.1 80 force @s
# 龙息粒子
particle minecraft:dragon_breath ~ ~1 ~ 0.4 0.6 0.4 0.1 80 force @s
# 进度完成音效
playsound minecraft:ui.toast.challenge_complete master @s ~ ~ ~ 1.5 1.0
# 聊天提示,使用翻译键
tellraw @s {"translate":"message.kubejs.progenitor_breath"}
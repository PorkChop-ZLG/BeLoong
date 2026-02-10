# 该方程用于修复 维度之间传送时血条显示异常的BUG
# 原理是伤害玩家再进行治疗，从而更新状态栏

# 造成0.01点伤害
damage @s 0.1 minecraft:generic
# 给予瞬间治疗1的药水效果
effect give @s minecraft:instant_health 1 0 true
# 清除进度触发器，以便下次触发
advancement revoke @a only beloong:fix_healthbar
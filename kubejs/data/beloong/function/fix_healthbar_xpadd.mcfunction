# 该方程用于修复 维度之间传送时血条显示异常的BUG
# 原理是伤害玩家再进行治疗，延迟给予经验再收走，从而更新状态栏

# 给予玩家 1 点经验值
xp add @a 1 points
# 延迟运行方程，收走经验值
schedule function beloong:fix_healthbar_xpremove 5s
# 该方程用于道具 始祖龙鳞 给予装备无法破坏

# 设置物品堆叠组件数据 unbreakable
# 头盔
item modify entity @s armor.head {function:"set_components",components:{unbreakable:{}}}
# 胸甲
item modify entity @s armor.chest {function:"set_components",components:{unbreakable:{}}}
# 护腿
item modify entity @s armor.legs {function:"set_components",components:{unbreakable:{}}}
# 靴子
item modify entity @s armor.feet {function:"set_components",components:{unbreakable:{}}}
# 村民绿色粒子效果
particle minecraft:happy_villager ~ ~1 ~ 0.6 0.6 0.6 0.1 40 force @s
# 铁砧修复装备音效
playsound minecraft:block.anvil.use master @s ~ ~ ~ 1.5 1
# 聊天提示,使用翻译键
tellraw @s {"translate":"message.kubejs.progenitor_scale"}
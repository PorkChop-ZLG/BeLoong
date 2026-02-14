# 该方程用于道具 始祖龙珠 额外添加饰品栏

# 首饰 5
curios set head @s 5
# 项链 5
curios set necklace @s 5
# 背饰 1
curios set back @s 1
# 手饰 4
curios set hands @s 4
# 戒指 10
curios set ring @s 10
# 腰带 5
curios set belt @s 5
# 脚饰 5
curios set feet @s 5
# 护符 5
curios set charm @s 5
# 配饰(泰拉饰品) 5
curios set accessory @s 11
# 魔宠饰品(魔宠) 12
curios set familiar_trinket @s 12
# 魔法书(铁魔法) 1
curios set spellbook @s 1

# 不死图腾粒子
particle minecraft:totem_of_undying ~ ~1 ~ 0.4 0.6 0.4 0.1 80 force @s
# 附魔完成音效
playsound minecraft:block.enchantment_table.use master @s ~ ~ ~ 1.5 1.0
# 信标音效
playsound minecraft:block.beacon.power_select master @s ~ ~ ~ 1.0 1.0
# 聊天提示,使用翻译键
tellraw @s {"translate":"message.kubejs.progenitor_ball"}
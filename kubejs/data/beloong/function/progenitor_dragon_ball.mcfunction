# 该方程用于道具 始祖龙珠 额外添加饰品栏

# 首饰 8
curios set head @s 8
# 项链 8
curios set necklace @s 8
# 背饰 1
curios set back @s 1
# 手饰 4
curios set hands @s 4
# 戒指 20
curios set ring @s 20
# 腰带 8
curios set belt @s 8
# 脚饰 4
curios set feet @s 4
# 护符 8
curios set charm @s 8
# 魔法书(铁魔法) 4
curios set spellbook @s 3

# 不死图腾粒子
particle minecraft:totem_of_undying ~ ~1 ~ 0.4 0.6 0.4 0.1 80 force @s
# 附魔完成音效
playsound minecraft:block.enchantment_table.use master @s ~ ~ ~ 1.5 1.0
# 信标音效
playsound minecraft:block.beacon.power_select master @s ~ ~ ~ 1.0 1.0
# 聊天提示,使用翻译键
tellraw @s {"translate":"message.kubejs.progenitor_ball"}
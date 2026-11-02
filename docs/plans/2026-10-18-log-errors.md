# 整合包日志报错清单（2026-10-18）

> 生成时间：2026-10-18
> 分析来源：`logs/latest.log`（4993 行，20:03:08.630 – 20:40:43.209）、`logs/debug.log`（37 245 行，同一会话）
> 会话结论：**正常启动 → 进入存档 → 正常退出，未产生崩溃报告**（`crash-reports/` 最新一份仍是 2026-09-27）
> 状态：仅记录问题，本次未改动任何文件
> 关联文档：[2026-08-29-log-issues.md](2026-08-29-log-issues.md)（上一份同类清单）

---

## 0. 会话概况与统计

| 项目 | 数值 |
|---|---|
| 游戏 / 加载器 | Minecraft 1.21.1 / NeoForge 21.1.248（`--fml.neoForgeVersion 21.1.248`） |
| 启动耗时 | **88.785 s**（`ModernFix: Game took 88.785 seconds to start`；2026-08-29 为 105.636 s） |
| 数据包首载 | 8.111 s |
| JEI 启动 | 8.814 s（`Recipe registry plugin is slow, took 76.55 ms`） |
| ERROR 行数 | **117 行**（按消息去重 75 条） |
| WARN 行数 | **539 行** |
| KubeJS 脚本 | startup 4/4、server **47/47**、client 0/0，**0 错误 0 警告** |
| FTB Quests | 7 章节组 / 25 章 / 845 任务 / 5 奖励表，正常加载 |
| 服务器追赶 | 出现 1 次 `Can't keep up! ... Running 2117ms or 42 ticks behind` |
| 方块小镇（Yuushya） | **0 ERROR / 67 WARN**（占全部 WARN 的 12.4%），详见 P2-13 |

按来源统计（WARN + ERROR，前 12）：

| 行数 | 来源 | 主要问题 |
|---:|---|---|
| 153 | `mixin/` | 未安装模组的类加载失败（噪音） |
| 105 | `GeckoLib/` | 78 条命名不规范 + 12 条 geometry 版本过新 + 15 条动画解析失败（另有 15 条经 STDERR 打印） |
| 53 | `ContinuityClient` | 无缝玻璃资源包 CTM 配置无效 |
| 41 | `KubeJS Server` | 配方解析失败 + `create:*` 配方被跳过 |
| 37 | `PathPackResources` | 非法资源路径（中文名/空格/拼写） |
| 36 | `Dragon Survival` | 32 饮食条目 + 2 阶段定义错误 + 1 骑乘骨骼缺失 + 1 皮肤缺失提示（INFO） |
| 21 | `FacingCameraMode` | 基岩版粒子朝向模式未实现（噪音） |
| 20 | `AttributeMap` | `forge:entity_gravity` 未知属性 |
| 18 | `ModelManager` / `BlockStateModelLoader` | 缺失模型/贴图/方块状态 |
| 14 | `ModelBakery` | 物品模型文件不存在 |
| 13 | `patchouli` | 手册引用的配方已不存在 |
| 11 | `SoundEngine` | 缺失音效事件 |

---

## 1. 严重程度定义

| 级别 | 含义 |
|---|---|
| 🔴 P1 | 高优先级：内容缺失、功能失效、数据包加载被中断 |
| 🟠 P2 | 中优先级：影响显示、兼容性、体验或性能，不阻止游戏进行 |
| 🟡 P3 | 低优先级：噪音类、环境类、第三方模组内部打包缺陷 |

---

## 🔴 P1 高优先级问题

### P1-01 星辰龙三个阶段 `crushing_growth` 越界，Dragon Survival 数据包重载抛异常

> **状态：✅ 已修复并验证（2026-10-18 22:50 重启）。** 三个阶段的 `crushing_growth` 已改为与各自 `block_destruction_growth` 一致（150 / 200 / 250）；重启后日志中 `Crushing growth` / `incorrectly defined` 均为 0 次。
>
> 注：实际物种是**星辰龙**（`star_dragon`，模组名「龙之生存：星辰龙」），不是星界龙（`astral_dragon`），原文档标题有误，已更正。

**日志（出现 2 次：初次加载 + 进入世界后重载）：**

```
[Render thread/ERROR] [Dragon Survival/]: An error was thrown while trying to reload datapacks:
java.lang.IllegalStateException: The following stages are incorrectly defined:
- Crushing growth of [star_dragon:progenitor] is not within the bounds of the dragon stage
- Crushing growth of [star_dragon:stellar] is not within the bounds of the dragon stage
- Crushing growth of [star_dragon:void] is not within the bounds of the dragon stage
```

**来源：** 整合包自制数据（不是模组问题）

**定位与修复：**

| 文件 | 行 | `growth_range` | 修复前 | 修复后 |
|---|---|---:|---:|---:|
| `kubejs/data/star_dragon/dragonsurvival/dragon_stage/stellar.json` | 9 | 150 – 200 | 120.0 ❌ | **150.0** ✅ |
| `kubejs/data/star_dragon/dragonsurvival/dragon_stage/void.json` | 9 | 200 – 250 | 120.0 ❌ | **200.0** ✅ |
| `kubejs/data/star_dragon/dragonsurvival/dragon_stage/progenitor.json` | 9 | 250 – 300 | 120.0 ❌ | **250.0** ✅ |

**原因：** Dragon Survival 要求 `destruction_data.crushing_growth` 落在该阶段的 `growth_range` 内。整合包把星辰龙的成长重排成六档（10–50 / 50–100 / 100–150 / 150–200 / 200–250 / 250–300），后三档的 `block_destruction_growth` 已按阶段下限缩放过（150 / 200 / 250），但 `crushing_growth` 还停留在模板里的 120，于是越界。

**其它龙的写法（本次修复依据）：** 遍历全部龙种模组的 `dragon_stage/*.json`，凡是带 `destruction_data` 的阶段，`crushing_growth` **必然落在 `growth_range` 内**，且通常与 `block_destruction_growth` 取同一个值（夜煞是 120/160 的特例）：

| 模组 | 阶段 | range | crushing | blockDestruction |
|---|---|---|---:|---:|
| DragonSurvival | `ancient` | 60–300 | 120 | 120 |
| wing_kirin | `ancient` | 60–300 | 120 | 120 |
| dihuang_loong | `dihuang_ancient` | 60–300 | 120 | 120 |
| annihilator_type_a | `_03` | 60–300 | 120 | 120 |
| ds_night_striker | `night_striker_ancient` | 60–300 | 120 | 160 |

**影响（修复前）：** 异常发生在 DS 的数据包重载监听器内，本次重载的 DS 数据不会完整应用，星辰龙的阶段定义可能整体回退（成长阶段、属性、破坏规则）。

**验证方式：** **完全重启游戏**（`/reload` 不会重新触发 DS 的 datapack 校验），重启后日志中不应再出现 `The following stages are incorrectly defined`。

---

### P1-02 `aether_body` 标记为可骑乘，但自定义模型缺少 `MountingBone`

**日志（进入世界时报 1 次）：**

```
[Render thread/ERROR] [Dragon Survival/]:
Dragon body [dragonsurvival:aether_body] is marked as rideable,
but model [dragonsurvival:geo/test_model.geo.json] does not contain the required mounting bone [MountingBone].
```

**定位：**

- `kubejs/data/dragonsurvival/dragonsurvival/dragon_body/aether_body.json:3` → `"model": "dragonsurvival:test_model"`
- 模型文件：`kubejs/assets/dragonsurvival/geo/test_model.geo.json`（`format_version 1.12.0`，**无 `MountingBone`**）
- 对照：模组自带的 `assets/dragonsurvival/geo/dragon_model.geo.json` 含 `MountingBone`

**附带发现：** 同一目录下的 `qinglong.geo.json`、`liebel.geo.json` 同样没有 `MountingBone`，只是这两个是人形躯体、未被判定为可骑乘，所以没报错。另外 `aether_body.json` 的 `animation` / `emotes` 仍是 `dragonsurvival:test_dragon_animation` / `dragonsurvival:test_emotes` 这类占位 ID。

**影响：** 以太龙（`aether_body`）的骑乘点（双人骑乘 / 乘客落座位置）找不到骨骼锚点，骑乘表现异常或失败。

**建议：**

1. 在 `test_model.geo.json` 的骨架里补一根名为 `MountingBone` 的骨骼（位置参考 `dragon_model.geo.json` 中同名骨骼），或
2. 确认不需要骑乘后，在 `aether_body.json` 显式写 `"rideable": false` 消除报错。

---

### P1-03 配方解析失败 10 条（引用了不存在的物品 / 空 ingredient）

**来源：** `RecipeManager`（ERROR）+ `KubeJS Server` / `RecipeComponentValue`（WARN，KubeJS 回退到原版解析）

| # | 配方 ID | 类型 | 失败原因 |
|---:|---|---|---|
| 1 | `frostfire_dragon:rime_obsidian_lantern` | crafting_shaped | 引用不存在的 `frostfire_dragon:rime_crystal_cluster` |
| 2 | `frostfire_dragon:crying_obsidian_bricks_chiseled_from_stonecutting` | stonecutting | 引用不存在的 `frostfire_dragon:crying_obsidian_bricks_chiseled` |
| 3 | `frostfire_dragon:crying_obsidian_brick_wall_from_stonecutting` | stonecutting | 引用不存在的 `frostfire_dragon:crying_obsidian_brick_wall` |
| 4 | `frostfire_dragon:crying_obsidian_brick_stairs_from_stonecutting` | stonecutting | 引用不存在的 `frostfire_dragon:crying_obsidian_brick_stairs` |
| 5 | `frostfire_dragon:crying_obsidian_brick_slab_from_stonecutting` | stonecutting | 引用不存在的 `frostfire_dragon:crying_obsidian_brick_slab` |
| 6 | `frostfire_dragon:crying_obsidian_pillar_from_stonecutting` | stonecutting | 引用不存在的 `frostfire_dragon:crying_obsidian_pillar` |
| 7 | `justenoughbreeding:breeding/iceandfire/lightning_dragon` | 繁殖 | 引用 `iceandfire:dragonegg_amythest`，疑为 `amethyst` 拼写错误 |
| 8 | `ultramarine:cobalt_dust_compat` | stonecutting | `ingredient` 为空 |
| 9 | `iss_magicfromtheeast:refined_jade_ingot_alternative` | crafting_shapeless | `ingredients[4]` 为空 |
| 10 | `extradelight:currywurst` | crafting_shapeless | `ingredients[4]` 为空 |

**影响：** 这些配方在游戏内不存在（JEI 里看不到），悚域方块（`crying_obsidian_*`）与冰焰龙灯笼无法正常合成。

**建议：** 前 6 条属于 `frostfire_dragon` 与当前版本不匹配——升级/降级该模组，或用 KubeJS 数据包覆盖这几个配方。第 7 条可写数据包覆盖修正拼写。第 8–10 条是模组自身在缺少联动模组时的兜底配方为空，可用 KubeJS `ServerEvents.recipes` 重新定义或直接删除。

> 注：以上 10 条与 2026-08-29 文档的 P1-01 完全一致，**至今未修复**。

---

### P1-04 战利品表解析失败 4 条（`beyonddimensions`）

```
Couldn't parse element ResourceKey[minecraft:root / minecraft:loot_table]:
  beyonddimensions:blocks/schematicannon_pathway   - Unknown registry key ... beyonddimensions:schematicannon_pathway
  beyonddimensions:blocks/rs_net_pathway           - Unknown registry key ... beyonddimensions:rs_net_pathway
  beyonddimensions:blocks/ars_source_pathway       - Unknown registry key ... beyonddimensions:ars_source_pathway
  beyonddimensions:blocks/mana_pool_pathway        - Unknown registry key ... beyonddimensions:mana_pool_pathway
```

**原因：** `beyonddimensions` 内置了 Create / Refined Storage / Ars / Botania 联动的 pathway 战利品表，但对应物品在本包中不存在（未装这些模组或物品被删）。

**影响：** 该模组对应的「方块破坏掉落」为空，相关 pathway 方块无掉落。

**建议：** 用数据包覆盖这 4 张战利品表为 `{"type":"minecraft:empty"}`，或升级到已修复的 `beyonddimensions` 版本。

> 该问题同样自 2026-08-29 起存在。

---

## 🟠 P2 中优先级问题

### P2-01 `dungeons_arise` 两个进度无法加载（父进度不存在）

```
[Render thread/ERROR] [net.minecraft.advancements.AdvancementTree/]:
Couldn't load advancements: [dungeons_arise:find_thornborn_towers, dungeons_arise:find_fishing_hut]
```

**原因：** 两个进度的 `parent` 都指向 `dungeons_arise:find_small_prairie_house`，而 `DungeonsArise-1.21.1-2.1.68` 的 `data/dungeons_arise/advancement/` 里**根本没有这份进度**（只有 `find_giant_mushroom`、`wda_root` 等）。属于该模组版本的打包错误。

排查全库 37 个进度的 `parent` 后确认：**只有这两个**引用了不存在的父节点，其余一级进度全部挂在 `dungeons_arise:wda_root` 下。

**影响：** 这两个探索进度不会出现在进度界面，也不参与 `wda_root` 树的统计。

**状态：✅ 已修复并验证（2026-10-18 23:11 重启）。** 在 `kubejs/data/dungeons_arise/advancement/` 下覆盖并重写这两份 JSON：保留原 `display` / `criteria` / `requirements`，仅把 `"parent"` 从 `dungeons_arise:find_small_prairie_house` 改为 **`dungeons_arise:wda_root`**（与其它一级进度一致），未改动任何触发条件。重启后进度总数 9414 → **9416**。

| 文件 | 改动 |
|---|---|
| `kubejs/data/dungeons_arise/advancement/find_thornborn_towers.json` | `parent` → `dungeons_arise:wda_root` |
| `kubejs/data/dungeons_arise/advancement/find_fishing_hut.json` | `parent` → `dungeons_arise:wda_root` |

---

### P2-02 `wing_kirin` 饮食条目缺 `properties`（30 行警告）

```
[Render thread/WARN] [Dragon Survival/]: Diet entry
  [DietEntry[items=#c:foods, properties=Optional.empty, retainEffects=Optional[Left[true]]]]
  has neither original nor custom food properties - item will not be edible
```

**来源：** `mods/[龙之生存：翼麒麟] wing_kirin-3.0.1.jar` → `data/dragonsurvival/data_maps/dragonsurvival/dragon_species/diet_entries.json`

```json
{
  "items": "#c:foods",
  "retain_effects": true
}
```

**原因：** 该条目只有一个通配标签 `#c:foods`，既没写 `properties`，标签本身也没有食物属性，DS 判定为“不可食用”。

**影响：** 麒麟吃普通食物时可能无法获得饱食度/营养（需实机确认具体表现，例如是否只能吃 `wing_kirin:empyrean_wine`）。

**附带发现：** 同一文件还引用了 `create:bar_of_chocolate` / `create:sweet_roll` / `create:chocolate_glazed_berries` / `create:honeyed_apple` / `create:builders_tea`，但本包**未安装 Create**，这些条目对应的食物永远不存在。

**另 2 行同类警告**（`#dragonsurvival:cooked_vegetables`）来自龙之生存本体自带数据，非整合包问题，可忽略。

**建议：** 用 KubeJS 数据包覆盖为带属性的一组条目，例如按 `#c:foods/berry` / `#c:foods/meat` 等细分并给出 `properties`；或直接给该条目补上 `properties`（`eat_seconds` / `nutrition` / `saturation`），同时删掉 `create:*` 条目。

---

### P2-03 `gametechbcs_spellbooks` 的玩家动画目录错误，PlayerAnimator 解析崩溃

```
[Render thread/ERROR] [dev.kosmx.playerAnim.minecraftApi.codec.AnimationCodecs/]: Unknown error when trying to apply emotecraft
java.lang.IndexOutOfBoundsException: Index 0 out of bounds for length 0
  at ...GeckoLibSerializer.readDataAtTick(GeckoLibSerializer.java:216)
```

前一行同时给出：

```
[WARNING FOR MOD DEVS] Animation player_animation/casting_animations.json is in wrong directory:
"player_animation", please place it in "player_animations".
```

**定位：** `mods/[GTBC的魔法书] gametechbcs_spellbooks-3.0.0-1.21.1.jar` 内含 `assets/gametechbcs_spellbooks/player_animation/casting_animations.json`（单数目录，且格式不是 GeckoLib 动画），PlayerAnimator 仍会读取并解析失败。（`darkdoppelganger` 也有单数目录，但文件是合法 GeckoLib 格式，未报错。）

**影响：** 该模组的施法动画无法应用；每次资源重载报 2 条错误。

**建议：** 反馈给模组作者；本地可临时从 jar 中删除该目录（或改用资源包覆盖为空），代价是该模组施法动画消失（本来也没生效）。

---

### P2-04 GeckoLib 动画/模型问题（105 行 + 15 行 STDERR）

| 类型 | 行数 | 说明 |
|---|---:|---|
| 动画文件命名不规范 | 78 | `Found animation file with improper file name format ... should end in .animation.json`，涉及 `dragonsurvival`（含 `dihuang_loong_animation`、`custom_qinglong_animation`、`night_striker_*`）、`irons_spellbooks`、`iss_magicfromtheeast`、`irons_lib` |
| geometry 版本过新 | 12 | `Unsupported geometry json version: 1.21.0 for model dragonsurvival:geo/neo_crystcursed_dragon.geo.json / night_striker.geo.json / night_striker_female.geo.json`（GeckoLib 4.9.3 只支持 1.12.0，需重导出模型） |
| 动画解析失败 | 30 | `Unable to parse animation: mass_buff / flapping_wings_standing / attack_single / supernova`（Geckolib.CompoundException）；其中 15 条记在 `[GeckoLib/]`，另 15 条经 `[STDERR]` 打印 |

> 78 + 12 + 15 = 105，与 `[GeckoLib/]` 的统计行数吻合；剩下 15 条走的是 `LoggedPrintStream` 的 STDERR 通道。

**影响：** 对应生物（晶咒龙、夜煞、星界龙等）的动画可能不播放或模型异常。

**建议：** `night_striker` / `neo_crystcursed` 的模型重新以 1.12.0 格式导出；`mass_buff` / `supernova` 等动画文件里的表达式语法需修正。

---

### P2-05 缺失模型 / 贴图 / 粒子 / 音效

**物品模型缺失（14 条）：**

- `frostfire_dragon:block/rime_glass_pane_post_full` → 引用不存在的 `minecraft:block/template_glass_pane_post_full`
- `beyonddimensions:item/test_item_generate`、`fdlib:item/test_multiblock`、`fdbosses:item/no_entity_spawn_block`、`cinematiccataclysm:item/debug_stick`（均为模组遗留的开发/测试物品）
- `gtbcs_spell_lib:item/gsl_example_*` / `gsl_test_echo`（4 条，示例物品）
- `iss_magicfromtheeast:item/affinity_ring_dune`、`iss_magicfromtheeast:item/scroll_dune`
- `dragonsurvival:item/mega_typhus_dragon_soul`
- `ds_night_striker_addon:item/striker_plasma_item_ly`
- `irons_spellbooks:item/template_open_spell_book_model`（模板模型，通常无害）

**方块状态缺模型（18 条）：** `beyonddimensions:blockstates/xp_fluid.json` 的 `level=0..15` 全部缺失；`fdlib:blockstates/test.json`；`fdbosses:blockstates/no_entity_spawn_block.json`。

**模型缺贴图（18 条）：** `yuushya:sign_14`（12 个朝向/形态 + inventory）、`yuushya:pos_trans_item` / `micro_pos_trans_item`、`legendary_monsters:falling_cloud_projectile` / `falling_cloud_small_projectile`、`block_factorys_bosses:crate`。

**图集缺 sprite（5 条）：** `dragonsurvival:textures/te/star/wind.png`、`wind_vertical.png`、`open_eye.png`、`cage.png`、`minecraft:textures/continuity_reserved/000008e8.png` —— ⚠️ 这 4 张 `dragonsurvival:te/star/*` 若被星界龙特效引用，会导致特效贴图缺失，值得优先确认。

**粒子贴图缺失（8 个 sprite）：** `legendary_monsters:annihilation_geyser_0..6`、`black_hole_5`。

**音效缺失事件（11 条）：**

```
minecraft:item.goat_horn.play / minecraft:entity.goat.screaming.horn_break /
minecraft:block.potent_sulfur.geyser_continuous_eruption_start /
cataclysm:lacerton_ambient|hurt|death / cataclysm:ignisshieldbreak /
irons_spellbooks:entity.generic.swing_weird / entity.dead_king.music.drum_loop /
gametechbcs_spellbooks:manifestation / abyssal_strike_trigger
```

另有 `legendary_monsters:sounds/ancient_guardian_death.ogg does not exist`。

**影响：** 对应物品显示为紫黑方块、部分特效/音效静音。

**建议：** 属于各模组自身缺资源，优先修 `frostfire_dragon` 的玻璃板模板与 `dragonsurvival:te/star/*`（整合包自制资源可直接补）。

---

### P2-06 Continuity：无缝玻璃资源包 CTM 配置无效

```
No tile or block matches provided in file 'minecraft:optifine/ctm/glass/black/glass_black.properties'
No valid connection type provided in file 'minecraft:optifine/ctm/glass/black/glass_black.properties'
```

**来源：** `config/paxi/resourcepacks/[无缝玻璃] Clear Glass Pack 1.21.zip`。每次资源重载 **32 行（ERROR 级）** = 16 个文件 × 2 条（多次重载会重复出现，首份日志里累计 53 行）。

#### 根因：16 份「没有 match 也没有 connect」的僵尸规则

失败的都是 `optifine/ctm/glass/<color>/glass_<color>.properties`（black / blue / brown / cyan / gray / green / light_blue / lime / magenta / orange / pink / purple / red / silver / white / yellow），内容只有两行：

```properties
method=ctm
tiles=0-46
```

既没有 `matchBlocks`，也没有 `matchTiles`。

#### OptiFine 与 Continuity 的差异（关键）

按 [OptiFine 官方文档](https://optifine.readthedocs.io/ctm.html)：

- `matchBlocks` 的默认值确实是「**由文件名推断**」，但只覆盖一种命名：`~/ctm/xxx/block_<name>.properties` ⇒ `matchBlocks=<name>`；
- `connect` 的默认值：方块用 `block`，贴图用 `tile` —— **前提是能确定匹配对象**；
- 两条都推不出来时，OptiFine 只是把这条规则**静默丢弃**，玩家端看不到任何提示。

Continuity 兼容 OptiFine 的 CTM 格式，但它对配置做**显式校验**：匹配对象缺失 → `No tile or block matches`；`connect` 推导不出来 → `No valid connection type`。于是同一份「在 OptiFine 里默默失效」的配置，在 Continuity 里变成每个文件 2 条警告。

`glass_<color>.properties` 既不符合 `block_<name>.properties`，包的 `textures/block/` 里也不存在 `glass_<color>.png`，所以在 OptiFine 下同样是死规则。

#### 为什么可以安全删除

同一目录下的 `<color>_stained_glass.properties` 已经是**同贴图、同目标**的完整规则：

```properties
matchBlocks=black_stained_glass
method=ctm
tiles=0-46
```

两者 `tiles=0-46` 指向同一个 `glass/<color>/` 目录里的 47 张图，唯一的区别就是前者缺 `matchBlocks`。删除后视觉零变化。

**状态：✅ 已修复并验证（2026-10-18 23:11 重启）。** 从 zip 内删除这 16 个僵尸文件（966 → 950 条目），保留 35 条有效 CTM；重启后 `ContinuityClient` 相关由 48 条降至 **16 条**（32 条 ERROR 全部消失）：

| 类别 | 数量 |
|---|---:|
| 普通玻璃 / 玻璃板 | 1 + 1 |
| 染色玻璃 | 16 |
| 染色玻璃板 | 16 |
| 遮光玻璃 | 1 |
| **合计** | **35** |

原始包已备份到 `docs/tools/backup/Clear Glass Pack 1.21.original.zip`。

> 只能改 zip 本身：Continuity 逐 pack 读取 CTM（见 [6.2](#62-失败一continuity-不看合并后的资源管理器)），高优先级资源包里放同名文件不会覆盖它。
>
> ⚠️ 事故记录：首次删除时正则 `glass_[a-z_]+\.properties` 把 `glass/aregular/glass_pane.properties`（有效文件）也匹配进去了，造成误删。已从备份原样恢复（145 bytes，内容校验一致），并重新做了全量 diff：备份有而当前无 = 恰好 16 个，当前有而备份无 = 0 个。

---

### P2-07 非法资源路径（11 行，含中文文件名）

```
beyonddimensions:textures/gui/sprites/widget/©xxx.png ×3（中文名）
biomespy:tags/worldgen/structure/uninit_safe.json?     ← 文件名末尾带问号
dragonsurvival:textures/armor/dragon_model/cnb/flower_crown 2.png
legendary_monsters:textures/entity/posessed_paladin/old/posessed_paladin — kopia.png
xaerominimap:...:dwarf/blacksmith - Copy.png
xaerominimap:...:lightningdragon_copper _3.png
PathPackResources: legendary_monsters:textures/item/the_great_frost_3d2Old_hilight.png
PathPackResources: minecraft:textures/block/gIass_hilight.png（36 行，`gIass` 拼写错误，被整个图集忽略）
```

**影响：** 对应贴图被忽略；`gIass_hilight.png` 连报 36 次说明有个模型批量引用了它。

**建议：** 资源包里删掉/改名这些文件；`gIass` 若为整合包自制模型引用，改成 `glass`。

---

### P2-08 ModernUI 文字描边渲染异常（3 次）

```
[Render thread/WARN] [ModernUI-MC/TextLayout]: Failed to add SDF fill/stroke to fixed buffers
java.lang.UnsupportedOperationException: null
  at icyllis.modernui.mc.text.TextRenderType.makeSDFFillType(TextRenderType.java:266)
```

**影响：** 带描边的文字（伤害数字、任务标题等）退化为普通渲染，不影响功能。

**建议：** ModernUI 3.13.0.1 与 fastutil 的已知兼容问题，等上游修复或降级 ModernUI。

---

### P2-09 Curios：`scroll` 槽位未注册

```
[Render thread/ERROR] [Curios API/]: scroll is not a registered slot type!
```

**影响：** 声明使用 `scroll` 槽位的饰品/卷轴类物品无法装备。

**建议：** 排查哪个模组引用了 `scroll` 槽（本包未安装对应槽位定义模组），在其配置中关闭该槽位或补一个 `curios` 槽位定义数据包。

---

### P2-10 Patchouli 手册引用的配方不存在（13 条）

`yuushya:*_blueprint`（8 条）、`irons_spellbooks:cryomancer_helmet` / `pyromancer_helmet` / `iron_spell_book`、`melodymagic:continue_sound_collection`。

**影响：** 手册内点击配方无法跳转（`lookups` 失效）。

**建议：** 这些配方被整合包（或模组更新）删除/改名了。若要保留手册联动，用 KubeJS 重新注册同名配方，或接受该提示。

---

### P2-11 生物生成类别不一致（4 条）

```
Detected minecraft:ocelot that was registered with CREATURE mob category
but was added under MONSTER mob category for regions_unexplored:rainforest biome!
```

涉及 `regions_unexplored` 的 `eucalyptus_forest` / `rainforest` / `sparse_rainforest` / `tropics`。

**影响：** 豹猫按 MONSTER 上限生成，可能挤占怪物生成名额或数量异常。

**建议：** 数据包覆盖这 4 个群系的 `spawners`，把 `minecraft:ocelot` 放回 `creature`。

---

### P2-12 启动耗时与卡顿

- `Game took 88.785 seconds to start`（较 08-29 的 105.6 s 有改善，但仍偏长）
- `Can't keep up! Is the server overloaded? Running 2117ms or 42 ticks behind`（1 次，进世界时）

**建议：** 结合 P2-04/P2-05 的资源加载错误一起优化；模组数 226，属正常区间偏上。

---

### P2-13 方块小镇（Yuushya）专项：0 错误、67 行警告

> **最终状态（2026-10-18 22:43）：模型/贴图 15 条、手册 7 条已修复并验证；CTM 16 条经评估后决定接受（Continuity 绕过 pack filter，包内无解）；Create 26 条与 mixin 2 条保持现状。** 详见第 5、6 节。

`latest.log` 中 `yuushya` 相关共 90 行：**0 ERROR / 67 WARN / 6 INFO**；`debug.log` 无额外条目。涉及两个模组：

- `[方块小镇] yuushya-1.21.0-neoforge-2.3.0.jar`（方块、CTM、手册）
- `[方块建模] yuushya_modelling-1.21.1-2.4.1.jar`（建成工具、位置/旋转/缩放道具）

67 行警告可归为 5 类，逐条已定位到具体文件：

#### (1) 26 条：Create 联动配方被 KubeJS 跳过

```
[KubeJS Server/]: Skipping recipe yuushya:mixing/...,    unknown type: create:mixing      ×15
[KubeJS Server/]: Skipping recipe yuushya:splashing/..., unknown type: create:splashing   ×8
[KubeJS Server/]: Skipping recipe yuushya:deploying/..., unknown type: create:deploying   ×3
```

`data/yuushya/recipe/` 下确实存在 `mixing/` 15 个、`splashing/` 8 个、`deploying/` 3 个 JSON，但本包**未安装 Create**，配方类型无法解析。

> KubeJS 这条日志是**写死的 WARN，没有配置开关**：`RecipesKubeEvent.java:237` 的 `warnSkip(...)` 无条件输出（`D:\Minecraft\开源模组参考文件\kubejs` 源码可查）。

**影响：** 无。这些配方在无 Create 的环境里本来就不该存在。

#### (2) 16 条：Continuity 报「未知方块」——亚克力 CTM 用的是旧版数字 ID

```
Unknown block 'yuushya:a53' in 'matchBlocks' element 'yuushya:a53' at index 0
  in file 'minecraft:optifine/ctm/compact/acrylic/black/l_.properties'
  in pack 'mod/yuushya:resourcepacks/mcpatcher_feature'
```

16 种颜色各报 1 条，引用的全是**旧版数字 ID**：`yuushya:15`（黄）、`yuushya:069`（灰）、`yuushya:a50`～`a63`（其余 14 色）。而 2.3.0 的 5773 个 blockstate 里**没有任何数字 ID**，方块名已改为 `<颜色>_acrylic`。

每份 `l_.properties` 只有 4 行：

```properties
matchBlocks=yuushya:a53
method=fixed
tiles=1
faces=top bottom
```

`tiles=1` + `method=fixed` 意味着**不产生任何连接变化**，本质是一份无效配置。**影响：** 仅日志污染，亚克力本就没有连接纹理效果。

#### (3) 15 条：模型缺贴图（3 个模型）

| 模型 | 缺失贴图 | 成因 |
|---|---|---|
| `yuushya:sign_14`（13 个朝向/形态 + inventory） | `yuushya:0extra_building_material/preview/poster/poster_large` | 父模型 `models/extra_building_material/sign/sign_14.json` 的 `particle` 指向不存在的文件（`#0` 已被 5 个随机子模型覆盖，实际只缺 particle）；该目录只有 `0.png`～`13.png`、`template.png`、`digital_payment.png` |
| `yuushya:pos_trans_item#inventory` | `yuushya:item//wrench/translate_x` | `方块建模` 的 `models/item/pos_trans_item.json` 里**双斜杠笔误** |
| `yuushya:micro_pos_trans_item#inventory` | `yuushya:item/fine_tune_x` | 两个模组**都提供同名模型**：`方块建模` 写 `item/wrench/fine_tune_x`（正确），`方块小镇` 写 `item/fine_tune_x`（缺 `wrench/`）；方块小镇的包优先级更高，错误版本胜出 |

**影响：** 海报/告示牌的破坏粒子、扳手系列工具的物品图标可能显示紫黑或空白。

#### (4) 8 条：Patchouli 手册查不到配方

```
[Render thread/WARN] [patchouli/]: Recipe yuushya:block_blueprint (of type minecraft:crafting) not found
```

两种不同成因：

- **5 条「配方存在但类型不符」**：`block_blueprint` / `sign_blueprint` / `furniture_blueprint` / `facility_blueprint` / `extra_shapes_blueprint` 在 jar 里都是 **`minecraft:stonecutting`**，而手册页写死 `"type": "crafting"`，Patchouli 按 crafting 查不到。
- **3 条「配方真的不存在」**：`deco_blueprint`、`dailylife_stuff_blueprint` 疑似被改名为 `stone_blueprint` / `living_being_blueprint`；`get_showblock_item` 模组本身无配方，本包在 [kubejs/server_scripts/recipe/yuushya/recipe.js](kubejs/server_scripts/recipe/yuushya/recipe.js) 补了一个 shapeless，但 id 是 KubeJS 自动生成的，不是 `yuushya:get_showblock_item`。

涉及 3 个手册条目文件：`bt_survival_building_material.json`（7 个 blueprint 全在这一个文件里）、`bt_survival_gameplay.json`、`mf_block_modeling_basic.json`。

**影响：** 手册里对应页面显示「配方缺失」，点击无法跳转。

#### (5) 2 条：mixin 噪音

- `@Mixin target org.embeddedt.embeddium...EmbeddiumWorldRenderer was not found`（`方块建模` 的 Embeddium 兼容 mixin，本包用 Sodium）
- `Reference map 'yuushya.refmap.json' could not be read`（开发环境提示）

**影响：** 无。

---

## 🟡 P3 低优先级问题

### P3-01 `pride` 模组 AccessTransformer 缺失

```
[main/ERROR] [net.neoforged.fml.loading.moddiscovery.ModFile/LOADING]:
Access transformer file META-INF/accesstransformer.cfg provided by mod pride does not exist!
```

`pride` = **Pride Lib 1.2.4**，由 `lambdynamiclights-4.8.11` 通过 JarJar 内置（`mods/` 里没有独立 jar）。属上游打包缺陷，不影响运行。

### P3-02 Mixin 类加载失败（26 条）

`Error loading class: ... ClassNotFoundException`，涉及 create / mekanism / embeddium / journeymap / jeresources / sodium 旧路径 / kubejs 客户端处理器等**本包未安装**的模组类。标准的 mixin 噪音。

### P3-03 着色器 uniform / sampler 警告（10 条）

`fdbosses`（malkuth_boss_bar、chesed_item_overlay、spherical_distortion_field、vignette、netzach_mexico）、`fdlib`（noise、chromatic_abberation、shattered_screen、impact_frame）、`ldlib2`（graph_wire）、`rendertype_entity_translucent_emissive`。仅影响个别特效。

### P3-04 未知属性 `forge:entity_gravity`（20 条）

1.20 时代的旧属性名，某些模组的生物属性仍在写入。被静默忽略，无功能影响。

### P3-05 未安装的 JarJar 依赖被当作源 jar（5 条）

`fabric_*` / `cloth_config` 等 fabric 侧 jar 被打进 JarJar 元数据但未实际嵌入（`Attempted to select a dependency jar for JarJar which was passed in as source`）。无影响。

### P3-06 网络/证书类

- `Moonlight Hub Fetcher`: `SSLHandshakeException ... PKIX path building failed`（无法拉取团队信息）
- `xaero.lib.XaeroLib`: `io exception while checking patreon: Read timed out`
- `Collective`: `has an update available: 8.40 -> 8.58`

均为在线数据拉取失败，不影响单机。

### P3-07 其他少量提示

| 内容 | 说明 |
|---|---|
| `IMBlocker`: 7 个类未找到 | 未安装对应模组的输入法兼容项，已忽略 |
| `Jupiter`: `cannot resolve 37 empty List<Enum>` / `damage_type_colors` 配置项缺失 | 配置读取提示 |
| `Unable to play empty soundEvent: minecraft:entity.{salmon,cod,tropical_fish}.ambient` | `sounds.json` 被覆盖成空事件 |
| `Block-attached entity at invalid position: BlockPos{x=124, y=-23, z=87}`（2 次） | 地下生成的画/展示框位置非法，属世界生成偶发 |
| `FTB Library EntityIconLoader`: `artifacts:mimic` / `iceandfire:stone_statue` 使用旧版隐形贴图 | 图标可能不显示 |
| `VanillaPackResourcesBuilder`: `Assets URL ... uses unexpected schema`（2 条） | 启动器 classpath 形式导致，无害 |
| `Not all defined tags for registry ... are present in data pack`（5 条） | `cataclysm:needs_black_steel_tool`、`dragonsurvival:no_striker_echo`、`c:ingots/cobalt` 等标签未定义 |
| 纹理 mip / 帧索引（8 条） | `dragonsurvival:icons/food_tooltip_icons_extended` 27×18 限制 mip、`corgilib:alert` 帧索引越界、若干未使用帧 |
| `JarSelector` / `patchouli.refmap.json` 读取失败 | 开发环境提示，可忽略 |
| `TeleportWaypoint`: `Xaero config options unavailable` | 已回退到模组自身配置，正常 |
| `KubeJS Server`: 30 条 `Skipping recipe ... unknown type: create:*` | 本包未安装 Create，`yuushya` 的 Create 联动配方被跳过（预期行为） |
| `KubeJS Server`: `Skipping recipe minecraft:dough, not a json object` | 某个数据包里 `minecraft:dough` 配方格式错误，被跳过 |
| `Skipping recipe justenoughbreeding:breeding/untamedwilds/terror_bird, conditions not met` | 条件未满足，正常 |

---

## 2. 与 2026-08-29 清单的对照

### 仍然存在（未修复）

| 问题 | 08-29 编号 | 本次位置 |
|---|---|---|
| 10 条配方解析失败（frostfire / justenoughbreeding / ultramarine / iss / extradelight） | P1-01 | P1-03 |
| 4 条 `beyonddimensions` 战利品表失败 | P1-02 | P1-04 |
| GeckoLib 命名 / geometry 版本 / 解析失败 | P2-01 | P2-04 |
| Continuity 无缝玻璃 | P2-05 | P2-06 |
| 缺失模型/方块状态 | P2-06 | P2-05 |
| 着色器 uniform 警告 | P2-07 | P3-03 |
| ModernUI SDF `UnsupportedOperationException` | P2-08 | P2-08 |
| `scroll` 槽位未注册 | P2-09 | P2-09 |
| PlayerAnimator `player_animation` 目录错误 | P2-03 | P2-03 |
| Mixin 类加载噪音 | P3-01 | P3-02 |
| 非法资源路径 | P3-04 | P2-07 |

### 本次新增（08-29 文档中未记录）

1. **P1-01 星辰龙三阶段 `crushing_growth` 越界** —— 整合包自制数据问题，**已修复（待重启验证）**。
2. **P1-02 以太龙 `aether_body` 缺 `MountingBone`** —— 自制龙模型问题。
3. **P2-01 `dungeons_arise` 两个进度父节点缺失** —— 模组 2.1.68 打包错误。
4. **P2-02 `wing_kirin` 饮食条目缺 `properties`** —— 30 行警告。
5. **P2-11 `ocelot` 生成类别不一致** —— 4 条。
6. **P3-01 `pride`（Pride Lib）AT 文件缺失** —— LambDynamicLights 内置依赖。
7. **P2-13 方块小镇（Yuushya）专项** —— 67 行警告，本次首次逐条定位到文件（Create 配方 26、亚克力旧 ID 16、模型缺贴图 15、手册配方 8、mixin 2）。

### 已消失（本次未出现）

- `Serene Shrubbery` 模型 JSON 非法（模组已在 1.4 移除）
- `EMF` 模型创建超过 64 次（`entity_model_features` 已移除）
- `AllTheLeaks` `VarHandler is null`（模组仍在，本次未复现）
- `ModernFix: A mod is calling registerReloadListener at the wrong time`
- `Artifacts` 无法给实体装备物品（模组仍在，本次未复现）
- `butchercraft` 相关方块状态 / 模型错误（模组已移除，仅剩 `config/butchercraft-common.toml` 残留）

### 改善

- 启动耗时 **105.636 s → 88.785 s**
- 服务器追赶从 `11595ms / 231 ticks` 降到 `2117ms / 42 ticks`

---

## 3. 建议处理顺序

1. **P1-01**（星辰龙阶段）—— ✅ 已完成：三行 JSON 数值已改为 150/200/250，重启后即可验证。
2. **P1-02**（`MountingBone`）—— 补骨骼或关掉 `rideable`，消除每次进世界的报错。
3. **P1-03 / P1-04**（配方 / 战利品）—— 通过 KubeJS 数据包覆盖修复，避免内容缺失。
4. **P2-01 / P2-02 / P2-05**（进度、麒麟饮食、缺失资源）—— 数据包或资源包即可修复。**P2-01 已完成**（父进度改为 `wda_root`）。
5. **P2-03 / P2-04 / P2-06**（动画、GeckoLib、Continuity）—— **P2-06 已完成**（删除 16 份僵尸 CTM 规则）；其余需模组作者或替换资源包。
6. **P2-13**（方块小镇）—— 3 个模型 + 16 个 CTM + 3 个手册页，纯包内改动，可让 Yuushya 归零（见第 4 节）。
7. 其余 P2/P3 作为噪音清理，并按第 4.5 节建立日志基线，防止新噪音回归。

---

## 4. 专题讨论：能不能彻底修掉、做到「0 噪声」？

### 4.1 结论先行

| 范围 | 能否 0 噪声 | 说明 |
|---|---|---|
| **方块小镇（Yuushya）单项** | 🟡 **67 条里 39 条可零成本清零；全量归零必须动 jar** | 22 个包内文件（3 模型 + 16 CTM + 3 书页）+ 1 行脚本，即可清掉 16+15+8=39 条；剩下 26 条 Create 配方与 2 条 mixin 只有改 jar 才能真正归零 |
| 整个整合包 | ❌ 做不到，也不建议 | 约 300 行噪音来自模组 jar 内部（文件名、模型版本、mixin 目标），只能 fork 模组 |

### 4.2 方块小镇：0 WARN 的可行方案

| # | 报错 | 条数 | 推荐方案 | 改动量 | 风险 |
|---:|---|---:|---|---|---|
| 1 | Create 配方被跳过 | 26 | **方案 C（推荐）保持现状**；若要清空，见下方三选一 | 0 | 无 |
| 2 | Continuity 旧数字 ID | 16 | 资源包覆盖 16 份 `l_.properties`，`matchBlocks` 换成真实方块 | 16 个小文件 | 低（映射错误只影响某色亚克力，且原配置本就是空转） |
| 3 | 模型缺贴图 | 15 | 资源包覆盖 3 个模型 JSON | 3 个文件 | 极低（纯资源） |
| 4 | 手册配方缺失 | 8 | 覆盖 3 个书页 JSON（页类型 `crafting`→`stonecutting`，2 个失效 id 换现存 id）；KubeJS 配方补 `.id(...)` | 3 个 JSON + 1 行 | 低（需校对页面内容） |
| 5 | mixin 噪音 | 2 | 只能改 `方块建模` 的 mixin 配置 | 需改 jar | 不建议 |

> 第 1、5 项**不改 jar 就消不掉**；第 2～4 项合计 **39 条可 100% 清零**，且全部通过 `kubejs/` 目录生效，不产生任何第三方 jar 修改。

**第 1 项的三选一：**

- **A. 改 jar**：删除 `data/yuushya/recipe/{mixing,splashing,deploying}` 三个目录（26 个 JSON）。日志**彻底归零**，但每次方块小镇更新都要重做。
- **B. 数据包覆盖**：把 26 个 JSON 原样覆盖，并在根节点加 `"neoforge:conditions": [{"type": "neoforge:mod_loaded", "modid": "create"}]`。KubeJS 会走**条件不满足分支**（`infoSkip`，INFO 级），WARN 归零，但日志仍留 26 行 INFO；好处是将来若安装 Create，配方会自动恢复。
- **C. 保持现状**：这 26 条不影响任何实际内容，是"未安装可选联动模组"的正常结果。

> 我的建议是 **C**：为了 26 行无害日志去改 jar 或写 26 个覆盖文件，维护成本高于收益。方块小镇真正值得修的是第 2、3、4 项。

**落地形态（与项目现有 `kubejs/assets/yuushya/...` 覆盖习惯一致）：**

```
kubejs/assets/yuushya/models/item/pos_trans_item.json                    # 修 item// 双斜杠
kubejs/assets/yuushya/models/item/micro_pos_trans_item.json              # 补 wrench/ 路径
kubejs/assets/yuushya/models/extra_building_material/sign/sign_14.json   # particle 指向 poster/template
kubejs/assets/minecraft/optifine/ctm/compact/acrylic/<color>/l_.properties  # ×16，改 matchBlocks
kubejs/data/yuushya/patchouli_books/yuushya_guidebook/en_us/entries/
    building_techniques/bt_survival_building_material.json               # 7 个 blueprint 页类型
    building_techniques/bt_survival_gameplay.json                        # get_showblock_item 页
    mod_functions/mf_block_modeling_basic.json                           # get_showblock_item 页
kubejs/server_scripts/recipe/yuushya/recipe.js                           # .id('yuushya:get_showblock_item')
```

**旧 ID → 新方块映射（按颜色目录推导，落地前建议实机抽查 2～3 个）：**

| 颜色 | 旧 ID | 现方块 | 颜色 | 旧 ID | 现方块 |
|---|---|---|---|---|---|
| black | `yuushya:a53` | `black_acrylic` | light_gray | `yuushya:a54` | `light_gray_acrylic` |
| blue | `yuushya:a52` | `blue_acrylic` | lime | `yuushya:a57` | `lime_acrylic` |
| brown | `yuushya:a58` | `brown_acrylic` | magenta | `yuushya:a62` | `magenta_acrylic` |
| cyan | `yuushya:a55` | `cyan_acrylic` | orange | `yuushya:a61` | `orange_acrylic` |
| gray | `yuushya:069` | `gray_acrylic` | pink | `yuushya:a60` | `pink_acrylic` |
| green | `yuushya:a59` | `green_acrylic` | purple | `yuushya:a56` | `purple_acrylic` |
| light_blue | `yuushya:a63` | `light_blue_acrylic` | red | `yuushya:a50` | `red_acrylic` |
| white | `yuushya:a51` | `white_acrylic` | yellow | `yuushya:15` | `yellow_acrylic` |

> 注意：这些补丁都**与模组版本强相关**。方块小镇升级后 ID、模型路径、手册条目都可能再变，需要重新核对一遍。

### 4.3 整包为什么做不到 0 噪声

把 539 行 WARN 按「能不能从整合包侧消除」分三堆（粗略估算）：

| 类别 | 约占行数 | 能否从包侧消除 | 典型例子 |
|---|---:|---|---|
| 资源 / 数据层 | ~180 | ✅ 能 | 缺模型、缺贴图、CTM、手册、配方、进度 |
| 模组 jar 内部 | ~300 | ❌ 不能（只能 fork） | GeckoLib 动画命名与 geometry 版本、mixin 目标缺失、jar 内非法文件名 |
| 设计使然 / 环境 | ~60 | ❌ 不需要 | 旧属性 `forge:entity_gravity`、JarJar 元数据、网络超时、Sodium 提示 |

具体到三项最大的：

- **mixin 153 行**：每个模组都带着一堆 `compat` mixin，会去尝试加载「未安装模组」的类。要消掉只能把这些兼容 mixin 从 jar 里删掉——每装一个新模组又会重新出现。
- **GeckoLib 105 行**：78 行是 **jar 内动画文件名**不以 `.animation.json` 结尾；12 行是模型 `format_version 1.21.0` 超出 GeckoLib 4.9.3 的支持范围。都不是整合包能改的。
- **PathPackResources 37 行**：jar 内文件名带空格、全角破折号、中文。改不了。

也就是说：**整包 0 噪声 ≈ 把 226 个模组全部重新打包一遍，并且每次更新都重做**，不可维护。

### 4.4 用日志过滤「做」到 0 噪声？不推荐

技术上可以用 `log4j2.xml` 把已知 logger 压到 DEBUG，日志立刻"干净"。但：

- 会连真问题一起吞掉——例如 `[Dragon Survival/]` 既有 32 行无害的饮食警告，也有 P1-01 的致命阶段错误；
- 模组升级后新增的同类警告也会被静默；
- 排障时还得临时关掉过滤，等于自欺欺人。

### 4.5 建议采用的目标：可归因噪声清零 + 基线

1. **修**：包侧能修的全部修掉（P1 全部 + P2 的 1、2、3、5、6、7、9、10 + 方块小镇第 2/3/4 项）。
2. **白名单基线**：把只能由上游解决的项目写成「日志模式 → 允许条数」，例如：
   ```
   mixin: Error loading class .*                     allow=153
   GeckoLib/.*improper file name format              allow=78
   GeckoLib/.*Unsupported geometry json version      allow=12
   ```
3. **校验脚本**：`docs/tools/verify-log-baseline.ps1`，读取 `latest.log` 与基线比对，**出现基线外的新噪音即非零退出**。这样"0 新增噪声"是脚本可验证的，而不是靠人眼看。
4. **升级流程**：每次更新模组后跑一次；基线条数变化说明上游有变动，人工确认后更新基线。

这套做法与项目现有的 `docs/tools/gen-*.ps1` / `verify-*.ps1` 风格一致，也符合 [docs/README.md](../README.md) 对 `plans` / `tools` 的定位。

---

## 5. 首轮修复记录（2026-10-18，仅方块小镇）

范围：只处理 P2-13 中**可从整合包侧修复的 39 条**；mixin（2 条）与其他模组的报错按约定不处理。

### 5.1 新增 / 修改文件

| 类型 | 路径 | 作用 | 对应条数 |
|---|---|---|---:|
| 贴图 | `kubejs/assets/yuushya/textures/0extra_building_material/preview/poster/poster_large.png` | 补齐 `sign_14` 父模型缺失的 `particle` 贴图（内容复制自 `template.png`） | 13 |
| 模型 | `kubejs/assets/yuushya/models/item/pos_trans_item.json` | 修正 `item//wrench/translate_x` 双斜杠 | 1 |
| 模型 | `kubejs/assets/yuushya/models/item/micro_pos_trans_item.json` | 用 `item/wrench/fine_tune_x` 覆盖方块小镇的错误版本 | 1 |
| CTM | `kubejs/assets/minecraft/optifine/ctm/compact/acrylic/<16 色>/l_.properties` | `matchBlocks` 由旧数字 ID 改为 `<颜色>_acrylic` | 16 |
| 手册 | `kubejs/data/yuushya/patchouli_books/yuushya_guidebook/en_us/entries/building_techniques/bt_survival_building_material.json` | 4 个 crafting 双配方页 → 7 个 stonecutting 单配方页；正文「无序合成」改为「切石机」 | 7 |
| 配方 | `kubejs/data/yuushya/recipe/deco_blueprint.json` | 补上缺失的石切配方（与其它 blueprint 完全一致：铋晶体 → 蓝图） | 1 |
| 配方 | `kubejs/data/yuushya/recipe/dailylife_stuff_blueprint.json` | 同上 | 1 |
| 配方 | `kubejs/data/yuushya/recipe/get_showblock_item.json` | 由 KubeJS 脚本改为原版 `crafting_shapeless` JSON，使手册能按 `minecraft:crafting` 解析 | 1 |
| 脚本 | `kubejs/server_scripts/recipe/yuushya/recipe.js` | 移除已迁移的 `get_showblock_item` shapeless，保留 textblock | — |

### 5.2 关键决策

- **不碰 jar**：全部通过 KubeJS 虚拟资源包 / 数据包覆盖。模组升级后只需按 4.2 的清单重新核对。
- **优先级已验证**：`latest.log` 的 `Reloading ResourceManager` 顺序中，`KubeJS Virtual Resource Pack [After Mods]` 位于 `mod/yuushya`、`mod/yuushya_modelling` **之后**，覆盖必然生效。
- **手册页拆成 7 页**：Patchouli 的 `PageStonecutting` 只支持单个 `recipe`（只有 `PageCrafting` 才有 `recipe2`），保留双配方会丢内容，所以拆页。
- **补 2 个 blueprint 配方**：`deco_blueprint` / `dailylife_stuff_blueprint` 的**物品存在、但模组没有给配方**（全库检索无任何引用），手册却在展示它们。按模组统一的石切模式补全——既消警告，也修复了两个"存在但不可获得"的物品。
- **`get_showblock_item` 改走原版 JSON**：KubeJS 的 `shapeless` 实际注册为 `kubejs:shapeless` 类型，Patchouli 按 `RecipeType.CRAFTING` 查不到；改成 `minecraft:crafting_shapeless` 后既能被手册解析，玩法完全等价。

### 5.3 预期效果

| 项 | 修复前 | 修复后（预期） |
|---|---:|---:|
| 方块小镇 WARN | 67 | **28**（26 条 Create 配方 + 2 条 mixin） |
| 全包 WARN | 539 | **约 500** |
| 全包 ERROR | 117 | 117（不变） |

### 5.4 验证方式

1. **完全重启游戏**（模型 / 贴图 / CTM 需要资源重载，`/reload` 不够）。
2. 重新检查日志：
   ```powershell
   Select-String -Path logs\latest.log -Pattern 'yuushya' | Where-Object { $_.Line -match 'WARN|ERROR' }
   ```
   预期只剩 26 条 `Skipping recipe yuushya:(mixing|splashing|deploying)` 与 2 条 mixin。
3. 实机抽查：
   - 手册「生存模式获取建材」页应显示 7 张石切配方，无「配方缺失」；
   - 扳手系列道具（`pos_trans_item` / `micro_pos_trans_item`）图标正常；
   - 16 色亚克力方块外观无变化。

### 5.5 回滚方式

除 `recipe.js`（仅替换注释与移除一段 shapeless）外，其余全部是**新增的覆盖文件**；删掉对应文件、恢复脚本即回到改动前状态。

---

## 6. 首轮验证结果与修正（2026-10-18 22:03 启动）

### 6.1 结果：1 项成功、2 项失败、2 项新增错误

| 项 | 预期 | 实际 | 结论 |
|---|---|---|---|
| 模型缺贴图 15 条 | 消失 | **已消失** | ✅ 方案有效 |
| 亚克力 CTM 16 条 | 消失 | **仍存在**（旧 ID） | ❌ KubeJS 资源包对 Continuity 无效 |
| 手册配方 7 条 | 消失 | **仍存在**（仍报 crafting） | ❌ 覆盖放错目录 |
| 补的 2 个 blueprint 配方 | 消 2 条 | **反而新增 2 WARN + 2 ERROR** | ❌ 目标物品根本没注册 |

当次统计：WARN **539 → 497**，ERROR **117 → 121**（新增的 5 条全部来自本轮改动：2 条配方解析 + 3 条 `/give` 异常）。

`yuushya` 相关合计 58 条 = 26 Create + 16 CTM + 7 手册 + 2 mixin + 4 条本轮引入的配方错误 + 3 条 `/give` 异常。

### 6.2 失败一：Continuity 不看合并后的资源管理器

`CtmPropertiesLoader` 的实现是**自己遍历 pack**（`listPacks` + `Iterator<PackResources>` + `packPriority` + `reverseOrder`），对每个 pack 单独调用 `pack.listResources(PackType, "optifine/ctm", ...)`，同路径按它自己的规则去重——实测保留**模组内置 pack** 的版本。

所以往 KubeJS 虚拟资源包放 `assets/minecraft/optifine/ctm/...` 完全无效：文件在包里，但 Continuity 不读（模型能用是因为 ModelBakery 走 `getResource`，机制不同）。

**修正：** 改用 **Paxi 资源包 + `pack.mcmeta` 的 `filter`**。`filter` 会在构建 pack 栈时把低优先级 pack 里匹配的资源**整段屏蔽**，模组那 16 份过期文件对 Continuity 直接不可见，只剩修正版。

`config/paxi/resourcepacks/[方块小镇] CTM 修复.zip`：

```json
{
  "pack": { "pack_format": 34, "description": "..." },
  "filter": {
    "block": [
      { "namespace": "minecraft", "path": "optifine/ctm/compact/acrylic/.*" }
    ]
  }
}
```

### 6.3 失败二：帕秋莉读 assets，不读 data

`BookContentResourceListenerLoader` 继承 `SimpleJsonResourceReloadListener`，且位于 `vazkii.patchouli.client.book` 包——注册在**客户端**资源重载，扫描的是 `assets/<ns>/patchouli_books/...`。模组 jar 里同时存在 `assets/` 与 `data/` 两份同名书，真正生效的是 **assets** 那份。

首轮只覆盖了 `data/`，所以完全没生效。

**修正：** 覆盖文件移到 `kubejs/assets/yuushya/patchouli_books/...`，删除 data 版本。

### 6.4 失败三：那两个 blueprint 物品根本不存在

```
[ERROR] Parsing error loading recipe yuushya:deco_blueprint:
  Unknown registry key in ResourceKey[minecraft:root / minecraft:item]: yuushya:deco_blueprint
```

`/give @s yuushya:deco_blueprint` 同样失败。查 jar 只有 `models/item/deco_blueprint.json` 与 lang 条目，**没有任何 item 注册**——这是方块小镇 2.3.0 里已被删除的物品，lang/模型是残留。`dailylife_stuff_blueprint` 同理。

**修正：**

- 删除新增的 2 个 recipe JSON（它们让日志多了 2 WARN + 2 ERROR）；
- 手册里对应的 2 页一并删除，保留 5 个有效 blueprint：`block` / `sign` / `furniture` / `facility` / `extra_shapes`。

### 6.5 关于 `/give` 的报错（ProbeJS 注入的异常）

```
[ERROR] Command exception: /give @s yuushya:deco_blueprint
java.util.NoSuchElementException: No value present
  at ...net.minecraft.server.commands.GiveCommand.md8a1c3b$probejs$lambda$pjs$injectRegister$6$6(GiveCommand.java:573)
```

栈里带 `$probejs$`：**ProbeJS 8.0.3 给 `GiveCommand` 注入的 lambda** 在物品查不到时直接 `Optional.orElseThrow()`，抛 `NoSuchElementException`，而不是像原版那样干净地返回「未知物品」。

所以「指令报错」有两层原因：

1. **物品确实不存在**（`deco_blueprint` / `dailylife_stuff_blueprint` 未注册）；
2. **ProbeJS 把它变成了 Java 异常**（即 `mods/记得删 ProbeJS-8.0.3.jar` 那个「记得删」）。

另外 `/give @s translate_x`、`/give @s fine_tune_x` 也报同样的错：这两个是**模型名**，不是物品，本来就不该用 `/give`。

建议：发布前删除 ProbeJS（文件名已标注「记得删」）；调试期保留也行，但要知道「未知物品」会以异常形式出现，不是真正的功能故障。

### 6.6 修正后的预期

| 项 | 首轮后 | 修正后（待验证） |
|---|---:|---:|
| 方块小镇 WARN+ERROR | 58 条（含 3 条 ERROR） | **28 条**（26 Create + 2 mixin），ERROR 0 |
| 方块小镇 ERROR | 2 | 0 |
| 全包 ERROR | 121 | ~117 |

若 `filter` 仍不生效（下一轮还有 16 条 `Unknown block 'yuushya:a5x'`），备选方案按优先级：

1. 在「选项 → 资源包」禁用 `mod/yuushya:resourcepacks/mcpatcher_feature`（会一并关闭方块小镇其它 CTM）；
2. 直接改模组 jar 内那 16 份 properties（改动最小，但每次更新要重做）。

### 6.7 最终决定（2026-10-18 22:43）

第二轮实测（22:21 启动）结论：

- **手册 7 条 → 0** ✅（`assets/` 路径正确）
- **模型/贴图 15 条保持 0** ✅
- **配方/`/give` 错误消失** ✅
- **CTM 16 条仍在** ❌：`filter` 对 Continuity 无效（它遍历原始 pack），且 filter 范围写得太宽，把整个 `optifine/ctm/compact/acrylic/` 目录屏蔽了，误伤 16 份**正常的** `l.properties` 与 80 张 `0.png`~`4.png`，导致 `SingleFile` +80、`FallbackResourceManager` +80，WARN 反而涨到 648。

**处置：**

1. **回滚 Paxi 补丁包**：删除 `config/paxi/resourcepacks/[方块小镇] CTM 修复.zip`，并从 `resourcepack_load_order.json` 移除对应条目。
2. **接受 CTM 16 条**：它们是模组残留的失效配置（`tiles=1` + `method=fixed`，不产生任何连接效果），且在 Continuity 的实现下，除直接改 jar 外没有包内解法。

**最终实测（2026-10-18 22:50 启动，ProbeJS 已删除）：**

| 项 | 预期 | 实测 |
|---|---:|---:|
| 全包 WARN | ~488 | **488** ✅ |
| 全包 ERROR | ~114 | **112** ✅ |
| `yuushya` 相关 | 44 | **44**（26 Create + 16 CTM + 2 mixin）✅ |
| `yuushya` ERROR | 0 | **0** ✅ |
| 手册 / 模型相关 | 0 | **0** ✅ |
| P1-01 `Crushing growth` | 0 | **0** ✅ |
| Paxi `was filtered by pack` | 0 | **0** ✅ |
| 启动耗时 | — | **85.332 s**（首轮 88.785 s） |

其余 112 条 ERROR 全部是已知项：`PathPackResources` 37（jar 内非法文件名）、`Continuity` 32（无缝玻璃包）、`GeckoLib` 15、`Util` 9（中文/空格文件名）、`RecipeManager` 7（frostfire 6 + justenoughbreeding 1）、`LootDataType` 4、其余 8 条零散。

> ProbeJS 已从 `mods/` 删除：日志中无任何 `probejs` 字样，也无模组因此报缺依赖（`ClassNotFoundException` 仍为 26 条，与删除前一致，全部是 mixin 噪音）。残留的 `config/kubejs/probe-settings.json` 不影响运行，可留可删。

后续若要彻底清掉这 16 条，唯一可靠做法是改模组 jar 内的 `l_.properties`（**不要动 `l.properties`**）；每次方块小镇更新需重做。

---

## 7. 第二轮修复记录（P2-01 / P2-06，2026-10-18 23:00）

### 7.1 P2-01：`dungeons_arise` 两个进度的父节点

| 新增文件 | 改动 |
|---|---|
| `kubejs/data/dungeons_arise/advancement/find_thornborn_towers.json` | `parent` → `dungeons_arise:wda_root` |
| `kubejs/data/dungeons_arise/advancement/find_fishing_hut.json` | 同上 |

**依据：** 扫描该模组全部 37 个进度的 `parent`，只有这两个引用 `dungeons_arise:find_small_prairie_house`（2.1.68 中不存在该文件），其余一级进度（`find_giant_mushroom`、`find_lighthouse` 等 20 个）全部挂在 `wda_root` 下。因此改用 `wda_root` 与模组自身惯例一致。

**影响面：** 只改 `parent`，`display` / `criteria` / `requirements` 原样保留；两个进度重新出现在 `wda_root` 树下，触发条件不变（`minecraft:location` 检测 `thornborn_towers` / `fishing_hut` 结构）。

**状态：✅ 已修复并验证（2026-10-18 23:11 重启）。** 日志中 `Couldn't load advancements` 归零，进度总数 **9414 → 9416（+2）**——不只是报错消失，两个进度确实重新注册进了 `wda_root` 树。

### 7.2 P2-06：无缝玻璃包 16 份「僵尸 CTM」

| 项 | 内容 |
|---|---|
| 删除 | `assets/minecraft/optifine/ctm/glass/<color>/glass_<color>.properties` × 16 |
| 保留 | 35 条有效规则（普通玻璃 1 + 玻璃板 1 + 染色玻璃 16 + 染色玻璃板 16 + 遮光玻璃 1） |
| 备份 | `docs/tools/backup/Clear Glass Pack 1.21.original.zip` |
| 包内条目 | 966 → 950 |

**为什么只能改 zip：** Continuity 的 `CtmPropertiesLoader` 是逐 pack 读取 CTM（见 6.2 节），高优先级资源包里放同名文件不会覆盖它，`pack.mcmeta` 的 `filter` 也拦不住。

**为什么删了不影响外观：** 被删的 16 份规则没有 `matchBlocks`/`matchTiles`，在 OptiFine 下本来就被静默丢弃；同目录的 `<color>_stained_glass.properties` 已经用**同一批** `0-46.png` 覆盖了同一个方块。

**状态：✅ 已修复并验证（2026-10-18 23:11 重启）。** `ContinuityClient` 相关从 **48 条降到 16 条**（32 条 ERROR 全部消失，只剩 Yuushya 的 16 条已接受 WARN），日志中已搜不到任何 `glass/` 路径的 CTM 报错。

### 7.3 实测结果（2026-10-18 23:11 重启）

| 项 | 修复前（22:50） | 预期 | 实测 | 结果 |
|---|---:|---:|---:|---|
| WARN | 488 | 488 | **488** | ✅ 无变化 |
| ERROR | 112 | ~79 | **79** | ✅ 精确命中（−33） |
| Continuity 相关 | 48（32 ERROR + 16 WARN） | 16 | **16 WARN** | ✅ |
| `Couldn't load advancements` | 1 | 0 | **0** | ✅ |
| 进度总数 | 9414 | — | **9416** | ✅ +2 |
| 玻璃包相关报错 | 32 | 0 | **0** | ✅ |

**无回归验证：** 按 logger 对比两次会话的 WARN 分布，**没有任何一项发生变化**，说明删掉的 16 份 CTM 与新增的两个进度 JSON 未引入新问题。

剩余 79 条 ERROR 的构成（与修复前完全一致，仅少了那两类）：

| 来源 | 条数 |
|---|---:|
| `PathPackResources`（jar 内非法文件名，含 `gIass_hilight` 36 条） | 37 |
| `GeckoLib` | 15 |
| `Util`（中文/空格文件名） | 9 |
| `RecipeManager`（frostfire 6 + justenoughbreeding 1） | 7 |
| `LootDataType`（beyonddimensions） | 4 |
| `EntityIconLoader` / `AnimationCodecs` | 2 / 2 |
| `Curios` / `VanillaPackResources` / `ModFile`(pride) | 1 / 1 / 1 |

### 7.4 验证命令（已执行，结果为实测值）

```powershell
(Select-String -Path logs\latest.log -Pattern 'ContinuityClient').Count           # 16
(Select-String -Path logs\latest.log -Pattern "Couldn't load advancements").Count # 0
(Select-String -Path logs\latest.log -Pattern '/ERROR\]').Count                   # 79
(Select-String -Path logs\latest.log -Pattern 'Loaded \d+ advancements')          # 9416 / 484
```

### 7.5 整体进展

| 会话 | WARN | ERROR | 说明 |
|---|---:|---:|---|
| 20:03 初始 | 539 | 117 | 首次诊断基线 |
| 22:21 方块小镇第二轮 | 648 | 114 | filter 误伤 +160，已回滚 |
| 22:50 回滚后 | 488 | 112 | 方块小镇 44 条稳定，P1-01 验证通过 |
| **23:11 本轮** | **488** | **79** | P2-01 / P2-06 修复完成 |

累计：**ERROR −38（117→79）**，WARN −51（539→488）；方块小镇剩 44 条已接受噪音。

---

## 附录：日志提取脚本

```powershell
$p = 'logs\latest.log'
$sr = New-Object System.IO.StreamReader($p, [System.Text.Encoding]::UTF8)
$lines = $sr.ReadToEnd() -split "`r?`n"; $sr.Close()

# 所有 ERROR
$lines | Where-Object { $_ -match '/ERROR\]' }

# 按 logger 统计
$lines | Where-Object { $_ -match '/(WARN|ERROR)\] \[([^\]]+)\]' } |
  ForEach-Object { [regex]::Match($_, '/(WARN|ERROR)\] \[([^\]]+)\]').Groups[2].Value } |
  Group-Object | Sort-Object Count -Descending | Format-Table -AutoSize

# 异常 + 后续 10 行堆栈
for ($i = 0; $i -lt $lines.Count; $i++) {
  if ($lines[$i] -match 'Exception|Error:') {
    "#### line $($i+1)"; $lines[$i..([Math]::Min($i+10, $lines.Count-1))]
  }
}
```

> 说明：日志为 UTF-8；PowerShell 直接 `Get-Content` 在 GBK 控制台下会把中文显示成乱码，建议先 `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`。
>
> 本文档由 AI 生成，按项目规定存放于 `docs/plans/`。

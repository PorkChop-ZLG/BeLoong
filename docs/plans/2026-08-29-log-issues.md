# 整合包日志问题分析（2026-08-29）

> 生成时间：2026-08-29  
> 分析来源：`logs/latest.log`、`logs/debug.log`（最近一次完整启动并进入存档的会话）  
> 状态：未修改任何文件，仅记录问题清单

## 总览

- 本次游戏**正常启动并进入存档**，最后正常退出，没有产生新的崩溃报告。
- 之前修复的两个问题已确认消失：
  - `iceandfire:immune_to_gorgon_stone` 不再引用 `alshanex_familiars`。
  - Beautify 战利品表不再报 `No key value in MapLike`。
- 启动耗时仍较长：`ModernFix: Game took 105.636 seconds to start`。
- 日志中仍存在较多资源、动画、配方、战利品、渲染与兼容性警告。

## 严重程度定义

| 级别 | 含义 |
|---|---|
| 🔴 P1 | 高优先级：会导致游戏内容缺失、配方/战利品失效、启动明显异常 |
| 🟠 P2 | 中优先级：影响显示、兼容性或性能，但不阻止游戏进行 |
| 🟡 P3 | 低优先级：噪音类、环境类或非功能性提示 |

---

## 🔴 P1 高优先级问题

### P1-01 多个配方解析失败，相关物品/合成会缺失

**来源：** `RecipeManager` / `KubeJS Server`

受影响配方：

- `frostfire_dragon:rime_obsidian_lantern`
  - 引用不存在的物品 `frostfire_dragon:rime_crystal_cluster`
- `frostfire_dragon:crying_obsidian_bricks_chiseled_from_stonecutting`
- `frostfire_dragon:crying_obsidian_brick_wall_from_stonecutting`
- `frostfire_dragon:crying_obsidian_brick_stairs_from_stonecutting`
- `frostfire_dragon:crying_obsidian_brick_slab_from_stonecutting`
- `frostfire_dragon:crying_obsidian_pillar_from_stonecutting`
  - 均引用不存在的 `frostfire_dragon:crying_obsidian_*` 物品
- `justenoughbreeding:breeding/iceandfire/lightning_dragon`
  - 引用 `iceandfire:dragonegg_amythest`，疑似拼写应为 `amethyst`
- `ultramarine:cobalt_dust_compat`
  - ingredient 为空
- `iss_magicfromtheeast:refined_jade_ingot_alternative`
  - ingredients 中存在空项

**影响：** 相关合成配方无法加载，游戏中可能看不到对应合成表。

**建议：** 核对 `frostfire_dragon`、`justenoughbreeding`、`ultramarine`、`iss_magicfromtheeast` 的版本与物品 ID，更新到互相配套的版本；或通过 KubeJS 数据包覆盖修正错误配方。

---

### P1-02 战利品表解析失败

**来源：** `LootDataType`

- `beyonddimensions:blocks/schematicannon_pathway`
- `beyonddimensions:blocks/rs_net_pathway`
- `beyonddimensions:blocks/ars_source_pathway`
- `beyonddimensions:blocks/mana_pool_pathway`

**原因：** 战利品表引用了不存在的物品：

```
Unknown registry key in ResourceKey[minecraft:root / minecraft:item]:
  beyonddimensions:schematicannon_pathway
```

**影响：** 这些方块/物品可能没有正确掉落。

**建议：** 更新 `beyonddimensions` 到与当前物品注册匹配的版本，或通过数据包覆盖修复这些战利品表。

---

### P1-03 启动时间过长

**日志：**

```
ModernFix: Game took 105.636 seconds to start
```

**影响：** 玩家等待时间过长，接近“卡死”的体验。

**建议：** 结合 P2 中的大量模型/动画/纹理加载错误一起排查；优先处理资源包、GeckoLib、Serene Shrubbery 等加载错误。

---

## 🟠 P2 中优先级问题

### P2-01 GeckoLib 动画/模型加载错误

**日志示例：**

```
Unable to parse animation: climb
  -> Failed to parse expression 'q.ground_speed<0.8?4'
```

其他问题：

- 大量动画文件命名不规范，应以 `.animation.json` 结尾。
- 模型版本过新：
  ```
  Unsupported geometry json version: 1.21.0 for model dragonsurvival:geo/neo_crystcursed_dragon.geo.json
  ```
- 涉及模组：`gametechbcs_spellbooks`、`irons_spellbooks`、`dragonsurvival`、`darkdoppelganger`、`iss_magicfromtheeast`、`block_factorys_bosses` 等。

**影响：** 相关生物/物品动画可能无法播放或显示异常。

---

### P2-02 Serene Shrubbery 模型 JSON 非法

**日志示例：**

```
Invalid rotation -90.0 found, only -45/-22.5/0/22.5/45 allowed
Missing axis, expected to find a string
```

**涉及模型：** `serene_shrubbery:models/custom/fireweedd.json`、`fireweedredone.json`、`newfireweed.json`、`redonefireweed.json`、`stupidfireweedwork.json` 等。

**影响：** 火草类方块模型可能显示异常或缺失。

---

### P2-03 PlayerAnimator 动画错误

**日志示例：**

```
IndexOutOfBoundsException: Index 0 out of bounds for length 0
```

以及：

```
Animation player_animation/casting_animations.json is in wrong directory: "player_animation"
```

**影响：** 玩家动画（施法、模型加入/离开等）可能失效。

---

### P2-04 EMF 模型创建超过 64 次

**涉及模型：**

- `butchercraft:rabbithead`
- `eternal_starlight:accessory`
- `cataclysm:kobolediator_head_model`
- `cataclysm:aptrgangr_head_model`
- `cataclysm:draugr_head_model`

**影响：** 这些模型会被 EMF 忽略，可能显示为默认/缺失模型。

---

### P2-05 Continuity / 无缝玻璃资源包报错

**来源：** `[无缝玻璃] Clear Glass Pack 1.21.zip`

**日志示例：**

```
No tile or block matches provided in file 'minecraft:optifine/ctm/glass/black/glass_black.properties'
No valid connection type provided ...
```

**影响：** 玻璃连接纹理可能不生效。

**建议：** 更新或移除该资源包。

---

### P2-06 缺失模型/纹理/方块状态

**常见缺失：**

- `frostfire_dragon:block/rime_glass_pane_post_full`
- `beyonddimensions:item/test_item_generate`
- `gtbcs_spell_lib:item/gsl_example_*`
- `fdbosses:item/no_entity_spawn_block`
- `fdlib:item/test_multiblock`
- `irons_spellbooks:item/template_open_spell_book_model`
- `iss_magicfromtheeast:item/affinity_ring_dune`
- `iss_magicfromtheeast:item/scroll_dune`
- `cinematiccataclysm:item/debug_stick`
- `netherman` 系列方块状态缺失
- `butchercraft:blockstates/blood_fluid_block.json` 多个 level 缺失

**影响：** 对应物品/方块可能显示为紫黑方块或模型缺失。

---

### P2-07 着色器警告

**涉及：** `fdbosses`、`fdlib`、`ldlib2`、`star_dragon`

**日志示例：**

```
Shader fdbosses:malkuth_boss_bar could not find sampler named Sampler0
Shader star_dragon:black_hole could not find uniform named EventHorizonRatio
```

**影响：** 部分 Boss 特效、黑 hole 等视觉效果可能异常。

---

### P2-08 ModernUI + HealthBars 渲染异常

**日志示例：**

```
Failed to add SDF stroke to fixed buffers
java.lang.UnsupportedOperationException: null
  at icyllis.modernui.mc.text.TextRenderType.makeSDFStrokeType(...)
  at fuzs.healthbars.client.handler.GuiRenderingHandler.drawDamageNumber(...)
```

**影响：** 伤害数字描边/血条渲染可能失败，属于渲染兼容问题。

---

### P2-09 Curios API 槽位未注册

**日志：**

```
scroll is not a registered slot type!
```

**影响：** 依赖 `scroll` 槽位的饰品/物品可能无法装备。

---

### P2-10 Artifacts 无法给实体装备物品

**日志示例：**

```
Could not equip item 'x irons_spellbooks:frozen_bone' on spawned entity 'Stray'...
```

**影响：** 流浪者等生物可能缺少预期装备。

---

### P2-11 服务器瞬时卡顿

**日志示例：**

```
Can't keep up! Is the server overloaded? Running 11595ms or 231 ticks behind
```

**影响：** 进入存档/区块加载时出现明显卡顿。

---

### P2-12 AllTheLeaks 兼容补丁失败

**日志：**

```
ExceptionInInitializerError
Caused by: java.lang.RuntimeException: VarHandler is null
```

**影响：** AllTheLeaks 对 JEI 的某个补丁未生效，非致命。

---

### P2-13 ModernFix 报告错误时机注册 ReloadListener

**日志：**

```
A mod is calling registerReloadListener at the wrong time.
```

**影响：** 潜在并发风险，当前未崩溃。

---

## 🟡 P3 低优先级问题

### P3-01 Mixin 类加载警告（大量）

**日志示例：**

```
Error loading class: com/simibubi/create/... (ClassNotFoundException)
Error loading class: mekanism/... (ClassNotFoundException)
Error loading class: me/jellysquid/mods/sodium/... (ClassNotFoundException)
```

**说明：** 某些模组的 mixin 配置引用了未安装模组的类，通常只是启动噪音。

### P3-02 网络/证书类报错

**涉及：** Iris、Exposure、Moonlight

```
SSLHandshakeException: PKIX path building failed
```

**影响：** 在线更新/数据拉取失败，不影响单机游玩。

### P3-03 Xaero 在线数据过期

```
Online mod data expired! Date: Mon Aug 24 19:29:54 CST 2026
```

### P3-04 无效资源路径/文件名

**常见：**

- `beyonddimensions:textures/gui/sprites/widget/漏斗图.png` 等中文文件名
- `dragonsurvival:textures/armor/dragon_model/cnb/flower_crown 2.png`
- `legendary_monsters:textures/entity/posessed_paladin/old/posessed_paladin — kopia.png`
- `minecraft:textures/block/gIass_hilight.png` / `gIass_e.png`（拼写/命名异常，重复出现多次）

**影响：** 这些资源被忽略，可能导致对应贴图缺失。

### P3-05 TeleportWaypoint 配置回退

```
[TeleportWaypoint] Xaero config options unavailable, using mod config fallback
```

### P3-06 其他少量警告

- `Sodium-VertexConsumerTracker` 性能提示
- `Unknown attribute 'forge:entity_gravity'` / `forge:step_height_addition`
- `Missing sound for event` 系列

---

## ✅ 已确认修复/消失的问题

| 问题 | 状态 |
|---|---|
| `iceandfire:immune_to_gorgon_stone` 引用 `alshanex_familiars` 实体 | ✅ 已修复 |
| Beautify 战利品表 `No key value in MapLike` | ✅ 已修复 |
| `minecraft:entities/bee` 引用 `kubejs:abeemination` | ✅ 本次未出现 |
| `alshanex_familiars` 在 Sound Physics 配置中的残留 | ✅ 本次未出现 |
| NeoForge 版本差异警告（iceandfire/uranus） | ✅ 本次未出现 |

---

## 建议处理顺序

1. 优先处理 **P1**：配方、战利品、启动时间。
2. 然后处理 **P2** 中影响较大的模型/动画/资源包问题。
3. 最后清理 **P3** 噪音类问题。

> 本文档由 AI 生成，按项目规定存放于 `docs/plans/`。

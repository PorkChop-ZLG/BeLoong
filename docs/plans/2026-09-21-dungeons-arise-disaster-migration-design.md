# 地牢浮现之时 → 天灾维度迁移 设计文档
## 十一、原点禁区（2026-09-21 补记，非原设计）

**需求：** 让地牢浮现之时的地面结构在天灾维度原点 250 方块（约 15.6 区块）半径内不生成。

**结论：原版 1.21.1 无法实现，必须换用模组 placement 类型。**

依据（源码已逐条核对）：
- StructurePlacementType.java:8-9 只注册 andom_spread 与 concentric_rings；
- StructurePlacement 的 codec 参数仅 locate_offset / requency_reduction_method / requency / salt / exclusion_zone（:34-45），**无原点/距离字段**；
- RandomSpreadStructurePlacement.isPlacementChunk（:82-85）纯种子判定；
- placement 类型由代码注册（Registry.register(BuiltInRegistries.STRUCTURE_PLACEMENT, ...)），数据包只能引用；
- exclusion_zone 语义是"避开另一结构集的区块"（:132-146），且结构集需先过 hasBiomesForStructureSet 过滤（ChunkGeneratorStructureState.java:55-57），无法用标记集伪造禁区。

**采用方案：** eloong:disaster_ground_set 的 placement 改为
moogs_structures:advanced_random_spread + min_distance_from_world_origin: 250。

- 该类型由 MoogsStructureLib 3.1.2 注册（MoogsStructuresStructurePlacementType，注册名 dvanced_random_spread），实例中 MoogsVoyagerStructures / MoogsSoaringStructures / MoogsStructureLib 均依赖它；
- 字段语义（同源参考实现 Repurposed Structures → Dragon Survival AdvancedRandomSpread.java:121-133）：xBlockPos = x*16; zBlockPos = z*16; if (x²+z² < min²) return false; → **单位方块**、禁区为**圆**；
- **原点是所在维度自身的原点**，非主世界原点：该类常量池无任何跨维度引用，唯一上下文是每维度构建的 ChunkGeneratorStructureState；
- 天灾维度 coordinate_scale: 1.0 且传送门下行 1:1，故此处两种解读坐标一致。

**不改动的部分：** disaster_underground_set 保持 minecraft:random_spread；spacing/separation 保持 32/16；成员与权重不变。

**salt：** 地面 88371664、地下 342415936。这是**用户有意设定的最终值**，与本次 placement 改动无关；文档他处出现的 20260921/20260922 为设计稿原拟值，已作废。详见 §7 参数表下的说明。

**待实机验收（新存档）：** 反复 /locate structure dungeons_arise:<结构> 于 eloong:disaster，确认落点距原点 ≥ 250 方块。

> **命名更新（2026-09-21，不改写正文）：** 结构集已按「维度_位置_set」重命名，本文正文中的旧 ID 对应关系为 
`disaster_set` → `disaster_sky_set`、`disaster_set_ground` → `disaster_ground_set`、`disaster_set_underground` → `disaster_underground_set`、`disaster_set_sea` → `disaster_sea_set`。
另外：主题标签已由 31 个收敛为 13 个（见 decisions-log）；地面集权重已归一为大型 1 / 小型 2（`1:16 2:13`）；两套结构集的 `exclusion_zone` 已移除（见本目录 §9）。


**Date:** 2026-09-21
**Status:** Implemented（Batch 1–6 已完成；静态校验 33 项检查 / 0 错误通过；运行期 `/locate` 验证待执行）
**Approach:** A —— `c:` 型主题命名空间 `beloong:disaster/*` + 总账 `beloong:is_disaster` + 两套结构集

> 本文由 brainstorming 技能产出，全部数字均由脚本核对，无手算。
> 与之同构的既有先例：`docs` 中悚域迁移（Legendary Monsters）与末地迁移。

---

## 一、Problem Statement

「地牢浮现之时」（`dungeons_arise`，40 个结构）目前在整合包中：

1. 通过 `#minecraft:is_taiga` / `#c:is_jungle` / `#c:is_desert` / `#forge:is_desert` 等**被 BWG 污染过的原版聚合标签**筛选群系，因此在**天灾维度零星漏生**（行为不可控）；
2. 其中 5 个结构已在早前被迁移到末地，用的是**直接改写结构 JSON 的 `biomes` 字段**（权宜手段，绕过了模组的标签抽象层）；
3. 两个原始结构集 `major_structures`(32) / `minor_structures`(6) 共覆盖 **38 个**结构；40 个结构 JSON 中另有 **3 个不在任何结构集里**（视为已删除）：`giant_mushroom`、`mining_system` 有结构 JSON 但为孤儿，`small_prairie_house` **连结构 JSON 都不存在**（仅剩一个群系标签文件）。**这三者均不纳入迁移。**

**目标**：把除末地 5 个与已删除 3 个以外的 **33 个**结构迁移到天灾维度，用**群系标签**精准指定气候归属，并用**两套结构集**统一管理密度与互斥。

**同时**：完善 `beloong:is_disaster` 自建总账标签，同步 BWG 最新群系与化龙核心自制群系。

---

## 二、Design

### 2.1 Architecture：三层标签体系

```
beloong:is_disaster                      ← 总账（60 项 = 55 BWG + 5 化龙自制）
    │                                      用途：地下结构的总群系门槛
    │
beloong:disaster/<c:主题>                 ← 31 个主题标签，内容为裸群系 ID
    │                                      用途：需求「精准映射」的载体
    │
dungeons_arise:has_structure/*_biomes     ← 33 个结构标签，replace:true
                                            可引多个主题（values 数组多引用）
```

**关键设计点（用户确认）**：

| 层 | 写法 | 理由 |
|---|---|---|
| `beloong:disaster/*` | **裸群系 ID**，不用 `#biomeswevegone:` 引用 | 便于后续人工审核与管理 |
| `beloong:disaster/*` | **`replace: false`** | 这是**自制标签**，没有上游先写入的内容，写 `false` 语义正确 |
| `beloong:is_disaster` | 5 个自制群系**置于 `values` 数组最上方** | 显式区分"化龙核心自制"与"BWG 群系" |
| `dungeons_arise:has_structure/*` | **`replace: true`** + **可引多个主题** | 覆盖模组自建标签（有上游内容）；多主题靠多引用表达，无需合并标签 |
| 结构 JSON 的 `biomes` 字段 | **不改** | 改它等于绕过模组的标签抽象层；标签才是正确的抽象边界 |

> ⚠️ **`replace` 语义澄清**：`replace` 是"是否清空此前数据包累积的同名标签条目"，不是"是否文件优先"。自制全新标签没有上游条目，故 `false` 与 `true` 结果相同，但 `false` 语义正确。

### 2.2 主题标签全清单（31 个：改写 22 + 新建 9）

| # | 标签 ID | 群系数 | 内容来源 | 动作 |
|---|---|---|---|---|
| 1 | `disaster/is_hot/overworld` | 19 | `biomeswevegone:climate/hot` | 改写 |
| 2 | `disaster/is_temperate/overworld` | 19 | `biomeswevegone:climate/temperate` | 改写 |
| 3 | `disaster/is_cold/overworld` | 17 | `biomeswevegone:climate/cold` | 改写 |
| 4 | `disaster/is_wet/overworld` | 8 | `biomeswevegone:climate/wet` | 改写 |
| 5 | `disaster/is_dry/overworld` | **6** | 展开 `biomeswevegone:climate/dry` | 改写 |
| 6 | `disaster/is_dense_vegetation/overworld` | **31** | 展开 `biomeswevegone:density/dense` | 改写 |
| 7 | `disaster/is_sparse_vegetation/overworld` | 8 | `biomeswevegone:density/sparse` | 改写 |
| 8 | `disaster/is_desert` | 3 | `biomeswevegone:desert` | 改写 |
| 9 | `disaster/is_plains` | 9 | `biomeswevegone:plains` | 改写 |
| 10 | `disaster/is_swamp` | 5 | `biomeswevegone:swamp` | 改写 |
| 11 | `disaster/is_sandy` | 5 | `biomeswevegone:sandy` | 改写 |
| 12 | `disaster/is_floral` | 7 | `biomeswevegone:floral` | 改写 |
| 13 | `disaster/is_dead` | 1 | `biomeswevegone:dead` | 改写 |
| 14 | `disaster/is_wasteland` | 3 | `biomeswevegone:wasteland` | 改写 |
| 15 | `disaster/is_magical` | 4 | `biomeswevegone:magical` | 改写 |
| 16 | `disaster/is_mountain` | 2 | `biomeswevegone:mountain` | 改写 |
| 17 | `disaster/is_mountain/peak` | 2 | `biomeswevegone:peak` | 改写 |
| 18 | `disaster/is_mountain/slope` | 2 | `biomeswevegone:slope` | 改写 |
| 19 | `disaster/is_windswept` | **1+1** | `biomeswevegone:windswept` **+ `beloong:windswept`** | 改写+追加 |
| 20 | `disaster/is_snowy` | 2 | `biomeswevegone:snowy` | 改写 |
| 21 | `disaster/is_icy` | 1 | `biomeswevegone:icy` | 改写 |
| 22 | `disaster/is_tree/coniferous` | 10 | `biomeswevegone:coniferous` | 改写 |
| 23 | `disaster/is_forest` | 19 | `biomeswevegone:forest` | **新建** |
| 24 | `disaster/is_taiga` | 2 | `biomeswevegone:taiga` | **新建** |
| 25 | `disaster/is_jungle` | 4 | `biomeswevegone:jungle` | **新建** |
| 26 | `disaster/is_badlands` | 4 | `biomeswevegone:badlands` | **新建** |
| 27 | `disaster/is_savanna` | 3 | `biomeswevegone:savanna` | **新建** |
| 28 | `disaster/is_ocean` | **2+2** | `biomeswevegone:ocean` **+ `beloong:ocean` + `beloong:frozen_ocean`** | **新建** |
| 29 | `disaster/is_beach` | 3 | `biomeswevegone:beach` | **新建** |
| 30 | `disaster/is_hill` | **1** | **自建**（= `beloong:windswept`） | **新建** |
| 31 | `disaster/is_river` | **1** | **自建**（= `beloong:river`） | **新建** |

> **计数口径说明**：下表"群素数"为**递归展开后的唯一群系数**（拍平为裸 ID 后的大小），非 BWG 标签文件的顶层条目数。二者会在标签引用处不同——例如 `biomeswevegone:density/dense` 顶层 15 条（含 3 条标签引用 `#forest`/`#jungle`/`#swamp`），展开去重后为 **31**；`biomeswevegone:climate/dry` 顶层 4 条，展开后为 **6**。

**已取消**：`disaster/is_cave`（用户决定：地下结构改用 `#beloong:is_disaster` 总账，不再需要洞穴专属主题）。

**主题轴对齐说明**：命名与分类轴**完全对应 NeoForge 的 `c:` 约定标签**。但 NeoForge 的 `c:` 定义了 ~80 个主题，BWG 只填了 23 个（且全是转发到 `biomeswevegone:*`），因此 `is_forest` / `is_taiga` / `is_jungle` / `is_badlands` / `is_savanna` / `is_ocean` / `is_beach` / `is_hill` / `is_river` 这 9 个的内容需自行组织。

**完备性口径**：**完备优先**（用户决定）——每个主题标签尽量含全语义相符的群系，允许一个群系同属多个主题；**零消费者的主题标签保留不删**，供将来新增结构直接引用。

### 2.3 化龙核心 5 个自制群系的落位

这 5 个群系是**逐字复制原版群系 JSON 后改名**，刻意不带任何原版/BWG 标签，因此**必须写裸 ID**，且置于各文件 `values` 数组最上方。

| 自制群系 | 参数点 | 落入的主题标签 |
|---|---|---|
| `beloong:windswept` | **352** | `disaster/is_windswept` + `disaster/is_hill` |
| `beloong:river` | 18 | `disaster/is_river` |
| `beloong:ocean` | 8 | `disaster/is_ocean` |
| `beloong:frozen_ocean` | 4 | `disaster/is_ocean` |
| `beloong:caves` | 3 | **（无主题标签；仅进入 `is_disaster` 总账）** |

实测确认（化龙核心 jar `data/beloong/worldgen/biome/`）：`caves`、`frozen_ocean`、`ocean`、`river`、`windswept` 五个 ID 一致；同目录另有 `loong_palace`，**不属天灾体系，不纳入**。

### 2.4 总账 `beloong:is_disaster` 升级

| 项 | 现状（实测） | 目标 |
|---|---|---|
| BWG 群系 | 55 | 55（**不变**，已与 BWG 全部群系逐项对齐、零缺失零多余） |
| 自制群系 | 0 | **5**（置顶） |
| 合计 | 55 | **60** |

> BWG 基线核对：BWG 2.6.0 共 55 个 `worldgen/biome` JSON，与 `biomeswevegone:overworld` 标签双向 diff 为空。
> `biomeswevegone:eroded_borealis` 已由用户手动启用，**会生成**，因此保留在清单内。

### 2.5 Components：结构 → 主题映射（33 个）

**地面组 `beloong:disaster_set_ground`（29 个）**

| 主题引用 | 数量 | 结构 |
|---|---|---|
| `is_forest` | 6 | `greenwood_pub`、`mushroom_house`、`mushroom_mines`、`mushroom_village`、`thornborn_towers`、`mechanical_nest` |
| `is_plains` | 5 | `coliseum`、`illager_campsite`、`illager_windmill`、`merchant_campsite`、`wishing_well` |
| `is_taiga`(+`is_hill`/`is_mountain`/`is_snowy`) | 4 | `abandoned_temple`、`illager_fort`、`monastery`、`bathhouse` |
| `is_ocean`(+`is_beach`) | 5 | `illager_corsair`、`illager_galley`、`typhon`、`undead_pirate_ship`、`fishing_hut` |
| `is_desert` | 3 | `ceryneian_hind`、`scorched_mines`、`shiraz_palace` |
| `is_badlands` | 2 | `bandit_towers`、`bandit_village` |
| `is_mountain` | 1 | `kisegi_sanctuary` |
| `is_windswept` | 1 | `small_blimp` |
| `is_jungle` | 1 | `jungle_tree_house` |
| `is_beach`(+`is_plains`) | 1 | `lighthouse` |
| **合计** | **29** | |

**地下组 `beloong:disaster_set_underground`（4 个）**——全部引 `#beloong:is_disaster`

| 结构 | `step` | `start_height` | 说明 |
|---|---|---|---|
| `foundry` | `underground_structures` | `absolute: -10` | 埋地 |
| `mining_complex` | `underground_structures` | `absolute: -5` | `terrain_adaptation: bury` |
| `plague_asylum` | `strongholds` | `absolute: 0` | `terrain_adaptation: bury` |
| `infested_temple` | `fluid_springs` | `absolute: -32` | `project_start_to_heightmap: WORLD_SURFACE_WG` |

**闭合校验（脚本实测）**：
```
jar 内结构 JSON                          40
  − 末地迁移                             5
  − 已删除（不入集）                      2   （giant_mushroom、mining_system）
  − 地下组                               4
  = 地面组                              29
  参与迁移 = 地面 29 + 地下 4            = 33  ✅
```

> **`small_prairie_house` 不存在**：本版 DA（`DungeonsArise-1.21.1-2.1.68`）的 `worldgen/structure/` 下**没有**该结构 JSON，只有残留的 `tags/worldgen/biome/has_structure/small_prairie_house_biomes.json`。它是我在讨论过程中从列表里**误采的幻觉项**，已从全部清单、权重表与文件计数中剔除。详见第五节复盘。

**排除项**：
- 末地迁移 5 个：`aviary`、`keep_kayra`、`heavenly_rider`、`heavenly_conqueror`、`heavenly_challenger`（保留其现有结构 JSON override）
- 已删除 1 个：`mining_system`（`has_structure/mining_system_biomes` 保持 `values: []` 不动，后续需要时再启用）

**权重分级（参照 `dreadland_set` 的 3/2/1 三档；脚本核对：地面 29 = 7+12+10，总计 33 = 7+16+10）**

| 权重 | 数量 | 结构 |
|---|---|---|
| **3** | 10 | `fishing_hut`、`wishing_well`、`bathhouse`、`merchant_campsite`、`illager_campsite`、`small_blimp`、`lighthouse`、`jungle_tree_house`、`abandoned_temple`、`mushroom_house` |
$116 | `greenwood_pub`、`mushroom_village`、`mushroom_mines`、`thornborn_towers`、`mechanical_nest`、`illager_fort`、`illager_windmill`、`kisegi_sanctuary`、`bandit_towers`、`scorched_mines`、`ceryneian_hind`、`plague_asylum`、`foundry`、`mining_complex`、`infested_temple``undead_pirate_ship` |
| **1** | 7 | `coliseum`、`monastery`、`shiraz_palace`、`bandit_village`、`illager_corsair`、`illager_galley`、`typhon` |
| **合计** | **33** | 10 + 16 + 7 = 33 ✅ 与成员表闭合 |

### 2.6 Data Flow：生成判定链路

天灾维度（`beloong:disaster`，`settings: minecraft:overworld`）中一个 DA 结构的生成判定：

```
① ChunkGenerator.createState 把全部 structure set 交给该维度
        ↓
② 对该 set 内每个结构：hasBiomesForStructureSet(generator, structure)
        ↓
③ structure.biomes（= #dungeons_arise:has_structure/<x>_biomes）
        与 dimension.possibleBiomes() 求交，非空才继续
        ↓
④ placement（random_spread: spacing/separation/salt）给出候选区块
        ↓
⑤ exclusion_zone 过滤（本方案：地面↔地下互斥；地下↔minecraft:strongholds）
        ↓
⑥ start_height 决定垂直落点（biomes 只管水平，不管 Y）
```

**关键推论**：`biomes` 标签是**三维不敏感**的，只管"这个群系 ID 合不合格"。地下结构之所以在地下，靠的是 `start_height` 为负值，而不是靠群系标签。这正是 `infested_temple`（`-32`）、`kisegi_sanctuary`（`-32`）能用**地表群系**却生在地下的原因。

### 2.7 结构集定义

| 项 | `disaster_set_ground` | `disaster_set_underground` | `disaster_set`（既有，**不动**） |
|---|---|---|---|
| 定位 | 地面结构 | 地下结构 | **空中/悬浮结构**（mss `Soaring` 系，Y 上限 100~200） |
| `spacing` | **32** | **32** | 20（保持） |
| `separation` | **16** | **16** | 10（保持） |
| salt | **88371664** | **342415936** | 20260604（保持） |
| `exclusion_zone` | 无（设计稿原为互斥，实施时移除，见 §9） | 无（同上） | — |
| 成员数 | 29 | 4 | 46 |
| 单点密度 | 0.01563 | 0.01563 | 0.02500 |

> **本表的 salt 为最终值（2026-09-21 用户确认）：** 地面 `88371664`、地下 `342415936`。
> 取值为原 DA 结构集 salt（`88371663` / `342415935`）**各 +1**，从而在保留"与原集同源可追溯"的同时
> 与原集错开，二者在全实例 103 个结构集中各自唯一（详见 §7 风险表的复用说明）。
>
> 本表描述的 ground / underground 两套 set **由脚本管理**；既有空中集与七海 sea 集为**手工维护**，边界见 §12。

**间距参照系**：`dreadland_set` 30/15、`the_end_set` 48/24、`the_nether_set` 60/30、`the_nether_set_small` 30/15、`the_end_set_air` 50/45。全整合包 `separation = spacing / 2` 为惯例。

**与空中 `disaster_set` 不设互斥**（用户决定）：mss 空中结构在 Y=100~200，DA 地面结构在 Y≈0，实际冲突概率低；不设可降低耦合，也让 `disaster_set` 完全不受本次改动影响。

**`exclusion_zone` 是单值字段**（实测：全实例 12 个结构集使用该字段，**0 个**使用多个；其类型为单对象 `{"chunk_count":N,"other_set":"..."}` 而非数组）。因此地下组**只能设置一个互斥**，取 `beloong:disaster_set_ground`，**放弃 `minecraft:strongholds`**：地面↔地下在 forest/taiga/plains 等群系上高度重叠，互斥收益远大于要塞。

### 2.8 完整文件清单（70 项操作）

| 类别 | 路径 | 数量 | 动作 |
|---|---|---|---|
| 主题标签（已有） | `kubejs/data/beloong/tags/worldgen/biome/disaster/**` | **22** | 拍平为裸 ID + `replace:false` |
| 主题标签（新建） | `.../disaster/{is_forest,is_taiga,is_jungle,is_badlands,is_savanna,is_ocean,is_beach,is_hill,is_river}.json` | 9 | 新建 |
| 总账 | `.../biome/is_disaster.json` | 1 | 追加 5 个自制群系（置顶） |
| 结构标签 | `kubejs/data/dungeons_arise/tags/worldgen/biome/has_structure/*_biomes.json` | 33 | `replace:true` → 主题引用 |
| 结构集（新建） | `kubejs/data/beloong/worldgen/structure_set/disaster_set_ground.json`、`disaster_set_underground.json` | 2 | 新建 |
| 结构集（清空） | `kubejs/data/dungeons_arise/worldgen/structure_set/major_structures.json`、`minor_structures.json` | 2 | `"structures": []` |
| **不动** | `kubejs/data/beloong/worldgen/structure_set/disaster_set.json` | — | **空中结构集，极其重要，保持原样** |
| **不动** | 5 个末地结构的 `dungeons_arise/worldgen/structure/*.json` override | — | 保留（JSON override 优先级高于 `biomes` 标签引用） |
| **不动** | `dungeons_arise/tags/worldgen/biome/has_structure/mining_system_biomes.json` | — | 保持 `values: []` |
| **合计** | | **69** | 22+9+1+33+2+2 = 69 ✅ |

> 主题标签总数 **31 = 已有 22（改写）+ 新建 9**。`disaster/is_mountain.json`（父标签）本身也有文件，计入 22 内。
> 已取消 `disaster/is_cave`，故 31 而非 32。

---

## 三、Error Handling

| 失败模式 | 后果 | 缓解 |
|---|---|---|
| `beloong:disaster/*` 引用了**未注册**的群系 ID | 标签绑定失败，**整个数据包加载报错**（KubeJS/数据包会拒绝加载） | 每个 ID 必须与 BWG 2.6.0 / 化龙核心 jar 实际注册项逐一核对 |
| `has_structure/*` 引用了**不存在的主题标签** | 同上 | 31 个主题标签必须**全部先落地**，再写 33 个结构标签 |
| 拼错群系 ID（如 `zelkova` vs `zelkova_forest`） | 整包加载失败，启动崩溃 | 用脚本从源 jar / 源目录生成清单，不手写 |
| **引用了不存在的结构 ID**（如 `dungeons_arise:small_prairie_house`） | 结构集 JSON 解析失败，**该结构集整体失效** | 结构集成员必须用脚本从 `worldgen/structure/` 实际文件枚举得出，**禁止手抄**（本设计已因此踩坑，见第五节） |
| 清空 DA 原结构集后忘记新建 set | **33 个迁移结构在主世界及所有维度全部消失** | 两套新 set 必须先建好再清空原 set；或同批完成 |
| `exclusion_zone` 引用了不存在的 set ID | 该 set 加载失败 | `minecraft:strongholds` 与两个新 set ID 必须精确拼写 |
| `salt` 与既有 set 冲突 | 候选点重合，结构挤在一起 | 最终值 `88371664`/`342415936` 已核实为全实例唯一（该维度两套 set 间距相同仅靠 salt 区分；设计稿原拟的 `20260921`/`20260922` 因与既有 salt 命名同族易混，改用原集 +1 方案） |

---

## 四、Decisions Made

1. **改 `has_structure` 标签，不改结构 JSON 的 `biomes` 字段**（用户纠正）：标签是模组的抽象边界；改 JSON 会绕过它。早前的末地迁移用了 JSON override，属权宜手段，本次不沿用。
2. **`beloong:disaster/*` 内容用裸群系 ID，不用 `#biomeswevegone:` 引用**（用户决定）：便于后续人工审核与管理，代价是失去随 BWG 自动同步的能力。
3. **`beloong:disaster/*` 用 `replace: false`**（用户纠正）：自制全新标签没有上游写入内容，`false` 语义正确。
4. **自制群系置于 `values` 数组最上方**（用户要求）：显式区分来源。
5. **地下结构用总账 `#beloong:is_disaster`，取消 `is_cave` 主题**（用户决定）：地下结构需要宽群系覆盖，靠 `start_height` 保证垂直位置。
6. **多主题靠「一个 `has_structure` 标签装多个主题引用」表达**，不新建合并标签（用户确认）。
7. **主题轴完全对应 NeoForge `c:` 约定标签**（用户决定）：`beloong:disaster/<c:主题>`。
8. **完备优先**：允许群系同属多主题；零消费者主题标签保留不删（用户决定）。
9. **`is_hill` 保留**（用户决定）：尽管只有 1 个群系（`beloong:windswept`）。
10. **`kisegi_sanctuary` 归地面组**（用户纠正）：它用 `WORLD_SURFACE_WG` 投影到地表下 32 格，不是地下结构。
11. **地下结构 4 个**（用户纠正）：`foundry`/`mining_complex`/`plague_asylum`/`infested_temple`。
12. **`mining_system` 已删除，标签保持空白**（用户决定）：后续需要时再启用。
13. ~~**`giant_mushroom` 落 `is_plains` 可接受**~~：**已作废** —— 该结构已从模组结构集中删除，不纳入本次迁移。
14. **地面组 `spacing 32 / separation 16`**（用户决定）。
15. **`beloong:disaster_set` 是空中/悬浮结构集，极其重要，不动**（用户纠正；见下节复盘）。
16. **新地面组与空中 `disaster_set` 不设互斥**（用户决定）。
17. **两个原结构集覆盖的 38 个结构从天灾以外全部撤出**（用户确认）：清空后它们只在天灾维度生成（其中 5 个末地结构因结构 JSON override 仍留在末地）。

---

## 五、复盘：两个被纠正的方法论错误

### 5.1 把「零引用」当成「死文件」

**错误陈述**：我曾判断 `kubejs/data/beloong/worldgen/structure_set/disaster_set.json` 是"死文件"，并建议删除。理由是 `grep 'beloong:disaster_set'` 全库零命中。

**错在哪里**：

> **结构集（structure_set）不是"被引用"的对象，它就是生成单元本身。**
> `ChunkGenerator.createState` 把注册表里**全部** structure set 交给每个维度，再用「结构的群系标签 ∩ 该维度 `possibleBiomes()`」筛一道。
> **任何结构集都不会被文件名引用——所以这个 grep 判据对每一个结构集都会得出"死文件"的结论**，包括 `dreadland_set`、`the_end_set`、`the_nether_set`。

**实际真相**（实测印证）：`disaster_set` 的 46 个成员中，mss（Moogs **Soaring** Structures）的 35 个结构 `start_height` 全部为 `uniform` 且 `max_inclusive` 达 Y=100~200 —— 它是天灾维度的**空中结构集**，与 `the_end_set_air` 完全同构。用户给新集命名 `disaster_set_ground` / `disaster_set_underground`，正是相对于这个既有空中集的三件套。

**可带走的规则**：
> **判断一个数据驱动对象是否"死亡"，不能用"谁引用了它"来判断。** 对注册表驱动的对象（structure_set、biome、configured_feature…），只要它在注册表里且其筛选条件可满足，它就是活的。要判断"是否生效"，必须看**消费链路**（对本例：`createState` → `hasBiomesForStructureSet` → `possibleBiomes()` 求交），而不是引用计数。

### 5.2 幻觉结构项 `small_prairie_house`，以及"用错误的和校验错误的和"

**错误陈述**：设计过程中我的地面组名单、权重表、文件计数里始终包含一个 `small_prairie_house`。

**真相**：本版 DA（`DungeonsArise-1.21.1-2.1.68`）的 `worldgen/structure/` 下有 **40 个结构 JSON，其中没有 `small_prairie_house`**。它只有两个残留文件：`tags/worldgen/biome/has_structure/small_prairie_house_biomes.json`（群系标签）与 `advancement/` 里的两处字符串命中。**它是我从讨论中途的某个列表里误采的项，随后自我强化地传播到了所有下游清单。**

**它为什么难被发现**（这才是要点）：

1. 我为它"合理化"了一个权重（先 1 后 3），让它看起来像真实成员；
2. 成员数与权重表**同时含它**，于是两者**互相校验通过**——我用"和等于 34"去验证一份含幻觉项的名单，而 34 这个目标本身就是错的；
3. 真正确认它不存在，靠的是**回源**：`Get-ChildItem worldgen/structure/*.json` 的实际文件枚举 + `Test-Path` 逐个存在性检查。

**可带走的规则**：
> **清单类事实必须从源数据枚举生成，禁止在对话中手工转录。** 任何"我复述一遍清单"的动作都会引入不可见的幻觉项，而幻觉项一旦进入两处以上就会被交叉校验"洗白"。
> **校验数字的闭合，不能替代校验清单的来源。**（`30 + 4 = 34` 闭合，但 `small_prairie_house` 与 `mining_system` 一进一出，和依然闭合。）

**实施硬约束（已写入执行计划要求）**：31 个主题标签、33 个结构标签、2 个结构集的所有成员，**必须由脚本从源目录/jar 枚举生成**，不得手写。

---

## 六、Non-Goals

- **不剔除原版/其他模组结构**：那是前一轮讨论的独立议题（BWG 污染 `minecraft:has_structure/*` 的 17 个标签），本设计**不涉及**。
- **不改 `beloong:is_desert` / `is_sea` / `is_snowy` 等既有主题标签**：它们已被 `cataclysm:koboleton_spawn` / `deeplings_spawn` 消费，与本设计形成两套并存的主题轴；统一问题留待后续（用户明确"先不管已有的 `is_*` 标签"）。
- **不重建 `beloong:is_disaster` 的 BWG 部分**：实测已完整（55/55 对齐），只追加 5 个自制群系。
- **不给 5 个末地结构做任何改动**。
- **不处理 `beloong:caves` 无结构**的问题：其 3 个参数点不会有 DA 结构，这是决策 5 的已知代价。
- **不引入 `lithostitched` 的 `set_structure_spawn_condition`**：实测 1.21.1 版没有维度限定能力，本设计不需要它。

---

## 七、Next Steps

Invoke `planning` skill to create implementation plan at
`docs/plans/2026-09-21-dungeons-arise-disaster-migration.md`.

执行计划必须包含：
1. 用**脚本**从 BWG jar + 化龙核心 jar 生成 31 个主题标签的完整裸 ID 清单（禁止手写）
2. 用**脚本**从 DA jar 生成 33 个 `has_structure/*` 覆盖内容
3. 用**脚本**生成两套结构集 JSON 并核对成员数/权重闭合
4. 明确的运行期验证步骤（`/locate structure` 逐项验证 + 主世界不再生成 DA 结构）
5. 文档同步：`.claude/memory/decisions-log.md`、`learned-patterns.md`

---

## 八、实施后修订（2026-09-21）

### 8.1 主题标签由 31 个收敛为 13 个

**变更**：删除 18 个「零引用」主题标签，`beloong:disaster/` 目录由 31 个文件（含 9 个子文件夹）收敛为 **13 个扁平文件**。

**删除清单**（全部经全令牌匹配确认为零引用，扫描 758 个数据文件）：
```
is_cold/overworld  is_hot/overworld  is_temperate/overworld
is_wet/overworld   is_dry/overworld
is_dense_vegetation/overworld  is_sparse_vegetation/overworld
is_mountain/peak   is_mountain/slope  is_tree/coniferous
is_dead  is_floral  is_icy  is_magical  is_river  is_sandy  is_savanna  is_wasteland
```

**保留 13 个**（每个都被至少一个结构引用）：
`is_forest`、`is_plains`、`is_taiga`、`is_hill`、`is_snowy`、`is_ocean`、`is_beach`、`is_desert`、`is_badlands`、`is_mountain`、`is_windswept`、`is_jungle`、`is_swamp`

**子文件夹为何存在**：这 10 个子文件夹内文件是照搬 BWG `c:` 标签层级的结果（`c:is_hot/overworld`、`c:is_mountain/peak`、`c:is_tree/coniferous`），它们**恰好全部落在零引用名单内**，因此删除后目录自然变为纯扁平。

**已知后果（已接受）**：`beloong:river` 失去唯一的主题标签 `is_river`，此后与 `beloong:caves` 一样仅由总账 `is_disaster` 覆盖。**对当前 33 个结构零影响**（它们全部走总账或已保留的主题）。

**此修订覆盖 §2.2 的标签清单与决策 8「零消费者主题标签保留不删」。**

### 8.2 实施期发现并修复的两个脚本缺陷

1. **`gen-is-disaster.ps1` 不幂等**：原假设 `is_disaster` 内 0 个自制群系，第二次运行必失败。已改为先剥离已有自制群系再重新置顶插入，连续两次 `-Apply` 均通过。
2. **迁移工具目录时误删文件**：`Move-Item -LiteralPath tools\* ...` 因 `-LiteralPath` 不支持通配符而失败，紧随的 `Remove-Item -Recurse -Force` 照常执行，导致全部脚本被永久删除。已全部重建到 `docs/tools/`（用户约定位置）。

### 8.3 工具脚本位置约定

辅助脚本统一放 **`docs/tools/`**（不放实例根的 `tools/`）：
- 生成器 `docs/tools/gen-*.ps1`
- 校验器 `docs/tools/verify-*.ps1`
- 清理器 `docs/tools/prune-disaster-tags.ps1`
- 产物 `docs/tools/out/`

脚本用 `$PSScriptRoot` 反推实例根目录，移动后仍可用。

---

## 九、根因结论与修复（2026-09-21 追加）

### 9.1 问题现象

玩家**新建存档后首次进入天灾维度**时，服务器主线程永久卡死，无崩溃报告。旧存档（目标区块已存在）不复现。

### 9.2 根因：结构集双向互斥导致 worker 线程 StackOverflowError

**证据**：`logs/debug-2.log.gz:71749`，`Worker-Main-17` 线程：

```
java.lang.StackOverflowError: null
  at RandomSpreadStructurePlacement.isPlacementChunk(...)
  at StructurePlacement.isStructureChunk(StructurePlacement.java:87)
  at ChunkGeneratorStructureState.hasStructureChunkInRange(ChunkGeneratorStructureState.java:198)
  at StructurePlacement$ExclusionZone.isPlacementForbidden(StructurePlacement.java:144)
  at StructurePlacement.applyInteractionsWithOtherStructures(StructurePlacement.java:93)
  at StructurePlacement.isStructureChunk(StructurePlacement.java:89)
  ... （同一四步循环重复）
```

帧计数：`hasStructureChunkInRange` 与 `isStructureChunk` 各 **255~256** 次，`StructurePlacement` 共 **1537** 帧 → **255 层递归**。

**机制**：原版 `StructurePlacement` 的排除区检查链**没有任何环路防护**（无 visited 集合、无深度上限、无"不可回指"校验）：

```
isStructureChunk(:89)                                  // StructurePlacement.java
  → applyInteractionsWithOtherStructures(:93)
  → ExclusionZone.isPlacementForbidden(:144)
  → ChunkGeneratorStructureState.hasStructureChunkInRange(:198)   // 遍历 (2*chunk_count+1)^2 个区块
  → isStructureChunk(:89)                              // 回到起点
```

本迁移建立的 `disaster_set_ground` 与 `disaster_set_underground` **双向互指**（各 `chunk_count=10`，即每次展开 441 个候选），构成环。全实例 **21 处 `other_set` 中，只有这一对是双向的**；其余（原版 `minecraft:end_cities`/`nether_complexes`/`villages`、灾变 `#cataclysm:*_avoid` 等）全部单向，故不成环。

**结果**：worker 线程爆栈 → `Caught exception in thread ... Worker-Main-17` → 该区块的生成 future **永不完成**。

### 9.3 与 portal 缺陷的叠加关系

```
① worker 生成天灾区块 → 排除区互递归 → StackOverflowError → 区块 future 永不完成
② 玩家走天灾传送门（新存档，落点区块不存在）
   → DisasterPortalBlock.entityInside:136 → targetLevel.getChunk(FULL)
   → ServerChunkCache.getChunk:159 → MainThreadExecutor.managedBlock → 主线程永久停转
```

**两个缺陷都真实、都需修复**：
- 缺陷①（本迁移数据引入）：worker 爆栈，区块生成失败、结构不生成
- 缺陷②（化龙核心既有）：把"区块生成失败"放大为"整个游戏卡死"

**旧存档为何不卡**：落点区块早已生成，`getChunk` 命中 4 槽 LRU 缓存（`ServerChunkCache.getChunk:144-151`）直接返回，绕过了缺陷②；故缺陷①即使发生也无人察觉。

### 9.4 修复

**移除两个结构集的 `exclusion_zone`**（天灾维度的结构已设计为互不重叠，无需互斥）。

- `disaster_ground_set` 与 `disaster_underground_set` 的 `placement` 现仅含 `type`/`spacing`/`separation`/`salt`
- 成员数、间距、权重分布**全部未变**（地面 29 = `1:16 2:13`；地下 4 = `1:4`）
  - 注：此处原记为 `1:7 2:12 3:10` / `2:4`，是权重归一之前的旧值，已按实际取值更正
  - 注：**salt 在本节修复之后另行调整过**（2026-09-21，用户有意设定），现值为地面 `88371664`、地下 `342415936`，见 §7 参数表
- **覆盖 §2.7 的互斥设计与决策 16「新地面组与空中集不设互斥」的相邻条款**

**连带修改**（防止 bug 复活）：
1. `docs/tools/gen-da-structure-sets.ps1` — 停止输出 `exclusion_zone`；新增**无环回归断言**（扫描全整合包 21 处 `other_set`，发现任何双向互斥即失败）
2. `docs/tools/verify-disaster-migration.ps1` — 断言改为"不得声明 `exclusion_zone`"，并加入同一无环检测
   - ⚠️ 该脚本已于 2026-09-13 删除（见 §12.3）；「不得声明 `exclusion_zone`」现在只能靠人工核对

### 9.5 教训

1. **原版 `exclusion_zone` 不支持双向（互指）**。若要互斥，**只能单向**，且需评估递归展开代价（`chunk_count` 的平方）。
2. **天灾维度本就设计了结构不重叠**，添加互斥是多余且危险的——"零收益 + 高风险"的组合。
3. **worker 线程异常不会出现在主线程转储里**。本次主线程转储只暴露了缺陷②（portal 阻塞），缺陷①只存在于 `debug.log` 的 `Worker-Main-*` 行。**排查卡死必须同时搜 worker 线程异常**。
4. **新存档是这类缺陷的唯一有效验收环境**；旧存档会因区块缓存而假通过。

---

## 十、附属扩展：海洋扩展（Seven Seas）迁移（2026-09-21 追加）

### 10.1 背景

`dungeons_arise_seven_seas`（DungeonsAriseSevenSeas-1.21.x-1.0.4-neoforge）是地牢浮现之时的**附属模组**，共 **5 个结构，全部是船**。命名空间 `dungeons_arise_seven_seas`（独立于主模组的 `dungeons_arise`）。

| 船 | 模板数 | 体积 |
|---|---|---|
| `victory_frigate` | 12 | 123 KB |
| `pirate_junk` | 7 | 41 KB |
| `unicorn_galleon` | 7 | 37 KB |
| `corsair_corvette` | 6 | 29 KB |
| `small_yacht` | 4 | 13 KB |

### 10.2 迁移方式（沿用主模组范式）

| 项 | 值 | 说明 |
|---|---|---|
| 目标群系标签 | **`#beloong:disaster/is_ocean`** | **单一引用**——5 个船的源标签内容完全相同，故无需多主题 |
| 新结构集 | **`beloong:disaster_set_sea`** | 与 `disaster_set` / `_ground` / `_underground` 组成**四件套** |
| `spacing` / `separation` | **40 / 34** | 原扩展为 68/60，但那是针对主世界全部海洋设计；天灾仅有 4 个海洋群系，68/60 会过于罕见 |
| `salt` | **98123789** | 沿用原值；该值与已清空的 `dungeons_arise_seven_seas:minor_structures` 相同，但后者 `structures: []`、不产生任何候选点，故不构成实际冲突 |
| 权重 | **5 条船全部 = 1** | 同原扩展 |
| `exclusion_zone` | **不加** | 天灾维度结构已设计为互不重叠（见第九章教训） |
| 原结构集 | **清空** `dungeons_arise_seven_seas:minor_structures` | 保留原 placement（68/60/98123789）仅清空成员 |

### 10.3 关键取证

1. **5 个船的源标签内容完全一致**：`{"replace": false, "values": ["#minecraft:is_ocean"]}` → 一次批量覆盖即可
2. **全实例只有扩展自身引用这 5 条船**（无其他结构集、无 kubejs/paxi 引用）→ 清空原集 = **真正彻底清空**
3. **迁移前它们已经在天灾维度漏生**：`#minecraft:is_ocean` 被 BWG 追加了 `#biomeswevegone:ocean`（`dead_sea` + `lush_stacks`），而这两者在天灾维度内。故本任务实质是**收编 + 独占**，非新增
4. **5 个船均为** `step: surface_structures` + `project_start_to_heightmap: WORLD_SURFACE_WG` + 负 `start_height`（-4~0）

### 10.4 已知取舍（用户已确认）

- **`beloong:frozen_ocean` 会结冰**（温度 0.0 + `temperature_modifier: frozen`），船会嵌入冰盖 —— **接受**为特色
- 未使用 `beloong:is_sea`（该标签含 3 个陆地海岸群系 `basalt_barrera`/`dacite_shore`/`rainbow_beach`，船会搁浅；且不含自制海洋 `beloong:ocean`/`frozen_ocean`）
- 未使用 `disaster/is_beach`（船不应靠岸）
- **（2026-09-21 追加）** sea 集现已带原点禁区 `min_distance_from_world_origin: 250`，由用户**手工**加入，不在生成器/校验器覆盖内 —— 见 §12

### 10.5 改动清单（7 个数据文件）

| 路径 | 数量 | 动作 |
|---|---|---|
| `kubejs/data/dungeons_arise_seven_seas/tags/worldgen/biome/has_structure/*_biomes.json` | 5 | 新建，`replace:true` → `#beloong:disaster/is_ocean` |
| `kubejs/data/beloong/worldgen/structure_set/disaster_set_sea.json` | 1 | 新建（5 成员 / weight 1 / 40-34-98123789 / 无 exclusion） |
| `kubejs/data/dungeons_arise_seven_seas/worldgen/structure_set/minor_structures.json` | 1 | 覆盖 → `structures: []` |

工具：`docs/tools/gen-sevenseas-migration.ps1`（含 6 步断言与无双向互斥回归检测）

### 10.6 验收

静态校验 15 项全通过。实机需用**新存档**验证（见实施脚本输出）。

---

## 十二、维护边界：自动脚本 vs 手工维护（2026-09-21 用户确认）

**用户指示：** 小需求直接手写，不要为每件事都拉生成器。据此划定以下边界。

### 12.1 四个天灾结构集的现状与归属

| 结构集 | 成员 | placement | 维护方式 |
|---|---|---|---|
| `beloong:disaster_ground_set` | 35 | `moogs_structures:advanced_random_spread` / 32-16 / salt `88371664` / `min_distance_from_world_origin` 250 | **手工维护**（成员已含 6 个灾变小结构）；`gen-da-structure-sets.ps1` 仍可重建其中 DA 的 29 项，但会覆盖手工追加的成员，**不要再跑** |
| `beloong:disaster_underground_set` | 5 | `minecraft:random_spread` / 32-16 / salt `342415936` | **手工维护**（含 `cataclysm:amethyst_nest` 权重 4）；同上 |
| `beloong:disaster_sea_set` | 5 | `moogs_structures:advanced_random_spread` / 40-34 / salt `98123789` / `min_distance_from_world_origin` 250 | **手工维护** |
| `beloong:disaster_sky_set` | 46 | `moogs_structures:advanced_random_spread` / 20-10 / salt `20260604` / `min_distance_from_world_origin` 250 | **手工维护** |

**四个集合现已统一带 `min_distance_from_world_origin: 250`**（原点 250 方块禁区，单位方块，判定为圆；`disaster_underground_set` 除外，它是原版 `random_spread`，无此字段）。

**⚠️ `verify-disaster-migration.ps1` 已于 2026-09-13 由用户决定删除**（灾变小结构并入后其写死的 DA 口径既漏报又误报）。四个集合自此**全部为手工维护**，无自动校验。

### 12.2 手工维护的两个集合

`disaster_sea_set` 与 `disaster_sky_set` **从一开始就不在任何生成器或校验器的覆盖范围内**——这是**有意选择**，不是遗漏：

- 两者的成员分别来自七海扩展 jar（5 条船）与 mss（46 个空中结构），各有独立的迁移脚本（`gen-sevenseas-migration.ps1`）或纯手工来源；
- 为其新增"枚举 + 生成 + 校验"的工具链，成本高于收益；
- 它们的 placement 已手写为与 ground 集一致的原点禁区写法。

**2026-09-13 更新：`disaster_ground_set` 与 `disaster_underground_set` 也已转为手工维护**——灾变小结构并入后不再有能安全重建它们的脚本（详见 12.3）。至此**四个集合全部手工维护**。

**由此产生的已知风险（接受）：**

1. 若任一集合的 placement 被改回 `minecraft:random_spread` 或删掉 `min_distance_from_world_origin`，**没有任何脚本会报警**，禁区会静默消失（原版会保留未知键但不使用）。
2. 覆盖它们的模组（mss / 七海 / 灾变）若更新并改变结构集或结构 JSON 内容，不会自动反映。

**变更这些集合时请手工核对：**
- `type` 必须是 `moogs_structures:advanced_random_spread`（该 placement 类型由 MoogsStructureLib 提供，原版不存在；`disaster_underground_set` 例外，它是原版类型且无禁区字段）；
- `min_distance_from_world_origin` 必须存在且为方块数（250 = 15.6 区块）；
- salt 不得与全实例既有值冲突——各集合的 `spacing/separation` 互异，故冲突风险低，但若将来新增集合，需重新核对全实例 salt 表。

### 12.3 工具链的边界（勿误以为覆盖全量）

`docs/tools/` 下的脚本**只覆盖它明确列出的目标**，不是"天灾维度的全量校验"：

- `gen-da-structure-sets.ps1` → 只写 `disaster_ground_set.json` 与 `disaster_underground_set.json`，且**只写 DA 的 29 + 4 个成员**。这两个文件现在分别有 35 和 5 个成员（各含灾变结构），**再跑一次 `-Apply` 会把手工追加的灾变成员整段覆盖掉**——该脚本已事实上停用；
- `gen-sevenseas-migration.ps1` → 七海 5 条船的标签与集合（其生成的结构集即 `disaster_sea_set`，但脚本内不校验原点禁区字段）；
- `verify-disaster-migration.ps1` → **已于 2026-09-13 删除**（用户决定）。它写死了 DA 的 29/4/33 成员数与 `1:16 2:13` 权重分布，灾变小结构并入后既漏报（w3 那 3 个 DA 结构的预期本就过时）又误报（把合法的 `cataclysm:*` 成员判为"不在 DA jar 中"）。

**因此：现在没有任何脚本能校验四个天灾结构集。** 改动它们之后只能靠人工核对或实机 `/locate` 验证。这句话是本节的要点。
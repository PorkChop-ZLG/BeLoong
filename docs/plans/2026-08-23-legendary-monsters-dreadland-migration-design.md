# Legendary Monsters 迁移至悚域维度设计文档

**Date:** 2026-08-23
**Status:** Approved
**Approach:** 方案 B——灾变式集中 structure_set（dreadland_set）

## Problem Statement

将模组“传奇怪物”（Legendary Monsters）的结构与现有自然生成生物迁移到“冰火传说：悚域”（Ice And Fire: Dread Land）的悚域维度 `iceandfire_dreadland:dreadland`，并使其不再在主世界/末地/下界生成。要求使用纯数据包方式实现，参考整合包对灾变（Cataclysm）的结构迁移魔改。

## Design

### Architecture

- 新建集中结构集合 `beloong:dreadland_set`，统一控制悚域内所有 Legendary Monsters 结构。
- 清空原 `legendary_monsters/worldgen/structure_set/*.json` 的 `structures`，防止原维度继续生成。
- 覆盖 Legendary Monsters 的 `has_structure/*_biomes` 标签，按结构主题指向悚域群系标签。
- 覆盖特殊结构 JSON（下界/末地风格结构），调整 Y 轴/方块条件以适配悚域。
- 覆盖自然生成 biome modifier（chorusling、bomber、skeletosaurus），使其只在悚域对应群系生成。

### Components

1. `kubejs/data/beloong/worldgen/structure_set/dreadland_set.json`
2. `kubejs/data/legendary_monsters/worldgen/structure_set/*.json`（清空 structures）
3. `kubejs/data/legendary_monsters/tags/worldgen/biome/has_structure/*.json`（指向悚域标签）
4. `kubejs/data/legendary_monsters/worldgen/structure/*.json`（特殊结构适配）
5. `kubejs/data/legendary_monsters/neoforge/biome_modifier/chorusling.json`
6. `kubejs/data/legendary_monsters/forge/biome_modifier/bomber.json`
7. `kubejs/data/legendary_monsters/forge/biome_modifier/skeletosaurus.json`
8. 可选：`neoforge/biome_modifier/bomber.json`、`skeletosaurus.json`

### Biome Mapping

| 结构/生物 | 原环境 | 悚域标签 |
|---|---|---|
| ancient_stronghold | 主世界森林 | `#iceandfire_dreadland:is_dread` |
| ancient_tower_remains | 末地 | `#iceandfire_dreadland:is_lightning` |
| cloudy_temple | 主世界山地 | `#iceandfire_dreadland:is_iceland` |
| collapsed_kingdom | 主世界森林/平原 | `#iceandfire_dreadland:is_dread` |
| frostbitten_temple | 主世界雪原 | `#iceandfire_dreadland:is_iceland` |
| lava_eater_spawn | 下界 | `#iceandfire_dreadland:is_fireland` |
| mossy_temple | 主世界丛林 | `#iceandfire_dreadland:is_dreadland_forest` |
| ruined_pyramid | 主世界沙漠 | `#iceandfire_dreadland:is_fireland` |
| shulker_tower | 末地 | `#iceandfire_dreadland:is_lightning` |
| skeletosaurus_nest | 下界 | `#iceandfire_dreadland:is_fireland` |
| soul_fortress_remains | 下界 | `#iceandfire_dreadland:is_fireland` |
| space_station | 末地 | `#iceandfire_dreadland:is_lightning` |
| warped_fungussus_nest | 下界 | `#iceandfire_dreadland:is_fireland` |
| 自然生成 chorusling | 末地 | `#iceandfire_dreadland:is_lightning` |
| 自然生成 bomber | 主世界沙漠 | `#iceandfire_dreadland:is_fireland` |
| 自然生成 skeletosaurus | 下界 | `#iceandfire_dreadland:is_fireland` |

### Special Structure Adjustments

- `lava_eater_spawn.json`：群系改 `is_fireland`；`start_height` 改为地表；移除下界方块条件。
- `skeletosaurus_nest.json`：群系改 `is_fireland`；`start_height` 改为地表；移除下界方块条件。
- `soul_fortress_remains.json`：群系改 `is_fireland`；`start_height` 改为地表；移除下界方块条件。
- `warped_fungussus_nest.json`：群系改 `is_fireland`；`start_height` 改为地表；移除下界 `height`/`predicate`。
- `space_station.json`：群系改 `is_lightning`；`start_height` 建议 120–180 高空。

### Data Flow

悚域世界生成 → 读取 `beloong:dreadland_set` → random_spread 选择 LM 结构 → 检查结构 `biomes` 对应的悚域群系标签 → 通过结构 `start_height`/地形适配 → 生成结构。

自然生成：biome modifier 只在对应悚域群系标签下注册刷怪。

### Error Handling

- JSON 覆盖文件保留原结构，只改必要字段。
- 确认悚域标签存在。
- 下界结构 Y 轴必须改为悚域地表，避免低于 min_y=-64。
- space_station 高度需实测调整。
- 同时补 `neoforge` 版本 biome modifier，避免 `forge` 目录不被 NeoForge 加载。
- 若结构重叠明显，后续给 `dreadland_set` 增加 `exclusion_zone`。

### Testing Strategy

1. 静态检查 JSON 合法、路径正确、标签存在。
2. 悚域内 `/locate structure legendary_monsters:<structure>` 逐个验证。
3. 主世界/末地/下界 `/locate` 应找不到 LM 结构。
4. 悚域雷域验证 chorusling；火域验证 bomber、skeletosaurus。
5. 检查 `latest.log` 的 datapack error。

## Decisions Made

- 使用方案 B（集中 structure_set），与整合包灾变迁移手法对齐。
- 集合命名为 `dreadland_set`，与 `disaster_set` 对齐。
- `dreadland_set` 只包含 Legendary Monsters 结构。
- 末地原生的结构统一放 `is_lightning`。
- 下界原生的结构统一放 `is_fireland`。
- 其余结构按主题分配至 `is_dread` / `is_iceland` / `is_dreadland_forest`。

## Non-Goals

- 不迁移悚域教堂或冰火龙巢/洞穴到 `dreadland_set`。
- 不修改宠物/召唤物（mossy_golem、skeloraptor、guard、knights_armor、the_obliterator 等）的生成方式。
- 不修改 Legendary Monsters 的配方、物品、战利品表。

## Next Steps

调用 planning skill 创建详细实施计划。

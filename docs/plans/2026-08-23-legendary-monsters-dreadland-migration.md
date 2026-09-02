# Legendary Monsters 迁移至悚域维度实施计划

**Goal:** 使用纯数据包将传奇怪物（Legendary Monsters）结构与现有自然生成生物迁移到悚域维度，并停止在原维度生成。
**Architecture:** 新建 `beloong:dreadland_set` 集中管理 LM 结构；清空原 LM structure_set；覆盖 biome 标签/特殊结构 JSON/biome modifier。
**Approach:** 方案 B（灾变式集中 structure_set），已由用户在设计阶段确认。

---

### Task 1: 创建集中 structure_set

**Files:**
- Create: `kubejs/data/beloong/worldgen/structure_set/dreadland_set.json`

**Steps:**
1. 写入包含全部 13 个有效 LM 结构的 `dreadland_set.json`。
2. 使用 `minecraft:random_spread`，初始 `spacing: 40`、`separation: 25`、`salt: 20260823`。
3. 每个结构权重先设为 `1`。

**Verification:**
- JSON 可解析。
- 启动游戏无 datapack error。

---

### Task 2: 清空原 LM structure_set

**Files:**
- Modify（覆盖）以下文件，全部设为 `"structures": []`，保留原 placement：
  - `kubejs/data/legendary_monsters/worldgen/structure_set/ancient_stronghold.json`
  - `kubejs/data/legendary_monsters/worldgen/structure_set/ancient_tower_remains.json`
  - `kubejs/data/legendary_monsters/worldgen/structure_set/cloudy_temple.json`
  - `kubejs/data/legendary_monsters/worldgen/structure_set/collapsed_kingdom.json`
  - `kubejs/data/legendary_monsters/worldgen/structure_set/frostbitten_temple.json`
  - `kubejs/data/legendary_monsters/worldgen/structure_set/lava_eater_spawn.json`
  - `kubejs/data/legendary_monsters/worldgen/structure_set/mossy_temple.json`
  - `kubejs/data/legendary_monsters/worldgen/structure_set/ruined_pyramid.json`
  - `kubejs/data/legendary_monsters/worldgen/structure_set/shulker_tower.json`
  - `kubejs/data/legendary_monsters/worldgen/structure_set/skeletosaurus_nest.json`
  - `kubejs/data/legendary_monsters/worldgen/structure_set/soul_fortress_remains.json`
  - `kubejs/data/legendary_monsters/worldgen/structure_set/space_station.json`
  - `kubejs/data/legendary_monsters/worldgen/structure_set/warped_fungussus_nest.json`

**Steps:**
1. 对每个文件创建覆盖，保留原 `placement`，将 `structures` 改为空数组。
2. 不处理无 `.json` 扩展名的 `altar_platform`/`frostbittentempleoriginal`/`mossytempleoriginal`/`soulfortressoriginal`，因为 Minecraft 不会加载它们。

**Verification:**
- 游戏启动无结构集错误。
- 主世界/末地/下界 `/locate structure legendary_monsters:<structure>` 找不到结构。

---

### Task 3: 覆盖结构群系标签

**Files:**
- Modify（覆盖）以下文件，每个内容为 `{ "replace": true, "values": ["<对应悚域标签>"] }`：
  - `kubejs/data/legendary_monsters/tags/worldgen/biome/has_structure/ancient_stronghold_biomes.json` → `#iceandfire_dreadland:is_dread`
  - `.../ancient_tower_remains_biomes.json` → `#iceandfire_dreadland:is_lightning`
  - `.../cloudy_temple_biomes.json` → `#iceandfire_dreadland:is_iceland`
  - `.../collapsed_kingdom_biomes.json` → `#iceandfire_dreadland:is_dread`
  - `.../frostbitten_temple_biomes.json` → `#iceandfire_dreadland:is_iceland`
  - `.../lava_eater_spawn_biomes.json` → `#iceandfire_dreadland:is_fireland`
  - `.../mossy_temple_biomes.json` → `#iceandfire_dreadland:is_dreadland_forest`
  - `.../ruined_pyramid_biomes.json` → `#iceandfire_dreadland:is_fireland`
  - `.../shulker_tower_biomes.json` → `#iceandfire_dreadland:is_lightning`
  - `.../skeletosaurus_nest_biomes.json` → `#iceandfire_dreadland:is_fireland`
  - `.../soul_fortress_remains_biomes.json` → `#iceandfire_dreadland:is_fireland`
  - `.../space_station_biomes.json` → `#iceandfire_dreadland:is_lightning`
  - `.../abandoned_crypt_biomes.json` → `#iceandfire_dreadland:is_dread`（保留覆盖，未使用也无害）

**Steps:**
1. 为每个标签文件写入对应值。
2. 确保 `replace: true`，移除原群系列表。

**Verification:**
- JSON 可解析。
- 悚域内 `/locate structure` 能找到对应结构。

---

### Task 4: 覆盖特殊结构 JSON

**Files:**
- Modify：
  - `kubejs/data/legendary_monsters/worldgen/structure/lava_eater_spawn.json`
  - `kubejs/data/legendary_monsters/worldgen/structure/skeletosaurus_nest.json`
  - `kubejs/data/legendary_monsters/worldgen/structure/soul_fortress_remains.json`
  - `kubejs/data/legendary_monsters/worldgen/structure/warped_fungussus_nest.json`
  - `kubejs/data/legendary_monsters/worldgen/structure/space_station.json`

**Steps:**
1. `lava_eater_spawn.json`：`biomes` 改为 `#iceandfire_dreadland:is_fireland`；`start_height` 改为地表（`absolute: 0` + `project_start_to_heightmap: WORLD_SURFACE_WG`）；移除下界方块条件。
2. `skeletosaurus_nest.json`：同上，群系 `is_fireland`；移除 soul_soil/soul_sand 条件。
3. `soul_fortress_remains.json`：同上，群系 `is_fireland`。
4. `warped_fungussus_nest.json`：`biomes` 改为 `#iceandfire_dreadland:is_fireland`；`start_height` 改为地表；移除 `height`/`predicate`。
5. `space_station.json`：`biomes` 改为 `#iceandfire_dreadland:is_lightning`；`start_height` 改为 `uniform 120–180`。

**Verification:**
- 悚域对应群系中 `/locate structure legendary_monsters:<structure>` 可找到。
- 手动传送到生成点确认没有卡在地下或过高。

---

### Task 5: 覆盖自然生成 biome modifier

**Files:**
- Modify：
  - `kubejs/data/legendary_monsters/neoforge/biome_modifier/chorusling.json`
  - `kubejs/data/legendary_monsters/forge/biome_modifier/bomber.json`
  - `kubejs/data/legendary_monsters/forge/biome_modifier/skeletosaurus.json`
- Create（兼容 NeoForge）：
  - `kubejs/data/legendary_monsters/neoforge/biome_modifier/bomber.json`
  - `kubejs/data/legendary_monsters/neoforge/biome_modifier/skeletosaurus.json`

**Steps:**
1. `chorusling` 的 `biomes` 改为 `#iceandfire_dreadland:is_lightning`。
2. `bomber` 的 `biomes` 改为 `#iceandfire_dreadland:is_fireland`。
3. `skeletosaurus` 的 `biomes` 改为 `#iceandfire_dreadland:is_fireland`。
4. 为 `bomber` 和 `skeletosaurus` 补 `neoforge` 版本，避免 `forge` 目录在 NeoForge 下不生效。

**Verification:**
- 悚域雷域可自然生成 chorusling。
- 悚域火域可自然生成 bomber、skeletosaurus。
- 原末地/沙漠/灵魂沙峡谷不再自然生成这三种生物。

---

### Task 6: 验证与调参

**Files:**
- 可能 Modify：`kubejs/data/beloong/worldgen/structure_set/dreadland_set.json`

**Steps:**
1. 启动游戏，检查 `latest.log` 无 datapack error。
2. 进入悚域，逐个 `/locate structure legendary_monsters:<structure>` 验证。
3. 在主世界/末地/下界执行 `/locate` 确认找不到。
4. 检查自然生成是否按预期。
5. 若结构过密/过稀或重叠，调整 `dreadland_set` 的 `spacing`/`separation` 或为特定结构降权。

**Verification:**
- 所有验证命令通过。
- 用户确认悚域体验符合预期。

---

## 非目标
- 不迁移悚域教堂或冰火龙巢/洞穴到 `dreadland_set`。
- 不修改宠物/召唤物（mossy_golem、skeloraptor、guard、knights_armor、the_obliterator）生成。
- 不修改配方、物品、战利品表。

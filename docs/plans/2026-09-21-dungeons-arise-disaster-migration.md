# 地牢浮现之时 → 天灾维度迁移 实施计划

> **命名更新（2026-09-21，不改写正文）：** 结构集已按「维度_位置_set」重命名，本文正文中的旧 ID 对应关系为 
`disaster_set` → `disaster_sky_set`、`disaster_set_ground` → `disaster_ground_set`、`disaster_set_underground` → `disaster_underground_set`、`disaster_set_sea` → `disaster_sea_set`。
另外：主题标签已由 31 个收敛为 13 个（见 decisions-log）；地面集权重已归一为大型 1 / 小型 2（`1:16 2:13`）；两套结构集的 `exclusion_zone` 已移除（见本目录 §9）。


**Goal:** 把 `dungeons_arise` 的 33 个结构（地面 29 + 地下 4）改为**仅在天灾维度生成**，用 31 个 `beloong:disaster/*` 主题标签精准指定气候归属，并用两套新结构集统一管理。

**Architecture:** 三层标签体系 —— 31 个主题标签（裸群系 ID）← 33 个 `dungeons_arise:has_structure/*` 覆盖（`replace:true`，可多引用）；总账 `beloong:is_disaster` 升级为 60 项，供地下组使用。两套新结构集 `disaster_set_ground`(32/16) 与 `disaster_set_underground`(32/16) 互斥；DA 原两个结构集清空。空中 `beloong:disaster_set` 与 5 个末地结构**完全不动**。

**Approach:** 设计文档第七节选定的「A —— `c:` 型主题命名空间 + 总账 + 两套结构集」。理由：主题轴对齐 NeoForge `c:` 约定标签，气候归属有客观依据且可人工审核；用 `has_structure` 标签而非结构 JSON 的 `biomes`，保留模组抽象边界。

**设计依据:** `docs/plans/2026-09-21-dungeons-arise-disaster-migration-design.md`

**关键硬约束（违反即失败）:**
1. **所有清单必须由脚本从源数据枚举生成**，禁止手写转录（设计文档 §5.2 记录了幻觉项事故）
2. **先建 31 个主题标签，再写 33 个结构标签**（反向会导致标签引用不存在而整包加载失败）
3. **先建两套新结构集，再清空 DA 原结构集**（反向会导致 33 个结构在所有维度消失）
4. 自制群系置于 `values` 数组**顶部**，主题标签用 `replace:false`，结构标签用 `replace:true`
5. 空中 `beloong:disaster_set` / 5 个末地结构 JSON / **3 个已删除结构**（`giant_mushroom`、`mining_system`、`small_prairie_house`）的残留文件 **一律不动**

**数据源（权威枚举来源）:**
- BWG 群系：`mods\[我们走过的生物群系] Oh-The-Biomes-Weve-Gone-NeoForge-2.6.0.jar` → `data/biomeswevegone/worldgen/biome/*.json`
- BWG 标签：`D:\Minecraft\开源模组参考文件\Oh-The-Biomes-Weve-Gone\Common\src\main\generated\resources\data\biomeswevegone\tags\worldgen\biome\`
- DA 结构：`D:\Minecraft\闭源模组解压文件\地牢浮现之时\data\dungeons_arise\worldgen\structure\*.json`
- 化龙核心群系：`mods\beloong-0.9.1.jar` → `data/beloong/worldgen/biome/*.json`

---

## Batch 1：生成器脚本 + 31 个主题标签

### Task 1.1：编写枚举生成器

**Files:**
- Create: `tools/gen-disaster-tags.ps1`

**Steps:**
1. 从 BWG 源目录读取 28 个 `biomeswevegone:` 标签，产出**逐项群系清单**（去掉 `biomeswevegone:` 前缀）
2. 从化龙核心 jar 读取 5 个自制群系 ID 并断言等于 `caves`/`frozen_ocean`/`ocean`/`river`/`windswept`
3. 按设计文档 §2.2 的 31 行映射表产出每个主题标签的 `values` 数组：
   - 自制群系**在前**（仅 `is_windswept`、`is_ocean`、`is_river` 三个含自制项）
   - BWG 群系在后，按字母序
   - 每个文件形如 `{ "replace": false, "values": [ ... ] }`
4. 断言：31 个文件全部产出；每个文件 `values` 非空；所有 ID 均在该群系的全集内
5. 输出一份 `tools/out/disaster-tags-manifest.txt` 供人工核对

**Verification:**
```powershell
pwsh -File tools/gen-disaster-tags.ps1
# 期望：31 个文件生成、0 断言失败、manifest 含 31 行
```

### Task 1.2：落地主题标签

**Files:**
- Modify: `kubejs/data/beloong/tags/worldgen/biome/disaster/**` （22 个已有文件，拍平 + `replace:false`）
- Create: `kubejs/data/beloong/tags/worldgen/biome/disaster/is_forest.json`
- Create: `kubejs/data/beloong/tags/worldgen/biome/disaster/is_taiga.json`
- Create: `kubejs/data/beloong/tags/worldgen/biome/disaster/is_jungle.json`
- Create: `kubejs/data/beloong/tags/worldgen/biome/disaster/is_badlands.json`
- Create: `kubejs/data/beloong/tags/worldgen/biome/disaster/is_savanna.json`
- Create: `kubejs/data/beloong/tags/worldgen/biome/disaster/is_ocean.json`
- Create: `kubejs/data/beloong/tags/worldgen/biome/disaster/is_beach.json`
- Create: `kubejs/data/beloong/tags/worldgen/biome/disaster/is_hill.json`
- Create: `kubejs/data/beloong/tags/worldgen/biome/disaster/is_river.json`

**Steps:**
1. 由 Task 1.1 的脚本直接写出 22+9=31 个文件
2. **不创建 `is_cave.json`**（用户已取消）
3. 逐一确认 `replace` 字段为 `false`、`values` 无任何 `#` 开头的条目

**Verification:**
```powershell
$d="kubejs/data/beloong/tags/worldgen/biome/disaster"
(Get-ChildItem $d -Recurse -File).Count          # 期望 31
Test-Path "$d/is_cave.json"                       # 期望 False
Get-ChildItem $d -Recurse -File | ForEach-Object {
  $j = Get-Content $_.FullName -Raw | ConvertFrom-Json
  if ($j.replace -ne $false) { "replace 不是 false: $($_.Name)" }
  if ($j.values -match '^#') { "含标签引用: $($_.Name)" }
}
# 期望：无任何输出
```

**验证门：** Task 1.2 通过前**不得**开始 Batch 3。

---

## Batch 2：总账升级

### Task 2.1：`beloong:is_disaster` 追加 5 个自制群系

**Files:**
- Modify: `kubejs/data/beloong/tags/worldgen/biome/is_disaster.json`

**Steps:**
1. 保留现有 55 个 `biomeswevegone:*` 条目（**不动、不排序、不删减**，含 `eroded_borealis`）
2. 在 `values` 数组**最上方**插入 5 个自制群系：
   ```
   "beloong:caves",
   "beloong:frozen_ocean",
   "beloong:ocean",
   "beloong:river",
   "beloong:windswept"
   ```
3. 该文件**不加** `replace` 字段（保持现状写法，避免影响 27 个既有消费者）

**Verification:**
```powershell
$f="kubejs/data/beloong/tags/worldgen/biome/is_disaster.json"
$v=(Get-Content $f -Raw | ConvertFrom-Json).values
$v.Count                                            # 期望 60
($v | Where-Object { $_ -like 'beloong:*' }).Count  # 期望 5
($v | Where-Object { $_ -like 'biomeswevegone:*' }).Count  # 期望 55
$v[0..4] -join ','                                  # 期望 5 个 beloong: 且在最前
```

---

## Batch 3：33 个结构标签覆盖

### Task 3.1：编写结构标签生成器

**Files:**
- Create: `tools/gen-da-structure-tags.ps1`

**Steps:**
1. **从实例实际加载的 DA jar 枚举** `data/dungeons_arise/worldgen/structure/*.json` 得到 40 个结构 ID（禁止手写）。**注意：`D:\Minecraft\闭源模组解压文件\地牢浮现之时` 与 jar 不同步，唯一权威来源是 jar**
2. 断言集合运算：40 − 5(末地) − 2(已删除且有 JSON：giant_mushroom/mining_system) − 4(地下) = 29(地面)；small_prairie_house 无结构 JSON，不在 40 之内
3. 断言 3 个已删除结构均**不在两个原结构集的成员里**（`giant_mushroom`/`mining_system`/`small_prairie_house`）
4. 断言 `small_prairie_house` **无结构 JSON**（`Test-Path` 显式检查并记录；它仅有残留群系标签）
5. 按设计文档 §2.5 的映射表产出 33 个 `has_structure/*_biomes.json`：
   - 地面 29 个 → 1~3 个主题引用（`#beloong:disaster/is_*`）
   - 地下 4 个 → `["#beloong:is_disaster"]`
   - 每个文件：`{ "replace": true, "values": [ ... ] }`
6. 断言每个引用的主题标签文件都存在于 Batch 1 的产物中
7. 输出 `tools/out/da-structure-tags-manifest.txt`（结构 ID → 引用的主题）

**Verification:**
```powershell
pwsh -File tools/gen-da-structure-tags.ps1
# 期望：33 个文件生成；40-5-2-4=29 地面断言通过；无引用缺失
```

### Task 3.2：落地结构标签

**Files:**
- Modify: `kubejs/data/dungeons_arise/tags/worldgen/biome/has_structure/*_biomes.json` （33 个）

**Steps:**
1. 由 Task 3.1 脚本写出 33 个文件
2. **不动** 3 个已删除结构的残留文件（`giant_mushroom_biomes`、`mining_system_biomes`、`small_prairie_house_biomes`）
3. **不动** 5 个末地结构的对应标签（`aviary_biomes`、`keep_kayra_biomes`、`heavenly_*_biomes`）——它们的结构 JSON override 已接管 `biomes`，改标签无意义且会污染末地

**Verification:**
```powershell
$d="kubejs/data/dungeons_arise/tags/worldgen/biome/has_structure"
$modified = Get-ChildItem $d -File | Where-Object {
  (Get-Content $_.FullName -Raw) -match 'beloong:'
}
$modified.Count                                     # 期望 33
$untouchedEnd = @('aviary_biomes','keep_kayra_biomes','heavenly_rider_biomes',
                  'heavenly_conqueror_biomes','heavenly_challenger_biomes')
$untouchedEnd | ForEach-Object {
  if ((Get-Content "$d\$_.json" -Raw) -match 'beloong:') { "误改末地标签: $_" }
}
# 期望：无输出
(Get-Content "$d\mining_system_biomes.json" -Raw | ConvertFrom-Json).values.Count   # 期望 0
```

**验证门：** Task 3.2 通过前**不得**开始 Batch 5（清空原结构集）。

---

## Batch 4：两套结构集

### Task 4.1：新建 `disaster_set_ground`

**Files:**
- Create: `kubejs/data/beloong/worldgen/structure_set/disaster_set_ground.json`

**Steps:**
1. 成员 = 设计文档 §2.5 的 29 个地面结构，**由脚本从 Task 3.1 的成员集合产出**
2. 权重：地面 29 = 权重 3 共 10 个 + 权重 2 共 12 个 + 权重 1 共 7 个；地下 4 个在另一集且各为权重 2
3. `placement`: `{"type":"minecraft:random_spread","spacing":32,"separation":16,"salt":20260921}`
4. `exclusion_zone`: `{"other_set":"beloong:disaster_set_underground","chunk_count":10}`

**Verification:**
```powershell
$f="kubejs/data/beloong/worldgen/structure_set/disaster_set_ground.json"
$j=Get-Content $f -Raw | ConvertFrom-Json
$j.structures.Count                                  # 期望 29
$j.placement.spacing                                 # 期望 32
$j.placement.separation                              # 期望 16
$j.placement.salt                                    # 期望 20260921
($j.structures | ForEach-Object { $_.weight } | Group-Object | ForEach-Object { "$($_.Name):$($_.Count)" })
# 期望 1:7 / 2:17 / 3:10
$j.structures | ForEach-Object {
  $id=$_.structure.Replace('dungeons_arise:','')
  if (-not (Test-Path "D:\Minecraft\闭源模组解压文件\地牢浮现之时\data\dungeons_arise\worldgen\structure\$id.json")) {
    "结构不存在: $id" }
}
# 期望：无输出
```

### Task 4.2：新建 `disaster_set_underground`

**Files:**
- Create: `kubejs/data/beloong/worldgen/structure_set/disaster_set_underground.json`

**Steps:**
1. 成员 = `foundry`、`mining_complex`、`plague_asylum`、`infested_temple`，权重各 2
2. `placement`: `{"type":"minecraft:random_spread","spacing":32,"separation":16,"salt":20260922}`
3. `exclusion_zone` **只能有一个**（实测：全实例 12 个结构集用了该字段、**0 个**用了多个；它是单值对象 `{"chunk_count":N,"other_set":"..."}`，非数组）
   - **取 `{"chunk_count":10,"other_set":"beloong:disaster_set_ground"}`**
   - **放弃 `minecraft:strongholds`**（用户 2026-09-21 确认）：地面↔地下在 forest/taiga/plains 等群系上高度重叠，互斥收益最大；而 `plague_asylum` 在 sparsity 32 的随机扩散下与要塞撞点的概率极低，不值得为它放弃更重要的互斥

**Verification:**
```powershell
$f="kubejs/data/beloong/worldgen/structure_set/disaster_set_underground.json"
$j=Get-Content $f -Raw | ConvertFrom-Json
$j.structures.Count                        # 期望 4
$j.placement.salt                          # 期望 20260922
$j.placement.exclusion_zone.other_set      # 期望 beloong:disaster_set_ground
([regex]::Matches((Get-Content $f -Raw),'"exclusion_zone"')).Count   # 期望 1
```

### Task 4.3：清理旧杂项

**Files:**
- Modify: `kubejs/data/dungeons_arise/tags/worldgen/biome/has_structure/mining_system_biomes.json` → **确认不动**
- 记录: `beloong:disaster_set` 保持不动

**Steps:**
1. 确认 `mining_system_biomes.json` 仍为 `{"replace":false,"values":[]}`
2. 确认 `beloong:disaster_set` 未被本次任何改动触碰（`git diff` 应无该文件）

**Verification:**
```powershell
git status --short | Select-String 'disaster_set.json'
# 期望：无输出（未被修改）
```

---

## Batch 5：清空 DA 原结构集

### Task 5.1：清空两个原结构集

**Files:**
- Modify: `kubejs/data/dungeons_arise/worldgen/structure_set/major_structures.json` → `{"structures":[],"placement":{...原值...}}`
- Modify: `kubejs/data/dungeons_arise/worldgen/structure_set/minor_structures.json` → 同上

**Steps:**
1. **前置检查**：确认 Batch 4 的 4.1/4.2 已验证通过、两套新集文件已存在
2. 保留原 `placement` 字段原值（`spacing`/`separation`/`salt`），仅把 `structures` 置空
3. `minor_structures` 的 `exclusion_zone` 保留原值

**Verification:**
```powershell
foreach ($f in @('major_structures','minor_structures')) {
  $j = Get-Content "kubejs/data/dungeons_arise/worldgen/structure_set/$f.json" -Raw | ConvertFrom-Json
  "$f : structures=$($j.structures.Count)  spacing=$($j.placement.spacing)"
}
# 期望：两者 structures=0，placement 原值保留
Test-Path "kubejs/data/beloong/worldgen/structure_set/disaster_set_ground.json"      # True
Test-Path "kubejs/data/beloong/worldgen/structure_set/disaster_set_underground.json" # True
```

**⚠️ 风险门：** 本任务一旦落地，33 个迁移结构将**只在天灾维度生成**。若前序有任何失败，结构会在所有维度消失。

---

## Batch 6：静态校验与运行期验证

### Task 6.1：JSON 与引用完整性静态校验

**Files:**
- Create: `tools/verify-disaster-migration.ps1`

**Steps:**
1. 校验 69 个产物的 JSON 全部可解析
2. 校验每个 `beloong:disaster/*` 里的群系 ID 都在 BWG 全集 ∪ 化龙 5 个自制群系内
3. 校验每个 `has_structure/*` 引用的 `#beloong:*` 标签文件都存在
4. 校验两套结构集的每个结构 ID 都在 DA jar 的 40 个结构内，且**不含** 3 个已删除结构
5. 校验权重表闭合：地面 29（10 + 12 + 7）+ 地下 4 = **33**；脚本必须输出账目并断言 33

**Verification:**
```powershell
pwsh -File tools/verify-disaster-migration.ps1
# 期望：0 错误
```

### Task 6.2：运行期验证（需启动游戏）

**Steps:**
1. 启动后查看日志：**不得有** `Tag` / `Failed to load` / `Unknown biome` 类报错
2. `/reload` 后再次确认无报错
3. 逐项验证白名单结构在天灾生成：
   ```
   /execute in beloong:disaster run locate structure dungeons_arise:coliseum
   /execute in beloong:disaster run locate structure dungeons_arise:bandit_village
   /execute in beloong:disaster run locate structure dungeons_arise:foundry
   /execute in beloong:disaster run locate structure dungeons_arise:mechanical_nest
   ```
   期望：均返回坐标而非 `ERROR_STRUCTURE_NOT_FOUND`
4. 验证已撤出：在**主世界**执行
   ```
   /execute in minecraft:overworld run locate structure dungeons_arise:coliseum
   ```
   期望：`ERROR_STRUCTURE_NOT_FOUND`
5. 验证末地那 5 个仍在末地：
   ```
   /execute in minecraft:the_end run locate structure dungeons_arise:keep_kayra
   ```
   期望：找到
6. 验证空中集未受影响：
   ```
   /execute in beloong:disaster run locate structure mss:arena
   ```
   期望：找到
7. **必须用从未探索过的新区域**（旧区块群系固化在 NBT 里不回填）

**Verification:** 上述 7 条 `locate` 结果全部符合期望；日志零报错。

---

## Batch 7：文档与记忆同步

### Task 7.1：更新整合包文档

**Files:**
- Modify: `CHANGELOG.md`（新增条目，按既有分区格式）
- Modify: `docs/plans/2026-09-21-dungeons-arise-disaster-migration-design.md` 的 Status 字段 → `Implemented`

**Steps:**
1. CHANGELOG 按「内容改动」分区写一条：地牢浮现之时 33 个结构迁移至天灾维度
2. 若产生偏差（如 `exclusion_zone` 双互斥语法不支持），在设计文档追加「实施偏差」小节

**Verification:**
```powershell
Select-String -Path CHANGELOG.md -Pattern '地牢浮现' | Measure-Object | Select-Object -ExpandProperty Count
# 期望 >= 1
```

### Task 7.2：更新记忆

**Files:**
- Modify: `.claude/memory/decisions-log.md`（若实施产生新决策）
- Modify: `.claude/memory/learned-patterns.md`（若发现新手法）

**Steps:** 仅在有实际新决策/新手法时追加；否则跳过。

**Verification:** `git status` 显示预期文件。

---

## 交付物汇总

| 类别 | 数量 |
|---|---|
| `beloong:disaster/*` 主题标签 | 31（改写 22 + 新建 9） |
| `beloong:is_disaster` | 1（→60 项） |
| `dungeons_arise:has_structure/*` | 33 |
| 新结构集 | 2 |
| 清空的结构集 | 2 |
| 工具脚本 | 3 |
| **合计文件操作** | **69 + 3 脚本** |

## 不做的（Non-Goals）

- 不动 `beloong:disaster_set`（空中结构集）
- 不动 5 个末地结构的 `worldgen/structure/*.json` override
- 不动 3 个已删除结构的残留文件
- 不剔除原版/其他模组在天灾的结构（独立议题）
- 不统一 `beloong:is_desert` / `is_sea` / `is_snowy` 与 `disaster/*` 两套主题轴

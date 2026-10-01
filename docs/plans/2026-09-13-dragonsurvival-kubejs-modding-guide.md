# 『化龙』Dragon Survival 魔改学习总结（KubeJS 数据包覆盖）

> 生成日期：2026-09-13
> 学习对象：`kubejs/data/dragonsurvival/`（数据包覆盖）+ `D:\Minecraft\开源模组参考文件\DragonSurvival`（模组源码）
> 参考准则：`docs/龙之生存附属模组适配准则.md`
>
> **版本基线**
> - 实例实际加载：`mods\[龙之生存] DragonSurvival-1.21.1-v2.0.67-24.08.2026-all.jar`
> - 手头源码：`2.0.64`（`gradle.properties` → `mod_version=2.0.64`）
> - 两者在本次涉及的关键机制上一致；行号引用以 2.0.64 为准，使用前请在 2.0.67 上复核。
> - 化龙核心模组：`mods\beloong-0.9.3.jar`
>   - **权威源码：`D:\Minecraft\BeLoong-Core`**（`mod_version=0.9.3`，MIT，作者 PorkChop-ZLG）
>   - 本文件第 5 章的所有结论均来自该源码仓库（含中文 Javadoc），**不是**反编译产物

---

## 一、三层魔改架构（最重要的一张图）

『化龙』对 Dragon Survival 的魔改**不是单一手段**，而是三层叠加。理解这三层的分工，是读懂后续所有内容的前提。

```
┌─────────────────────────────────────────────────────────────────────┐
│ 第 1 层：KubeJS 数据包覆盖（本会话重点）                              │
│   kubejs/data/<ns>/...  → 与模组同名路径 → 整体覆盖                  │
│   手段：纯 JSON，零代码，热重载友好                                   │
│   能做：物种/技能/阶段/诅咒/身体/饮食/信标/末地平台/标签              │
│   不能做：新增注册表条目类型、新增属性、新增效果类型、改运行逻辑       │
├─────────────────────────────────────────────────────────────────────┤
│ 第 2 层：化龙核心模组 BeLoong-Core（Java + Mixin）                   │
│   源码：D:\Minecraft\BeLoong-Core          （详见 §5）               │
│   ① Mixin：注入属性、改写运行公式、修模组缺陷                         │
│   ② 注册自定义能力效果：beloong:air_strike / beloong:tp_loong_palace │
│   ③ 自带数据包内容：dragonsurvival:air_strike 等技能 JSON            │
│   ④ 注册自定义状态效果：flight_ban / serene / mana_loss 等           │
│   本会话关键发现：dragonsurvival:flight_level 属性由这一层注入        │
├─────────────────────────────────────────────────────────────────────┤
│ 第 3 层：KubeJS 脚本（startup/server_scripts）                       │
│   手段：注册自定义物品、批量改物品属性修饰符、右键交互                │
│   例：kubejs:cave_dragon_heart 等"龙心"系列、龙鳞套装加魔力属性       │
└─────────────────────────────────────────────────────────────────────┘
```

**关键区分**：第 1 层与第 2 层的边界不是"数据 vs 代码"，而是
**"能否扩展注册表"**。第 2 层里有大量**数据包内容**（`BeLoong-Core/src/main/resources/data/`），
它们之所以放在模组里而不是 KubeJS，是因为它们**引用了只有模组才能注册的东西**
（自定义 `effect_type`、自定义 `mob_effect`、自定义 `damage_type`）。
反过来，只要不引用自定义注册项，就应放第 1 层（可热重载、无需重新编译打包）。

**判据**：当你在数据包 JSON 里看到某个注册表 ID 在模组里"查不到"时，**先去第 2 层（beloong 核心模组 mixin）找**，不要立刻判定为笔误。本会话就踩过这个坑（见 §6.1）。

---

## 二、覆盖文件清单与改动分类

`kubejs/data/dragonsurvival/` 共 **332 个文件**。

| 目录 | 文件数 | 性质 |
|---|---|---|
| `advancement/{aether,cave,forest,sea,tundra}/` | 45 | 龙种进度（新增/改写） |
| `damage_type/` | 1 | 自定义伤害类型 `wind_breath` |
| `data_maps/dragonsurvival/` | 5 | **覆盖（整体替换）**：`dragon_body/body_icons` + `dragon_species/{diet_entries,dragon_beacon_data,end_platforms,stage_resources}` |
| `dragonsurvival/dragon_ability/` | 87 | 覆盖 + 新增技能 |
| `dragonsurvival/dragon_body/` | 3 | 自定义身体 |
| `dragonsurvival/dragon_emote_set/` | 2 | 自定义表情集 |
| `dragonsurvival/dragon_penalty/` | 3 | 自定义诅咒 |
| `dragonsurvival/dragon_species/` | 16 | 覆盖 + 新增物种 |
| `dragonsurvival/dragon_stage/` | 50 | 覆盖 + 新增阶段 |
| `dragonsurvival/projectile_data/` | 7 | 弹射物 |
| `loot_table/chests/` | 5 | 龙之国度战利品 |
| `structure/` | 41 | 末地平台 / 龙之国度结构 |
| `tags/` | 30 | 标签（append / replace） |
| `worldgen/` | 37 | 结构、结构集、模板池 |

### 2.1 覆盖 vs 新增的判定方法

```powershell
# 判定某个文件是"覆盖模组"还是"化龙新增"
$ov='kubejs\data\dragonsurvival\dragonsurvival'
$md='D:\Minecraft\开源模组参考文件\DragonSurvival\src\generated\resources\data\dragonsurvival\dragonsurvival'
Get-ChildItem "$ov\dragon_species" -Filter *.json | ForEach-Object {
  $s = if (Test-Path "$md\dragon_species\$($_.Name)") {"MOD-EXISTS"} else {"NEW"}
  "$($_.Name)  $s"
}
```

实测结果（`dragon_species`）：

| 文件 | 判定 | 含义 |
|---|---|---|
| `cave_dragon.json` / `forest_dragon.json` / `sea_dragon.json` | **MOD-EXISTS** | 覆盖模组原生三主龙，**必须随模组更新同步** |
| `tundra_dragon.json` / `frostfire_dragon.json` / `aether_dragon.json` / `astral_dragon.json` / `annihilator_type_a.json` / `star_dragon.json` / `wing_kirin.json` 等 13 个 | **NEW** | 覆盖**附属模组**提供的物种文件，同样是覆盖 |

> ⚠️ 关键认知：模组自身只定义了 **3 个物种**（cave / forest / sea）。
> 其余 13 个物种的 JSON 分别来自各附属 mod 的 jar，化龙的数据包**逐一覆盖了它们**。
> 也就是说：**化龙掌握着全部 16 个物种定义的最终版本**，附属 mod 更新物种文件时，
> 化龙若不跟进，其覆盖版本会"锁死"在旧行为上。

---

## 三、从源码确认的 8 项核心机制

以下每条都已在源码中核验，并标注可复用的字段名。

### 3.1 数值提供器 = 原版 `LevelBasedValue`（不是 DS 自定义）

**这是整套系统的地基。** 所有 `amount` / `growth_requirement` / `duration` / `amplifier` 字段都用它。

```java
// common/codecs/Modifier.java:17-21
public static final Codec<Modifier> CODEC = RecordCodecBuilder.create(instance -> instance.group(
        Attribute.CODEC.fieldOf("attribute").forGetter(Modifier::attribute),
        Codec.either(LevelBasedValue.CODEC, PreciseLevelBasedValue.CODEC).fieldOf("amount").forGetter(Modifier::amount),
        AttributeModifier.Operation.CODEC.fieldOf("operation").forGetter(Modifier::operation)
).apply(instance, Modifier::new));
```

- `LevelBasedValue.CODEC` = `either(Constant.CODEC /* 裸浮点 */, DISPATCH_CODEC)`，注册表是原版
  `BuiltInRegistries.ENCHANTMENT_LEVEL_BASED_VALUE_TYPE`。
- 可用 `type`：`minecraft:linear` / `minecraft:lookup` / `minecraft:clamped` / `minecraft:fraction` / `minecraft:levels_squared`；**裸数字 = Constant**。
- `lookup`：`calculate(level) = level <= values.size() ? values.get(level-1) : fallback.calculate(level)`
  —— `fallback` 是**必需字段**，仅在 level 超出 `values` 长度时启用。
- `linear`：`calculate(level) = base + per_level_above_first * (level - 1)`（第 1 级取 `base`）。
- **DS 额外支持 `PreciseLevelBasedValue`**：`{"precise_base": B, "precise_amount": A}` → `B + A * level`（**double 连续值，不截断**）。用在 `dragon_stage` 的 `generic.scale` 上。

> **易错点**：`Modifier.calculate(double level)`（`Modifier.java:59-61`）对 `LevelBasedValue` 会**截断成 int**
> （`value.calculate((int) level)`）。只有 `PreciseLevelBasedValue` 才享受 double。
> 因此 `dragon_stage` 上写 `linear` 时，实际是 `B + P * ((int)(growth - stageMin) - 1)`。

### 3.2 `dragon_ability` 顶层只有 6 个字段

```java
// registry/dragon/ability/DragonAbility.java
activation                // 必需，dispatch 字段 activation_type
upgrade                   // 可选，dispatch 字段 upgrade_type
usage_blocked             // 可选 LootItemCondition
actions                   // 可选，默认 []
can_be_manually_disabled  // 默认 true
icon                      // 必需，LevelBasedResource
```

**没有**顶层 `mana_cost` / `cooldown` / `range` / `duration` / `effect_type`：
- `mana_cost`、`cooldown`、`cast_time` 在 **`activation` 内部**（`initial_mana_cost` / `continuous_mana_cost`）。
- `effect_type` 是 `actions[].target_selection.applied_effects.entity_effect[]` 元素的 dispatch 字段。
- `target_type` 在 `target_selection` 内：`self` / `area` / `disc` / `looking_at` / `dragon_breath`。

`upgrade_type` 取值与 `maximum_level` 支持情况：

| upgrade_type | 是否有 `maximum_level` | 等级上限来源 |
|---|---|---|
| `dragonsurvival:experience_points` | **有（必需）** | 字段值 |
| `dragonsurvival:experience_levels` | **有（必需）** | 字段值 |
| `dragonsurvival:dragon_growth` | **有（必需）** | 字段值 |
| `dragonsurvival:item_based` | **无** | `items_per_level.size()` |
| `dragonsurvival:condition_based` | **无** | `conditions.size()` |

> 化龙的 `*_wings.json` 用 `dragon_growth` + `maximum_level: 6`，写法正确；
> 而 DS 原版 `cave_wings.json` 用 `condition_based`（只有 0/1 两态）——**化龙是刻意改写的**。

### 3.3 `growth_requirement` 与"6 级翅膀"的可达性

```java
// registry/dragon/ability/upgrade/DragonGrowthUpgrade.java:21-42
int newLevel = 0;
for (int level = 1; level <= maxLevel(); level++) {
    if (data.input() < growthRequirement.calculate(level)) break;
    newLevel++;
}
```

⇒ 等级 N = 满足 `growth >= requirement(N)` 的最大 N。`growth < requirement(1)` 时为 0 级。

化龙使用的 lookup `[20, 50, 100, 150, 200, 250]` + `maximum_level: 6`：

| 等级 | 需求成长 |
|---|---|
| 1 | 20 |
| 2 | 50 |
| 3 | 100 |
| 4 | 150 |
| 5 | 200 |
| 6 | 250 |

> ⚠️ **可达性依赖 `dragon_stage` 覆盖**。DS 默认阶段的成长上限只有 **60**
> （`newborn 10-25` / `young 25-40` / `adult 40-60`），此时最多只能到 2 级。
> 化龙必须同时用 `custom_stage_progression` 把成长区间撑到 ≥250，第 3 级以上才解锁。
> **这是适配新从龙时最容易漏掉的一步**（准则 §2.2.2 有提，但没解释"为什么"）。

### 3.4 `dragon_species` 字段与 `mana_handling` 的双层默认值

```java
// registry/dragon/DragonSpecies.java:45-54
starting_growth            // 可选 double，(1, MAX)
unlockable_behavior        // 可选
mana_handling              // 可选，默认 ManaHandling.DEFAULT
custom_stage_progression   // 可选 HolderSet<DragonStage>
bodies                     // 可选
abilities                  // 可选 HolderSet<DragonAbility>
penalties                  // 可选 HolderSet<DragonPenalty>，默认空
misc_resources             // **必需**
```

**没有** `growth` / `stages` / `start_stage` 字段（起始阶段由 `starting_growth` 反查）。

`mana_handling` 的两个默认层级（极易出错）：

| 写法 | 结果 |
|---|---|
| 完全没有 `"mana_handling"` 键 | `ManaHandling.DEFAULT = (xp 0.1, perLevel 0.25, max 9)` |
| 写了 `"mana_handling": {}` | 三字段各取 codec 默认 → **(0, 0, 0)**，等于**关闭** |

**字段语义纠正**（`common/handlers/magic/ManaHandler.java:119-129`）：

```java
return (float) Math.min(manaHandling.maxManaFromLevels(),
                        player.experienceLevel * manaHandling.manaPerLevel());
```

`mana_per_level` 乘的是 **`player.experienceLevel`（原版经验等级）**，不是龙成长等级、也不是能力等级。
所以化龙统一的 `{0.2, 0, 20}` 真实含义是：**每 1 个原版经验等级 +0.2 最大魔力，最多 +20（即经验等级 100 封顶），并关闭 XP↔魔力互转**。

`unlock_condition` 就是原版 `LootItemCondition.DIRECT_CODEC`；DS 额外注册 3 个 `ENTITY_SUB_PREDICATE_TYPE`：
`dragonsurvival:dragon_predicate` / `dragonsurvival:entity_check_predicate` / `dragonsurvival:custom_predicates`。

### 3.5 `dragon_stage` 与阶段链

```java
// registry/dragon/stage/DragonStage.java:41-60
is_default                    // bool，默认 false
growth_range {min, max}       // 必需，min>=1 且 max>min
ticks_until_grown             // 必需，intRange(1, daysToTicks(365))
modifiers                     // 默认 []
growth_items                  // 默认 []
is_natural_growth_stopped     // 可选 EntityPredicate
destruction_data              // 可选
```

- **没有 `next_stage` 字段**。阶段链靠 `growth_range` 数值**首尾相接**（`areStagesConnected`），边界值归下一个阶段。
- 校验（`DragonStage.validate`）：`newborn` / `young` / `adult` 三个 id 必须存在；默认阶段区间必须连续；
  `destruction_data.crushing_growth` / `block_destruction_growth` 必须**落在本阶段区间内**。
- `growth_items[]`：`items`（id 列表或 `#tag`）、`growth_in_ticks`（int，**可为负**，`0` = 切换自然成长开关）、`maximum_usages`（默认 -1 = 无限）。
- 化龙把默认三阶段覆盖为 `newborn 20-50` / `young 50-100` / `adult 100-150`，并新增
  `cave_ancient 150-200` / `cave_archean 200-250` / `cave_progenitor 250-300`，串成 20→300 连续链。
- `kubejs:cave_dragon_heart` 作为 `cave_ancient` 的成长道具 —— **数据包与 KubeJS 脚本在此咬合**（第 1 层 × 第 3 层）。

### 3.6 饮食条目 `DietEntry` 的真实结构

```java
// common/codecs/DietEntry.java:24-29
public record DietEntry(String items,
                        Optional<FoodProperties> properties,
                        Optional<Either<Boolean, RetainEffects>> retainEffects)
```

> ⚠️ **`nutrition` / `saturation` / `eat_seconds` / `can_always_eat` / `effects` / `using_converts_to`
> 都不是顶层字段**，全部嵌在 `properties` 里，由**原版** `FoodProperties.DIRECT_CODEC` 定义。

`properties` 内字段（原版 `FoodProperties.java:21-31`）：

| 字段 | 类型 | 必需/默认 |
|---|---|---|
| `nutrition` | `NON_NEGATIVE_INT` | **必需** |
| `saturation` | `FLOAT` | **必需** |
| `can_always_eat` | bool | 默认 `false` |
| `eat_seconds` | `POSITIVE_FLOAT` | 默认 `1.6` |
| `using_converts_to` | 单物品 | 可选 |
| `effects` | `List<PossibleEffect>` | 默认 `[]`，元素 `{effect: MobEffectInstance, probability: 0..1 = 1}` |

其它三个坑：

1. `saturation` 是**绝对饱和度值**，不是 vanilla Builder 的 saturationModifier。
2. 原版 `FoodData.add()` 会把饱和度**夹到新的 foodLevel**
   （`Mth.clamp(saturation + cur, 0, foodLevel)`）⇒ **`nutrition` 小于 `saturation` 时饱和度会被截断**。
   化龙数据里 `charged_soup: nutrition 15 / saturation 15` 刚好，是刻意对齐的。
3. **覆盖语义**：`DietEntryMerger` 是 `removeIf(secondValue::contains); addAll(secondValue)`，
   而 `DietEntry.equals` **只比较 `items` 字符串**。
   ⇒ 想替换某条必须**保持 `items` 字符串完全一致**（含 `#tag` 前缀与正则原文），否则会变成"新增一条"。

`items` 支持三种写法（`common/codecs/ResourceLocationWrapper.java`）：`namespace:path`、`#tag`、以及**正则**（合法起始字符 `. ^ [ ( \`）。

### 3.7 龙之信标 `dragon_beacon_data`：付费与免费两种模式

```java
// server/tileentity/DragonBeaconBlockEntity.java:54-64
if (paidExperience) {
    duration  *= data.paymentData().durationMultiplier();
    amplifier += data.paymentData().amplifierModification();
}
```

- **付费激活**（玩家右键信标消耗经验）才应用 `duration_multiplier` 与 `amplifier_modification`。
- **免费模式**（信标下方是 `dragonsurvival:dragon_memory_block`，每 20 tick 给 50 格内玩家）
  只用 `effects[].duration/amplifier`，`duration = -1` 表示无限。
- `dragonsurvival:empowered_soul`（**准则要求必填**）本身无属性修正，作用是**压制"龙魂冷却"**：
  获得时移除 `exhausted_soul`，并阻止 `exhausted_soul` 附着 ⇒ 可以随时自由切换形态。
- 化龙用 `#dragonsurvival:all` 作为兜底条目，再为每个物种追加专属效果。

### 3.8 末地平台 `end_platforms`

```java
public record EndPlatform(ResourceLocation structure, BlockPos spawnPosition)
```

- `EndPortalBlockMixin` 在主世界进末地时替换落点；`EndPlatformHandler.placePlatform` 负责放置平台结构。
- 用 `PlacedEndPlatforms` 附件**按 structure id 判重**：同一 structure 每维度只放一次。
- 化龙为 14 个物种分配了**互不重叠**的坐标；新增物种时必须检查冲突（准则 §2.2.1 已强调）。

---

## 四、四类覆盖手法的具体写法

### 4.1 数据包注册表条目（species / ability / stage / penalty / body）→ **整体覆盖**

同 id 的高优先级包**整体替换**，**无字段级 merge**。

源码依据：DS 的 7 个 datapack registry 全部使用**两参数**重载

```java
// 例如 registry/dragon/DragonSpecies.java:109-111
event.dataPackRegistry(REGISTRY, DIRECT_CODEC, DIRECT_CODEC);
```

两参数重载不携带 `Cookie`，因此 **NeoForge 不会做对象级合并**，而是直接用 `DIRECT_CODEC`
解析高优先级包里的整个 JSON 作为该 id 的最终值。全仓库 grep `Cookie` **零命中**，
确认 DS 没有任何自定义合并逻辑。

⇒ **覆盖 = 完整重写该文件**。这解释了两条看似矛盾的现象：

1. `cave_dragon.json` 覆盖版必须**原样抄回** `misc_resources` 全部内容，只加/改需要的字段。
2. `frostfire_dragon.json` 覆盖版是**附属原始文件 + 增量字段的并集**，不是只写增量。

**标准从龙覆盖模板**（以 frostfire 为参照，对照其附属原始文件）：

```diff
 {
 	"abilities": "#dragonsurvival:frostfire_dragon",
+	"mana_handling": { "mana_per_level": 0.2, "mana_xp_conversion": 0, "max_mana_from_levels": 20 },
 	"misc_resources": { ...原样保留... },
 	"penalties": "#dragonsurvival:frostfire_dragon",
+	"unlockable_behavior": {
+		"visibility": "visible_if_locked",
+		"unlock_condition": { "condition": "minecraft:any_of", "terms": [ ...两个进度分支... ] }
+	}
 }
```

> 注意 `unlock_condition` 里的 `"condition": "any_of"` / `"type": "player"` 省略了 `minecraft:` 前缀。
> 原版 `ResourceLocation` 解析默认补 `minecraft:` 命名空间，**能正常工作**；
> 但为可读性建议统一写全 `minecraft:any_of`（化龙的 annihilator / frostfire 文件就写全了，cave / dihuang 没写全 —— 风格不统一）。

### 4.2 标签（tags）→ **默认追加，`replace: true` 才替换**

| 场景 | 写法 | 化龙实例 |
|---|---|---|
| 给模组已有标签**追加**条目 | 不写 `replace`（默认 `false`） | `tags/dragonsurvival/dragon_ability/cave_dragon.json` 在模组 15 条后追加 ISS 技能 + `become_bigger/smaller` |
| **替换**模组标签 | `"replace": true` | `tags/dragonsurvival/dragon_species/order.json`（祭坛显示顺序）、`tags/dragonsurvival/dragon_penalty/dihuang_loong.json` |
| 新增自制标签 | `"replace": false` | `tags/dragonsurvival/dragon_ability/annihilator_type_a.json` |

`dragon_species/order.json` 的运行时语义（准则称"必须修改"）：
`client/gui/screens/DragonAltarScreen.java:118-129` —— **祭坛物种显示顺序**，按 tag 索引排序，
**不在 tag 中的物种排最后**。`beginner_aether_dragon` 必须在最底部是出于玩法引导需求。

`dragon_ability/order.json` 则控制**能力界面三列排序**（主动 / 可升级被动 / 恒定被动）。

### 4.3 数值型改写：以"6 级翅膀"为例

化龙对**全部 10 个 `*_wings` 技能**（外加附属的 `star_wings` / `kirin_wing`，共 12 个文件）
统一施加三段 modifier：

```jsonc
"entity_effect": [
  { "effect_type": "dragonsurvival:flight", "icon": "...", "level_requirement": 1 },
  { "effect_type": "dragonsurvival:modifier",
    "modifiers": [{ "base": { "id": "dragonsurvival:cave_wings_flight_level", "is_hidden": true },
      "modifiers": [{ "attribute": "dragonsurvival:flight_level",
        "amount": { "type": "minecraft:lookup",
                    "values": [0,1,2,3,4,5],
                    "fallback": { "type": "minecraft:linear", "base": 0, "per_level_above_first": 1 } },
        "operation": "add_value" }]}]},
  { "effect_type": "dragonsurvival:modifier",  // flight_speed: linear base -0.2, per_level 0.1
    "modifiers": [{ "base": { "id": "dragonsurvival:cave_wings_flight_speed", "is_hidden": true },
      "modifiers": [{ "attribute": "dragonsurvival:flight_speed",
        "amount": { "type": "minecraft:linear", "base": -0.2, "per_level_above_first": 0.1 },
        "operation": "add_value" }]}]},
  // flight_stamina 同上，属性 id 换掉
]
```

`upgrade` 段同时改为 `dragon_growth` + `maximum_level: 6` + lookup `[20,50,100,150,200,250]`，
`icon.texture_entries` 的 `from_level: 0..6` 全部指向同一张贴图。

> **`base.is_hidden` 的作用**：`ModifierWithDuration` 的 `base` 字段是
> `DurationInstanceBase`（`id` / `duration` / `should_remove_automatically` / `early_removal_condition` /
> `custom_icon` / `is_hidden`）。`is_hidden: true` 让这条修正不出现在技能 tooltip 的属性列表里，
> 避免把"飞行等级 0~5"这种内部数值暴露给玩家。
>
> **`id` 的复用是安全的**：化龙所有翅膀技能都`id` 复用 `dragonsurvival:cave_wings_flight_*`（连附属的
> `annihilator_type_wings.json` 也照抄）。因为同一玩家同一时刻只可能是一条龙种，属性修饰符
> 按 id 去重不会互相干扰。

### 4.4 `neoforge:conditions` 被覆盖掉带来的隐性依赖

DS 自带的 4 个 DataMap JSON 里，每个条目都带一个条件守卫：

```jsonc
// 模组原版 data_maps/.../diet_entries.json
"dragonsurvival:cave_dragon": {
  "neoforge:conditions": [
    { "type": "dragonsurvival:registered",
      "registry": "dragonsurvival:dragon_species",
      "value": "dragonsurvival:cave_dragon" }
  ],
  "neoforge:value": [ ... ]
}
```

（`registry/datagen/data_maps/RegisteredCondition.java` 定义，datagen 自动生成。）

化龙的覆盖版把 `neoforge:conditions` **全部删除**，并直接把 `neoforge:value` 的内容提到该物种键下：

```jsonc
"dragonsurvival:cave_dragon": [ { "items": "#minecraft:coals", "properties": {...} }, ... ]
```

**收益**：文件更短、可读性更好，且省去了 datagen 专属条件。

**代价**：条目失去了"该物种/依赖模组是否已注册"的守卫。化龙的 4 个 DataMap 覆盖版
**引用了所有 9 个龙之生存附属模组**的物种 id 与物品
（`star_dragon:*`、`tundradragon:*`、`frostfire_dragon:*`、`crystcursed_dragon:*`、
`ds_aether_addon:*`、`wing_kirin:*`、`additionaldragons:*` 等）。

⇒ **这 4 个文件对附属模组是硬依赖集合**：任何附属被移除，对应的物种 id / 物品 id 就会悬空。
改动或精简整合包模组列表时，**必须同步清理这 4 个文件**，否则会留下悬空引用。

### 4.5 自定义属性 / 身体 / 诅咒：扩展模组能力边界

数据包能做的不止"覆盖"，还能**新增**模组没有的东西：

| 类型 | 化龙实例 | 源码依据 |
|---|---|---|
| 自定义 `dragon_body` | `aether_body` / `aether_body_human` / `tundra_body_human`（含 `modifiers` 属性修正、`scaling_proportions`） | `DragonBody.java:59` datapack registry，可整体覆盖/新增 |
| 自定义 `dragon_penalty` | `batophobia`（以太龙恐高）、`source_emptiness`（晶咒龙魔源枯竭） | `DragonPenalty.java:47` datapack registry；**模组内不存在这两个 id** |
| 自定义 `dragon_emote_set` | `qinglong_emotes` / `liebel_emotes` | `DragonEmoteSet.java:21` |
| 自定义 `damage_type` | `wind_breath` | 原版 datapack registry |
| 自定义 `dragon_stage` | `main_sequence` / `cave_ancient` / `kirin_*` … | `DragonStage.java:50` |

`batophobia` 的 `condition` 是 `minecraft:inverted` + `any_of` 组合：
「不在地面 **且** 没有 `beloong:serene` / `beloong:growth_acceleration` / `dragonsurvival:source_of_magic`」
→ 施加 `beloong:mana_loss`。这是用**原版 loot condition** 表达复杂玩法条件的范例。

`item_blacklist` 覆盖版（化龙禁用盾牌/鞘翅类）用到了 `items` 的**正则**写法：

```json
"items": ["#c:tools/shield", "minecraft:trident", ".*:.*?elytra.*", "cataclysm:black_steel_targe", ...]
```

---

## 五、BeLoong-Core 对 Dragon Survival 的扩展（第 2 层）

> 本章全部结论来自**源码仓库 `D:\Minecraft\BeLoong-Core`**（`mod_version=0.9.3`）。
> 该仓库的 Javadoc 是中文且相当完整，**是本项目最好的设计意图文档来源**，优先于反编译。

BeLoong-Core 对 DS 的扩展有**四条独立路径**，Mixin 只是其中一条：

| 路径 | 机制 | 实例 |
|---|---|---|
| ① Mixin 注入 | `beloong.mixins.json` | 17 个 DS 相关 mixin（§5.1–5.5） |
| ② 注册自定义**能力效果类型** | `RegisterEvent` + `AbilityEntityEffect.REGISTRY` | `beloong:air_strike`、`beloong:tp_loong_palace` |
| ③ 自带**数据包内容** | `src/main/resources/data/` | `dragonsurvival:air_strike`、`dragonsurvival:tp_loong_palace` 技能 JSON |
| ④ 注册自定义**状态效果** | `DeferredRegister<MobEffect>` | `beloong:flight_ban` / `serene` / `growth_acceleration` / `mana_loss` |

`beloong.mixins.json` 共 **39 个 mixin**，其中 **17 个直接针对 Dragon Survival**。

### 5.1 `DSAttributesMixin` —— 注入 `dragonsurvival:flight_level` 属性

```java
// BeLoong-Core: .../mixin/dragonsurvival/DSAttributesMixin.java:47-67
@Inject(method = "<clinit>", at = @At("RETURN"))
private static void registerFlightLevel(CallbackInfo ci) {
    beloong$FLIGHT_LEVEL = DSAttributes.REGISTRY.register(
            "flight_level",
            () -> new RangedAttribute("attribute.dragonsurvival.flight_level",
                    0.0, -1024.0, 1024.0).setSyncable(true));
}

@Inject(method = "attachAttributes", at = @At("TAIL"))
private static void attachFlightLevel(EntityAttributeModificationEvent event, CallbackInfo ci) {
    event.add(EntityType.PLAYER, beloong$FLIGHT_LEVEL);
}
```

**设计意图（源码 Javadoc 原文）**：飞行等级系统需要一个梯级属性来控制飞行能力
（`< 0` 禁止飞行 / `= 0` 可飞不能悬停 / `>= 1` 完整飞行）。由于 DS 不可修改，属性通过两个注入点注册：
`<clinit>` RETURN 确保 DS 自身 `static final` 字段（如 `FLIGHT_SPEED`）已初始化完成；
`attachAttributes` TAIL 在 DS 把自身属性挂到 PLAYER 之后再追加。

**结论**：
- `dragonsurvival:flight_level` **不在 DS 模组里**（2.0.64 与 2.0.67 都没有），
  而是 BeLoong-Core 通过 mixin 注入到 `dragonsurvival` 命名空间下的属性。
  规格：`RangedAttribute`，base `0.0`，范围 `[-1024, 1024]`，`setSyncable(true)`，仅挂 `EntityType.PLAYER`。
- 因此数据包里那 12 个 `dragon_ability` 文件引用 `dragonsurvival:flight_level` **是合法的**，
  前提是 `beloong` 模组存在 —— 这是**硬前置依赖**。

**飞行等级的三档语义**（`ModAttributes#getFlightLevel` Javadoc 明确定义）：

| 等级 | 含义 |
|---|---|
| `< 0` | **禁止飞行**（`ToggleFlightMixin` 拒绝展翅） |
| `= 0` | 可飞行，**不可稳定悬停** |
| `>= 1` | 可飞行 + **稳定悬停** |

这个三档设计与数据包的 `lookup values [0,1,2,3,4,5]` 正好对齐 —— 注意 `values[0] = 0` 对应
能力等级 1（即"刚学会飞、还不会悬停"），不是"0 级"。详见 §5.3 的修正说明。

**附注（加载时序，已在 `neoforge.mods.toml` 验证）**：mixin 往 DS 的 `DeferredRegister` 里追加条目，
而该 register 的 `register(modEventBus)` 调用发生在 `BeLoongCore` 构造期。源码 Javadoc 说明了这个顺序依赖：

> BeLoong-Core 依赖 DS（`mods.toml` 声明），故 DS 先构造 → `DSAttributes` 类加载 →
> `<clinit>` 中本 Mixin 注入注册 → REGISTRY 提交到模组事件总线 → 属性进入全局注册表。

该依赖在 `BeLoong-Core/src/main/templates/META-INF/neoforge.mods.toml` 中确实存在：

```toml
[[dependencies.beloong]]
    modId="dragonsurvival"
    type="required"
    versionRange="[2.0.53,)"
    ordering="AFTER"      # ← 关键：BeLoong-Core 在 DS 之后加载
    side="BOTH"
```

- `ordering="AFTER"` 保证 `BeLoongCore` 构造前 DS 已完成注册 ⇒ `DSAttributes` 已类加载 ⇒
  mixin 在 `<clinit>` RETURN 追加的条目仍能赶上 `register(modEventBus)`。
- `versionRange="[2.0.53,)"` 说明**本套魔改的最低 DS 版本是 2.0.53**，
  而手头源码是 2.0.64、实例运行 2.0.67 —— 都在范围内。
- 运行时证据：`config/attributefix/dragonsurvival/flight_level.json` 确实存在，
  说明该属性在注册表里真实可用。

### 5.2 `ClientFlightHandlerMixin` —— 稳定悬停 + 等级化下坠

`@Inject(method = "flightControl", at = @At("TAIL"))`，三层早退保护后按等级分支：

| 状态 | `flightLevel >= 1` | `flightLevel < 1` |
|---|---|---|
| 水中 | 锁定当前高度（不缓慢下沉） | 不干预，保持 DS 原版 |
| 空中 | 清零水平加速度 = **稳定悬停**；创造模式额外清零垂直速度防上漂 | 追加额外重力（总重力达 `-(gravity×2)`），模拟鞘翅式下坠 |

前置守卫：`Config.FIX_STABLE_HOVER` 为假 → 完全不干预；
DS 自身 `ServerFlightHandler.stableHover` 为假 → 完全不干预（**尊重模组配置**）；
非龙玩家 / 翅膀未展开 / 无飞行能力 / 有操作输入 / 滑翔中 / 旋转中 → 早退。

⇒ `flight_level` 是**"悬停能力"的开关兼等级**，而**不是**"能不能飞"的开关（那由 `FlightEffect.level_requirement` 决定）。

### 5.3 `ToggleFlightMixin` —— 起飞门槛

```java
// BeLoong-Core: .../mixin/dragonsurvival/ToggleFlightMixin.java:49-53
if (!flight.areWingsSpread && ModAttributes.getFlightLevel(player) < 0.0) {
    // 返回 NONE 而非 WINGS_BLOCKED——NONE 在客户端不显示消息
    // WINGS_BLOCKED 的提示"翅膀被阻挡或损坏"对禁空场景语义不准确
    cir.setReturnValue(ToggleFlight.Result.NONE);
}
```

注入点选在 `context.enqueueWork` 的 lambda（`lambda$handleServer$1`）内，
**属性读取落在服务端主线程**，避免在网络线程读 attribute 的线程安全问题 —— 这个细节值得学习。

⇒ 只有 `flight_level < 0` 才禁止起飞。

> **⚠️ 修正我上一版文档的一处错误推理**：我此前写"数据包 `lookup` 的 `values[0] = 0.0`（0 级）
> 正好卡在门槛上方 … 逻辑自洽"。这句话只对了一半。正确的关系是：
>
> - `flight_level` 的 **base 是 0.0**，而 modifier **只在翅膀能力等级 ≥ 1 时才生效**
>   （`FlightEffect.apply` 只在 `ability.level() >= level_requirement(=1)` 时把 `hasFlight` 置真）。
>   能力 0 级时属性就是 base `0.0`。
> - 所以数据包的 `lookup values[0] = 0.0` 对应的是**能力等级 1**（`LevelBasedValue` 的 level 参数是
>   从 1 起算的能力等级），此时 `flight_level = 0` → **可飞、不可悬停**。
> - 能力等级 2 → `flight_level = 1` → **可飞 + 可悬停**。
>
> 也就是说：`lookup values = [0,1,2,3,4,5]` 的真实含义是"能力 1..6 级分别给 0..5 点飞行等级"，
> 与 `fallback: linear(base 0, per_level 1)` 在能力 7 级时给 6 点是连续的。
> 这个设计让"飞行等级"成为一个**独立于能力等级的可被外部削弱的量**
> （见 §5.7 的 `beloong:flight_ban`），是三档语义与"6 级翅膀"能咬合的关键。

### 5.4 `ModifierMixin` —— 修 tooltip 的 0 级数组越界

```java
// BeLoong-Core: .../mixin/dragonsurvival/ModifierMixin.java:18-26
@ModifyVariable(method = "getFormattedDescription", at = @At("HEAD"), argsOnly = true, index = 1)
private int beloong$clampTooltipLevel(int level) { return Math.max(1, level); }
```

源码 Javadoc 说明了**确切的崩溃原因**：DS 在渲染**未学习技能**的 Modifier 描述时会传入等级 0，
而 `LevelBasedValue.Lookup` 会执行 `values.get(-1)` ⇒ **数组越界崩溃**。
钳到 1 是因为 `LevelBasedValue` 的 level 从 1 起算，`values[0]` 对应 level 1。

同类修补还有 `DamageEffectMixin`（对 `DragonAbilityInstance.level()` 做同样钳制）。

> 这条对适配新从龙有直接指导意义：**如果你给技能写了 `lookup` 类型的 `amount`/`growth_requirement`，
> 就必须确认有对应的钳制保护**，否则玩家在技能面板里悬停到未学习的技能时会崩客户端。

### 5.5 `MixinDragonGrowthHandler` —— 引入 `beloong:growth_speed`

```java
@Redirect(method = "onPlayerUpdate",
          at = @At(value = "INVOKE", target = "...DragonStage;ticksToGrowth(I)D"), remap = false)
private static double redirectTicksToGrowth(DragonStage stage, int ticks, PlayerTickEvent.Pre event) {
    double baseGrowth = stage.ticksToGrowth(ticks);
    if (event.getEntity() instanceof ServerPlayer player) {
        AttributeInstance attr = player.getAttribute(ModAttributes.GROWTH_SPEED);
        if (attr != null) return baseGrowth * attr.getValue();
    }
    return baseGrowth;
}
```

配合 `ModAttributes.GROWTH_SPEED`（`beloong:growth_speed`，base `1.0`，范围 `[-1024, 1024]`）
⇒ **成长速度乘区**。这是数据包无法表达的能力（`dragon_stage` 只有固定 `ticks_until_grown`）。

下游消费者：`beloong:growth_acceleration` 状态效果每级给该属性 `+1.0`（ADD_VALUE）。

### 5.6 路径②：注册自定义能力效果类型（`beloong:air_strike` / `beloong:tp_loong_palace`）

DS 的 `ability_entity_effect` 是一个**代码注册表**，数据包只能引用、不能定义。
BeLoong-Core 用 `RegisterEvent` 扩展它：

```java
// BeLoong-Core: .../ability/AbilityEffectRegistry.java:16-25
@SubscribeEvent
static void registerEntityEffects(final RegisterEvent event) {
    if (event.getRegistry() == AbilityEntityEffect.REGISTRY) {
        event.register(AbilityEntityEffect.REGISTRY_KEY,
                ResourceLocation.fromNamespaceAndPath(BeLoongCore.MODID, "tp_loong_palace"),
                () -> TpLoongPalaceEffect.CODEC);
        event.register(AbilityEntityEffect.REGISTRY_KEY,
                ResourceLocation.fromNamespaceAndPath(BeLoongCore.MODID, "air_strike"),
                () -> AirStrikeEffect.CODEC);
    }
}
```

| 效果 id | 实现类 | 作用 |
|---|---|---|
| `beloong:air_strike` | `ability/AirStrikeEffect.java` | 滑翔中高速撞击：按速度 + 主副手武器攻击力 + `dragonsurvival:dragon_ability_damage` 算伤害，命中后强制收翅 |
| `beloong:tp_loong_palace` | `ability/TpLoongPalaceEffect.java` | 传送至龙宫维度 |

`AirStrikeEffect` 的 codec 值得注意 —— 它自定义了一个 `FLEXIBLE_LBV`：

```java
/** 同时支持纯数字和 LevelBasedValue 对象格式 */
private static final Codec<LevelBasedValue> FLEXIBLE_LBV = Codec.either(
        LevelBasedValue.CODEC, Codec.DOUBLE)
    .xmap(either -> either.map(lbv -> lbv, d -> LevelBasedValue.constant((float)(double)d)),
          Either::left);
```

⇒ 在 JSON 里 `"min_speed": 0.8`（裸数字）与
`"collision_size": {"type":"minecraft:linear", ...}`（对象）**都能解析**。
这正是 `BeLoong-Core/.../data/dragonsurvival/dragonsurvival/dragon_ability/air_strike.json` 的写法。

它也在 `getDescription` 里做了自己的 0 级钳制（**双重保险**，不完全依赖 `ModifierMixin`）：

```java
int level = Math.max(DragonAbilityInstance.MIN_LEVEL_FOR_CALCULATIONS, ability.level());
```

### 5.7 路径④：注册自定义状态效果（含飞行等级博弈）

```java
// BeLoong-Core: .../registry/ModMobEffects.java:65-84（节选）
public static final Holder<MobEffect> FLIGHT_BAN = REGISTRY.register("flight_ban", () -> {
    Attribute flightLevelAttr = BuiltInRegistries.ATTRIBUTE.get(
            ResourceLocation.fromNamespaceAndPath("dragonsurvival", "flight_level"));
    FlightBanEffect effect = new FlightBanEffect();
    if (flightLevelAttr != null) {
        effect.addAttributeModifier(BuiltInRegistries.ATTRIBUTE.wrapAsHolder(flightLevelAttr),
                ResourceLocation.fromNamespaceAndPath("beloong", "flight_ban"),
                -1.0, AttributeModifier.Operation.ADD_VALUE);
    }
    return effect;   // 属性未找到时仍注册但不带 modifier —— 安全降级
});
```

| 效果 | 机制 |
|---|---|
| `beloong:flight_ban` | 每级 `-1.0` 飞行等级（vanilla 自动按 `amount × (amplifier+1)` 缩放 ⇒ I 级 -1、II 级 -2、III 级 -3）。`FlightBanEffect.onEffectStarted` 中若 `areWingsSpread && flightLevel < 0` 则强制收翅 + 提示 |
| `beloong:growth_acceleration` | 每级 `+1.0` 到 `beloong:growth_speed` |
| `beloong:serene`（气定神闲） | 每级 `+0.004` 到 `dragonsurvival:mana_regeneration` |
| `beloong:mana_loss`（魔力流逝） | 本身无属性修正，每 tick 扣 `0.025 × (amplifier+1)` 法力（`ManaLossHandler`） |

**设计意图（`FlightBanEffect` Javadoc 原文）**：这是一个**博弈设计** ——
敌方/BOSS 可施加禁空来限制飞行，龙则通过升级翅膀技能反制：

- 禁空 I（amp 0）→ `-1` 飞行等级
- **翅膀技能等级 2（成年龙）提供 +1 飞行等级，可抵消 1 级禁空**

与 DS 原生 `BROKEN_WINGS` 的区别：`BROKEN_WINGS` 无条件强制收翅；
`flight_ban` 只在飞行等级降至负数时才收翅，从而保留"低等级禁空只能削弱悬停、不能阻止飞行"的梯度。

> 这就是 §5.3 那句"飞行等级是独立于能力等级、可被外部削弱的量"的**实际用途**：
> 数据包把翅膀能力的每级映射为 +1 飞行等级，`flight_ban` 再把它减回去，形成可对抗的数值博弈。
> **这是整套魔改里设计最精巧的一环，且完全无法用纯数据包实现。**

### 5.8 其余 DS 相关 mixin

| Mixin | 作用 |
|---|---|
| `DragonStateHandlerMixin` | 构造时把 `largeDragonDestruction` 默认设为 `DISABLED`（禁用大型龙破坏地形） |
| `ProjectileDamageEffectMixin` | 修复 owner 缺少 `dragonsurvival:dragon_ability_damage` 属性时弹射物伤害崩溃（受 `Config.FIX_DS_PROJECTILE_CRASH` 控制） |
| `DamageEffectMixin` | `getDescription` 中把 `ability.level()` 钳到 ≥1（同 §5.4） |
| `BlockBreakEffectMixin` / `BlockConversionEffectMixin` / `ExplodeBlockEffectMixin` / `FireEffectMixin` / `BlockHarvestEffectMixin` / `BonemealEffectMixin` | 技能方块效果相关修补 |
| `ClientFlightHandlerAccessor` | `@Accessor`，让 mixin 能读写 `ClientFlightHandler` 的静态累积加速度 `ax/ay/az` |
| `DragonDestructionHandlerMixin` / `TreasureBlockMixin` | 局部行为改写 |

---

## 六、对照 `龙之生存附属模组适配准则.md` 的偏差与补充

准则文档整体准确，以下是本次源码核对后需要**修正/补充**的点。

### 6.1 ❗准则 §2.2.2「飞行等级 `dragonsurvival:flight_level`」缺少前置说明与语义表

准则写「飞行等级 → `dragonsurvival:flight_level` → 0~5 级映射」，只给了"插入模板"，但**未说明该属性的来源**。

核对 BeLoong-Core 源码后确认，它由 `DSAttributesMixin`
（`BeLoong-Core/src/main/java/com/zonlong/beloong/mixin/dragonsurvival/DSAttributesMixin.java`）
**注入到 DS 的 `DSAttributes.REGISTRY`**，因而注册在 `dragonsurvival` 命名空间下。
规格：base `0.0`，范围 `[-1024, 1024]`，`setSyncable(true)`，仅挂 `EntityType.PLAYER`。

**建议准则补充以下两点**：

1. **前置依赖声明**：这批技能文件依赖 BeLoong-Core 模组；移除核心模组会让它们全部解析失败。
2. **三档语义表**（源码 `ModAttributes#getFlightLevel` Javadoc 明确定义）：

| 等级 | 含义 |
|---|---|
| `< 0` | 禁止飞行（`ToggleFlightMixin` 拒绝展翅） |
| `= 0` | 可飞行，不可稳定悬停 |
| `>= 1` | 可飞行 + 稳定悬停 |

3. **等级对应关系**（准则未提，但适配时最易搞错）：
   `lookup values[0]` 对应的是**能力等级 1**，不是 0 级 —— `LevelBasedValue` 的 level 参数从 1 起算。
   所以 `values = [0,1,2,3,4,5]` 表示"能力 1~6 级分别给 0~5 点飞行等级"，
   即**能力 2 级（成年龙）才首次获得稳定悬停**。

### 6.2 ❗准则 §2.2.2「飞行速度/耐力 基础 -0.2，每级 +0.1」的语义容易被误读

`flight_speed` / `flight_stamina` 在 DS 中的**注册 base 都是 `1`**（不是 `-0.2`）。
`base: -0.2` 是**这条 modifier 自身的基线**：`add_value` 时

```
final = 属性base(1) + Σ(add_value 修正)
```

- 技能等级 1（`linear` 在 level=1 取 `base`）→ `1 + (-0.2) = 0.8`（比无修正慢）
- 等级 6 → `1 + (-0.2 + 0.1*5) = 1.3`

所以「-0.2 起、每级 +0.1」是**相对修正量**的正确描述，但准则应写明**属性自身 base 为 1**，
否则会误以为 `-0.2` 是属性基线。

另外 `flight_stamina` 是**除数**（`drain /= stamina`），越大越省力，范围 0..5：
`-0.2 → ... → 1.3` 意味着**1 级时飞行更费饥饿、6 级时更省**。

### 6.3 ⚠️准则 §2.2.2「技能等级改为 6 级」未提 `dragon_stage` 的联动前提

改 `growth_requirement` 为 `[20,50,100,150,200,250]` 后，**必须同时把该物种的成长区间撑到 ≥250**，
否则 3 级以上永远不可达。建议准则补上「先确认 `custom_stage_progression` 的成长上限」。

### 6.4 ⚠️准则 §2.2.1 `diet_entries` 模板未提醒两个陷阱

1. `saturation` 会被 `FoodData.add()` **夹到新的 foodLevel**，`nutrition < saturation` 时饱和度被截断。
2. 覆盖条目必须**逐字保持 `items` 字符串一致**（`DietEntry.equals` 只比 `items`）。

### 6.5 ✅已确认正确的部分

- `dragon_beacon_data` 必含 `dragonsurvival:empowered_soul` —— 正确（压制龙魂冷却）。
- `end_platforms` 坐标不得重叠 —— 正确（`PlacedEndPlatforms` 按 structure id 判重）。
- `dragon_ability/order.json` 一般不动、`dragon_species/order.json` 必改 —— 正确（前者是能力界面排序，后者是祭坛顺序且未列入者排最后）。
- 新增技能在 `dragon_ability/<物种>.json` 底部追加 `become_bigger` / `become_smaller` —— 正确，且这两个技能是**化龙自制**（贴图在 `assets/dragonsurvival/textures/gui/sprites/abilities/beloong/`）。
- 「尊重原文件缩进、只在尾部追加」—— 正确且重要：数据包注册表条目是整体覆盖，标签是追加，
  两种语义下"最小改动"的具体做法不同。

### 6.6 📌准则未覆盖但实际存在的内容

| 内容 | 位置 | 说明 |
|---|---|---|
| 自定义身体 `dragon_body` | `dragonsurvival/dragon_body/*.json` | 准则只说"从龙不需要修改"，但化龙为以太龙/苔原龙人形新增了 |
| 自定义表情集 `dragon_emote_set` | `dragonsurvival/dragon_emote_set/*.json` | 准则写明"不需要修改"，实际有 2 个 |
| 自定义诅咒 `dragon_penalty` | `dragonsurvival/dragon_penalty/*.json` | 准则写"不需要修改"，实际新增 3 个 |
| 自定义 `dragon_ability`（引用自定义 `effect_type`） | `BeLoong-Core/src/main/resources/data/dragonsurvival/dragonsurvival/dragon_ability/air_strike.json`、`tp_loong_palace.json` | **注意位置在核心模组里，不在 KubeJS 里** |
| 龙之国度结构 / 战利品表 | `structure/netherlands/` + `loot_table/chests/` | 未在准则中出现 |
| 独立命名空间的从龙 | `kubejs/data/star_dragon/`、`wing_kirin/` | 准则 §3.1 有原则说明，但未给出完整文件清单 |

### 6.7 📌准则未覆盖：自定义 `effect_type` 只能由模组提供

准则只讨论"复制模组文件并改数值"，未说明**技能效果的类型集合是代码注册表**。
`effect_type` 的合法取值来自 DS 的 `AbilityEntityEffect.REGISTRY`（32 个 entity effect + 11 个 block effect），
**数据包不能新增**。若要新效果类型，必须写 Java 代码注册：

```java
event.register(AbilityEntityEffect.REGISTRY_KEY,
        ResourceLocation.fromNamespaceAndPath(BeLoongCore.MODID, "air_strike"),
        () -> AirStrikeEffect.CODEC);
```

相应地，这类技能 JSON 也应放在模组资源里（`BeLoong-Core/src/main/resources/data/...`），
而不是 KubeJS —— 因为 KubeJS 数据包与模组数据包的加载顺序/归属不同，
且自定义效果类与 JSON 应作为一个整体发布。

**判定规则**：技能 JSON 里出现 `"effect_type": "beloong:xxx"` ⇒ 放核心模组；
只用 `dragonsurvival:*` / `minecraft:*` ⇒ 放 KubeJS。

---

## 七、可复用的操作方法

### 7.1 判定覆盖 vs 新增（程序化，勿手工转录）

```powershell
# 注意：路径含全角括号/方括号时，用 -like 在 PowerShell 侧过滤，不要交给文件系统
$ov = 'D:\BeLoong\.minecraft\versions\BeLoong\kubejs\data\dragonsurvival\dragonsurvival'
$md = 'D:\Minecraft\开源模组参考文件\DragonSurvival\src\generated\resources\data\dragonsurvival\dragonsurvival'
foreach ($sub in 'dragon_ability','dragon_species','dragon_stage','dragon_penalty','dragon_body') {
  Get-ChildItem "$ov\$sub" -File -Filter *.json -ErrorAction SilentlyContinue | ForEach-Object {
    $s = if (Test-Path -LiteralPath "$md\$sub\$($_.Name)") { '覆盖模组' } else { '化龙新增' }
    "$sub/$($_.Name)  $s"
  }
}
```

> 注意：判定"是否覆盖模组"时，除了 DS 本体，还要把**附属模组的 jar** 一并作为比对基准
> （13 个从龙的物种文件其实覆盖的是各附属 mod）。核心模组 `BeLoong-Core` 的 `src/main/resources/data/`
> 也要纳入比对范围。

### 7.2 权威数据源必须是 jar，不是解压目录

DS 2.0.67 的打包 JSON 在 `mods\[龙之生存] DragonSurvival-*.jar` 内。解压 `.jar` 前先复制成 `.zip`
（`Expand-Archive` 不认 `.jar` 扩展名），或用 `System.IO.Compression.ZipFile` 直接读条目：

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
$z = [System.IO.Compression.ZipFile]::OpenRead($jarPath)
$e = $z.GetEntry('data/dragonsurvival/dragonsurvival/dragon_ability/cave_wings.json')
$sr = New-Object System.IO.StreamReader($e.Open()); $sr.ReadToEnd(); $sr.Close(); $z.Dispose()
```

### 7.3 查核心模组：**先读源码，不要反编译**

**BeLoong-Core 有完整源码：`D:\Minecraft\BeLoong-Core`**（`src/main/java/com/zonlong/beloong/`）。
其 Javadoc 为中文且详细记录了设计意图、注入点选择理由、加载顺序，
**信息量远高于反编译产物**。常规做法：

```powershell
# 查某个 DS 特性/ID 在核心模组里的来源
Get-ChildItem 'D:\Minecraft\BeLoong-Core\src\main\java' -Recurse -File -Filter *.java |
  Select-String -Pattern 'flight_level|getFlightLevel' |
  ForEach-Object { "$($_.Filename):$($_.LineNumber): $($_.Line.Trim())" }

# 查核心模组自带的数据包内容
Get-ChildItem 'D:\Minecraft\BeLoong-Core\src\main\resources\data' -Recurse -File
```

#### 兜底：反编译（仅在源码缺失/与 jar 不一致时使用）

`mods\beloong-0.9.3.jar` 可能与源码仓库有版本差。需要核对"实例里实际跑的是哪版"时才反编译：

```powershell
java -jar 'D:\Minecraft\闭源模组解压文件\以太龙\cfr.jar' `
     'D:\BeLoong\.minecraft\versions\BeLoong\mods\beloong-0.9.3.jar' `
     --extraclasspath 'D:\BeLoong\.minecraft\versions\BeLoong\mods\[龙之生存] DragonSurvival-1.21.1-v2.0.67-24.08.2026-all.jar' `
     --outputdir $env:TEMP\beloong_src
# 重点关注 com/zonlong/beloong/mixin/dragonsurvival/
```

也可只用字符串扫描快速确认某个属性/效果是否存在：

```powershell
$text = -join ($bytes | ForEach-Object { if ($_ -ge 32 -and $_ -lt 127) {[char]$_} else {"`n"} })
($text -split "`n") | Where-Object { $_ -match '^[a-z_]{4,}$' } | Sort-Object -Unique
```

---

## 八、后续适配新从龙的检查清单

基于以上分析，适配一个新从龙时按顺序核对：

1. **确定命名空间形态**（标准 / 独立 / 混合，准则 §3）。
2. **覆盖 `dragon_species/<id>.json`**：抄全附属原文件，追加 `mana_handling` + `unlockable_behavior`。
3. **确认成长区间**：`custom_stage_progression` 的最大成长是否 ≥ 最高技能等级所需值（§6.3）。
4. **覆盖 `*_wings.json`**：三段 modifier（`flight_level` / `flight_stamina` / `flight_speed`）+ 6 级 + 贴图复制。
   - `flight_level` 用 `lookup [0..5]`（能力 1 级→0 点，2 级→1 点即获得悬停，6 级→5 点）。
   - 必须确认 `beloong` 核心模组在位，否则该属性不存在。
   - 若技能用到 `lookup` 型 `amount`，确认 0 级 tooltip 有钳制保护（§5.4）。
5. **`diet_entries.json`**：追加通用食物 + 附属专属食物；注意 `saturation ≤ nutrition`。
6. **`dragon_beacon_data.json`**：至少 2~3 个效果，**必含 `dragonsurvival:empowered_soul`**。
7. **`end_platforms.json`**：坐标与其他物种**不重叠**；复用平台时同时复用坐标。
8. **`stage_resources.json`**：若附属未提供独立贴图，需要新增该物种条目。
9. **`dragon_ability/<物种>.json`**：抄全原列表 + 底部追加 `become_bigger` / `become_smaller`。
10. **`dragon_species/order.json`**：插入合适位置，`beginner_aether_dragon` 保持在最底部。
11. **语言文件**：中英各补齐 4 个键（`.locked` / `.altar.desc` / `.banner.desc` / 主键），按准则 §2.1.1 的 §颜色码格式。
12. **判断技能归属**：新技能的 `effect_type` 是否只用 `dragonsurvival:*` / `minecraft:*`？
    - 是 → JSON 放 `kubejs/data/`（第 1 层）
    - 否（如 `beloong:air_strike`）→ JSON 必须放 `BeLoong-Core/src/main/resources/data/`（第 2 层），见 §6.7
13. **验收**：进游戏后依次确认 —— 祭坛可见性与解锁条件、成长到满级、翅膀 6 级（含悬停何时解锁）、
    信标效果（付费与记忆方块两种模式）、末地平台、饮食 GUI、诅咒提示。

> **一句提醒**：第 3 步与第 4 步是**联动的**。只改 `growth_requirement` 而不改 `dragon_stage`，
> 高级技能永远解锁不了；只改 `dragon_stage` 而不改 `growth_requirement`，则成长经验被浪费。
> 两者必须一起核对。

---

## 九、关联文档

| 文档 | 内容 |
|---|---|
| **`D:\Minecraft\BeLoong-Core`** | **化龙核心模组源码（权威）**，中文 Javadoc 记录了全部设计意图 |
| `docs/龙之生存附属模组适配准则.md` | 从龙适配的官方流程与字段要求（本文件的对照基准） |
| `docs/plans/2026-09-13-dragonsurvival-datapack-override-reverse-engineering.md` | DS 数据驱动加载系统逐字段逆向报告（1825 行，含全部 codec 与行号） |
| `.claude/memory/learned-patterns.md` | 项目通用经验（覆盖语义、标签 `replace`、结构迁移等） |

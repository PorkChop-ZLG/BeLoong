# Dragon Survival 数据驱动内容加载系统 —— 逆向工程报告

> 分析对象：`D:\Minecraft\开源模组参考文件\DragonSurvival`
> 参考源码版本 `2.0.64`，MC `1.21.1`，NeoForge `21.1.241`（`gradle.properties`）
> 下文所有路径均为相对仓库根目录的路径。所有行号均来自实际读取的源文件。
>
> ⚠️ **版本注意（2026-09-13 补充）**：实例实际加载的是 **`DragonSurvival-1.21.1-v2.0.67`**
> （`mods\[龙之生存] DragonSurvival-1.21.1-v2.0.67-24.08.2026-all.jar`）。
> 本报告基于 2.0.64 源码。已抽样核对 2.0.67 jar 内的 `cave_wings.json` 与
> `DSAttributes.class` 常量池，**关键结论一致**。引用具体行号时请以 2.0.64 为参照并在 2.0.67 上复核。
>
> 另：`dragonsurvival:flight_level` 属性**并非由 DS 提供**，而是由化龙核心模组
> `beloong-0.9.3.jar` 通过 `DSAttributesMixin` 注入注册的 —— 详见
> `docs/plans/2026-09-13-dragonsurvival-kubejs-modding-guide.md`。
>
> **关于核心模组**：BeLoong-Core 有完整源码仓库 **`D:\Minecraft\BeLoong-Core`**
> （`mod_version=0.9.3`，中文 Javadoc 完整）。查询核心模组行为时**应优先读该源码**，
> 而不是反编译 `mods\beloong-0.9.3.jar`。本报告仅分析 DS 侧，不涉及核心模组。

---

## 0. 总体架构速览

Dragon Survival **没有使用 `AddReloadListenerEvent` / `SimpleJsonResourceReloadListener`**。
`grep -n "AddReloadListenerEvent|RegistryDataLoader"` 在 `src/main/java` 下**零命中**。

它完全依赖两条 NeoForge / 原版机制：

| 机制 | 用途 | 注册位置 |
|---|---|---|
| `DataPackRegistryEvent.NewRegistry#dataPackRegistry` | 5 个 datapack registry（ability / species / stage / penalty / body / emote_set / projectile_data，共 7 个） | 各 registry 主类内的 `@SubscribeEvent register(...)` |
| `RegisterDataMapTypesEvent` | 5 个 NeoForge DataMap | `registry/DSDataMaps.java:49-57` |
| 原版 `TagKey`（`data/<ns>/tags/dragonsurvival/...`） | 排序 / 物种分组 | `registry/datagen/tags/DSDragon*Tags.java` |

另外有若干**自定义 `NewRegistryEvent` 注册的子类型 registry**（`ability_entity_effect`、`activation`、`upgrade_type`、`ability_targeting`、`penalty_effect`、`penalty_trigger` 等），它们通过 `MapCodec` dispatch 字段做多态分派。

数据重载后的校验入口是 `TagsUpdatedEvent`：

`src/main/java/by/dragonsurvivalteam/dragonsurvival/common/handlers/DataReloadHandler.java:11-29`
```java
@EventBusSubscriber
public class DataReloadHandler {
    public static long lastReload;

    @SubscribeEvent
    public static void handleDatapackReload(final TagsUpdatedEvent event) {
        lastReload = System.currentTimeMillis();
        try {
            DragonStage.update(event.getRegistryAccess());
            DragonSpecies.validate(event.getRegistryAccess());
            DragonAbility.validate(event.getRegistryAccess());
        } catch (Exception e) {
            DragonSurvival.LOGGER.error("An error was thrown while trying to reload datapacks: {}", e.toString());
        }
    }
}
```

内置数据在 datagen 阶段写入 `src/generated/resources/data/dragonsurvival/dragonsurvival/<registry>/<id>.json`
（见 `registry/datagen/DataGeneration.java:134-145`，`RegistrySetBuilder` 注册内容）。

---

## 1. 注册 datapack registry 的类与行号

### 1.1 `DataPackRegistryEvent.NewRegistry`（datapack registry）

| registry id | 主类 | 字段声明 | `register` 方法 |
|---|---|---|---|
| `dragonsurvival:dragon_ability` | `DragonAbility` (record) | `registry/dragon/ability/DragonAbility.java:53` | `:168-171` |
| `dragonsurvival:dragon_species` | `DragonSpecies` | `registry/dragon/DragonSpecies.java:43` | `:108-111` |
| `dragonsurvival:dragon_stage` | `DragonStage` (record) | `registry/dragon/stage/DragonStage.java:50` | `:161-164` |
| `dragonsurvival:dragon_penalty` | `DragonPenalty` (record) | `registry/dragon/penalty/DragonPenalty.java:47` | `:110-113` |
| `dragonsurvival:dragon_body` | `DragonBody` (record) | `registry/dragon/body/DragonBody.java:59` | `:219-222` |
| `dragonsurvival:dragon_emote_set` | `DragonEmoteSet` (record) | `registry/dragon/body/emotes/DragonEmoteSet.java:21` | `:30-33` |
| `dragonsurvival:projectile_data` | `ProjectileData` (record) | `registry/projectile/ProjectileData.java:32` | `:42-45` |

示例（`registry/dragon/ability/DragonAbility.java:53,168-171`）：
```java
public static final ResourceKey<Registry<DragonAbility>> REGISTRY = ResourceKey.createRegistryKey(DragonSurvival.res("dragon_ability"));
...
@SubscribeEvent
public static void register(final DataPackRegistryEvent.NewRegistry event) {
    event.dataPackRegistry(REGISTRY, DIRECT_CODEC, DIRECT_CODEC);
}
```
> 注意：7 个 registry 都只传 `DIRECT_CODEC` 两次（第二个参数是 network codec），**没有传 `DataPackRegistryEvent#dataPackRegistry(..., Codec)` 之外的额外参数**；网络同步单独由 `CODEC = RegistryFixedCodec.create(REGISTRY)` + `STREAM_CODEC = ByteBufCodecs.holderRegistry(REGISTRY)` 承担。

### 1.2 自定义子类型 registry（`NewRegistryEvent`）

| registry id | 接口/类 | `REGISTRY` 构建 | 条目注册 |
|---|---|---|---|
| `dragonsurvival:ability_entity_effect` | `AbilityEntityEffect` | `registry/dragon/ability/entity_effects/AbilityEntityEffect.java:28-29` | `:63-98` |
| `dragonsurvival:ability_block_effect` | `AbilityBlockEffect` | `registry/dragon/ability/block_effects/AbilityBlockEffect.java:19,43` | 同文件 |
| `dragonsurvival:activation` | `Activation` | `registry/dragon/ability/activation/Activation.java:32-33` | `:42-48` |
| `dragonsurvival:upgrade_type` | `UpgradeType` | `registry/dragon/ability/upgrade/UpgradeType.java:34-35` | `:46-54` |
| `dragonsurvival:ability_targeting` | `AbilityTargeting` | `registry/dragon/ability/targeting/AbilityTargeting.java:44-45` | `:117-125` |
| `dragonsurvival:penalty_effect` | `PenaltyEffect` | `registry/dragon/penalty/PenaltyEffect.java:22-23` | `:40-52` |
| `dragonsurvival:penalty_trigger` | `PenaltyTrigger` | `registry/dragon/penalty/PenaltyTrigger.java:22-23` | `:49-57` |
| `dragonsurvival:activation_trigger` | `ActivationTrigger` | `registry/dragon/ability/activation/trigger/ActivationTrigger.java:11,25` | 同文件 |
| `dragonsurvival:projectile_entity_effect` | `ProjectileEntityEffect` | `registry/projectile/entity_effects/ProjectileEntityEffect.java:12,28` | 同文件 |
| `dragonsurvival:projectile_block_effect` | `ProjectileBlockEffect` | `registry/projectile/block_effects/ProjectileBlockEffect.java:12,28` | 同文件 |
| `dragonsurvival:projectile_world_effect` | `ProjectileWorldEffect` | `registry/projectile/world_effects/ProjectileWorldEffect.java:11,27` | 同文件 |
| `dragonsurvival:projectile_targeting` | `ProjectileTargeting` | `registry/projectile/targeting/ProjectileTargeting.java:23,81` | 同文件 |

dispatch 模式统一为：
```java
Codec<AbilityEntityEffect> CODEC = REGISTRY.byNameCodec().dispatch("effect_type", AbilityEntityEffect::entityCodec, Function.identity());
```
（`entity_effects/AbilityEntityEffect.java:31`）

### 1.3 DataMap（`RegisterDataMapTypesEvent`）

`registry/DSDataMaps.java:28-57`
```java
public static final AdvancedDataMapType<DragonSpecies, List<DietEntry>, DietEntryRemover> DIET_ENTRIES = AdvancedDataMapType.builder(DragonSurvival.res("diet_entries"), DragonSpecies.REGISTRY, DietEntry.CODEC.listOf())
        .merger(new DietEntryMerger()).remover(DietEntryRemover.CODEC).synced(DietEntry.CODEC.listOf(), true).build();

public static final AdvancedDataMapType<DragonSpecies, Map<ResourceKey<DragonStage>, StageResources.StageResource>, StageResourceRemover> STAGE_RESOURCES = AdvancedDataMapType.builder(DragonSurvival.res("stage_resources"), DragonSpecies.REGISTRY, StageResources.CODEC)
        .merger(DataMapValueMerger.mapMerger()).remover(StageResourceRemover.CODEC).synced(StageResources.CODEC, true).build();

public static final DataMapType<DragonSpecies, EndPlatform> END_PLATFORMS = DataMapType.builder(DragonSurvival.res("end_platforms"), DragonSpecies.REGISTRY, EndPlatform.CODEC).build();

public static final DataMapType<DragonSpecies, DragonBeaconData> DRAGON_BEACON_DATA = DataMapType.builder(DragonSurvival.res("dragon_beacon_data"), DragonSpecies.REGISTRY, DragonBeaconData.CODEC).build();

public static final AdvancedDataMapType<DragonBody, Map<ResourceKey<DragonSpecies>, ResourceLocation>, BodyIconRemover> BODY_ICONS = AdvancedDataMapType.builder(DragonSurvival.res("body_icons"), DragonBody.REGISTRY, BodyIcons.CODEC)
        .merger(DataMapValueMerger.mapMerger()).remover(BodyIconRemover.CODEC).synced(BodyIcons.CODEC, true).build();
```
DataMap JSON 路径：`data/<ns>/data_maps/dragonsurvival/<registry_path>/<data_map_id>.json`
（由 `grep DataMapProvider` 与生成物目录 `src/generated/resources/data/dragonsurvival/data_maps/dragonsurvival/dragon_species/*.json`、`.../dragon_body/body_icons.json` 证实）。

---

## 2. 各 JSON 类型的完整字段表

### 2.1 `dragon_ability/<id>.json`

Java 记录：`by.dragonsurvivalteam.dragonsurvival.registry.dragon.ability.DragonAbility`
文件 `registry/dragon/ability/DragonAbility.java:41-62`

```java
@EventBusSubscriber
public record DragonAbility(
        Activation activation,
        Optional<UpgradeType<?>> upgrade,
        Optional<LootItemCondition> usageBlocked,
        List<ActionContainer> actions,
        boolean canBeManuallyDisabled,
        LevelBasedResource icon
) {
    public static final Codec<DragonAbility> DIRECT_CODEC = RecordCodecBuilder.create(instance -> instance.group(
            Activation.CODEC.fieldOf("activation").forGetter(DragonAbility::activation),
            UpgradeType.CODEC.optionalFieldOf("upgrade").forGetter(DragonAbility::upgrade),
            MiscCodecs.conditional(LootItemCondition.DIRECT_CODEC).optionalFieldOf("usage_blocked").forGetter(DragonAbility::usageBlocked),
            ConditionalOps.decodeListWithElementConditions(ActionContainer.CODEC).optionalFieldOf("actions", List.of()).forGetter(DragonAbility::actions),
            Codec.BOOL.optionalFieldOf("can_be_manually_disabled", true).forGetter(DragonAbility::canBeManuallyDisabled),
            LevelBasedResource.CODEC.fieldOf("icon").forGetter(DragonAbility::icon)
    ).apply(instance, instance.stable(DragonAbility::new)));
```

| JSON 字段 | Java 类型 | 必需 | 默认 |
|---|---|---|---|
| `activation` | `Activation`（多态，见 2.1.1） | ✅ | — |
| `upgrade` | `UpgradeType<?>`（多态，见 2.1.3） | ❌ | `Optional.empty()` |
| `usage_blocked` | `LootItemCondition`（可带 `neoforge:conditions`，见 §6） | ❌ | `Optional.empty()` |
| `actions` | `List<ActionContainer>`（每个元素可带 `neoforge:conditions`） | ❌ | `List.of()` |
| `can_be_manually_disabled` | `boolean` | ❌ | `true` |
| `icon` | `LevelBasedResource` | ✅ | — |

**注意**：没有 `mana_cost` / `cooldown` / `range` / `duration` / `type` / `effect_type` 这些顶层字段！
`mana_cost` / `cooldown` / `cast_time` 全部在 `activation` 内部；`range` 在 targeting 内部；`duration` 在具体 effect 内部；`effect_type` 是**每个 action effect 对象自己的 dispatch 字段**。

#### 2.1.1 `activation` —— `Activation` 多态

`registry/dragon/ability/activation/Activation.java:32-35`
```java
public static final ResourceKey<Registry<MapCodec<? extends Activation>>> REGISTRY_KEY = ResourceKey.createRegistryKey(DragonSurvival.res("activation"));
Registry<MapCodec<? extends Activation>> REGISTRY = new RegistryBuilder<>(REGISTRY_KEY).create();

Codec<Activation> CODEC = REGISTRY.byNameCodec().dispatch("activation_type", Activation::codec, Function.identity());
```
已注册 id（`Activation.java:42-48`）：

| `activation_type` | 实现类 | 文件 |
|---|---|---|
| `dragonsurvival:passive` | `PassiveActivation` | `registry/dragon/ability/activation/PassiveActivation.java` |
| `dragonsurvival:simple` | `SimpleActivation` | `.../SimpleActivation.java` |
| `dragonsurvival:channeled` | `ChanneledActivation` | `.../ChanneledActivation.java` |

`SimpleActivation`（`SimpleActivation.java:11-32`）：
```java
public record SimpleActivation(
        Optional<LevelBasedValue> initialManaCost,
        Optional<LevelBasedValue> castTime,
        Optional<LevelBasedValue> cooldown,
        Notification notification,
        boolean canMoveWhileCasting,
        Optional<Sound> sound,
        Optional<Animations> animations
) implements Activation {
    public static final MapCodec<SimpleActivation> CODEC = RecordCodecBuilder.mapCodec(instance -> instance.group(
            LevelBasedValue.CODEC.optionalFieldOf("initial_mana_cost").forGetter(SimpleActivation::initialManaCost),
            LevelBasedValue.CODEC.optionalFieldOf("cast_time").forGetter(SimpleActivation::castTime),
            LevelBasedValue.CODEC.optionalFieldOf("cooldown").forGetter(SimpleActivation::cooldown),
            Notification.CODEC.optionalFieldOf("notification", Notification.DEFAULT).forGetter(SimpleActivation::notification),
            Codec.BOOL.optionalFieldOf("can_move_while_casting", true).forGetter(SimpleActivation::canMoveWhileCasting),
            Sound.CODEC.validate(sound -> sound.looping().isPresent() ? DataResult.error(() -> "Simple activation does not support [looping] sounds") : DataResult.success(sound)).optionalFieldOf("sound").forGetter(SimpleActivation::sound),
            Animations.CODEC.validate(animations -> animations.looping().isPresent() ? DataResult.error(() -> "Simple activation does not support [looping] animations") : DataResult.success(animations)).optionalFieldOf("animations").forGetter(SimpleActivation::animations)
    ).apply(instance, SimpleActivation::new));
```
字段表（`simple`）：

| JSON 字段 | Java 类型 | 必需 | 默认 |
|---|---|---|---|
| `initial_mana_cost` | `LevelBasedValue` | ❌ | 空 → 0 |
| `cast_time` | `LevelBasedValue`（tick） | ❌ | 空 → 0 |
| `cooldown` | `LevelBasedValue`（tick） | ❌ | 空 → 0 |
| `notification` | `Notification` | ❌ | `Notification.DEFAULT` |
| `can_move_while_casting` | `boolean` | ❌ | `true` |
| `sound` | `Sound`（**禁止 `looping`**） | ❌ | 空 |
| `animations` | `Animations`（**禁止 `looping`**） | ❌ | 空 |

`ChanneledActivation`（`ChanneledActivation.java:12-35`）额外有 `continuous_mana_cost`（只允许 `ticking`）与 `max_duration`，并且 `sound`/`animations` 的 `looping` 是允许的：

| JSON 字段 | Java 类型 | 必需 | 默认 |
|---|---|---|---|
| `initial_mana_cost` | `LevelBasedValue` | ❌ | 空 |
| `continuous_mana_cost` | `ManaCost`（`type` 必须为 `ticking`，否则 decode 报错） | ❌ | 空 |
| `cast_time` | `LevelBasedValue` | ❌ | 空 |
| `cooldown` | `LevelBasedValue` | ❌ | 空 |
| `max_duration` | `LevelBasedValue` | ❌ | 空（→永不超时） |
| `notification` | `Notification` | ❌ | `Notification.DEFAULT` |
| `can_move_while_casting` | `boolean` | ❌ | `true` |
| `sound` | `Sound` | ❌ | 空 |
| `animations` | `Animations` | ❌ | 空 |

`PassiveActivation`（`PassiveActivation.java:12-21`）：
```java
public record PassiveActivation(Optional<ManaCost> continuousManaCost, Optional<LevelBasedValue> cooldown, ActivationTrigger trigger) implements Activation {
    public static final PassiveActivation DEFAULT = new PassiveActivation(Optional.empty(), Optional.empty(), ConstantTrigger.INSTANCE);

    public static final MapCodec<PassiveActivation> CODEC = RecordCodecBuilder.mapCodec(instance -> instance.group(
            ManaCost.CODEC.optionalFieldOf("continuous_mana_cost").forGetter(PassiveActivation::continuousManaCost),
            LevelBasedValue.CODEC.optionalFieldOf("cooldown").forGetter(PassiveActivation::cooldown),
            ActivationTrigger.CODEC.optionalFieldOf("trigger", ConstantTrigger.INSTANCE).forGetter(PassiveActivation::trigger)
    ).apply(instance, PassiveActivation::new));
```
| JSON 字段 | Java 类型 | 必需 | 默认 |
|---|---|---|---|
| `continuous_mana_cost` | `ManaCost` | ❌ | 空 |
| `cooldown` | `LevelBasedValue` | ❌ | 空 |
| `trigger` | `ActivationTrigger`（多态） | ❌ | `ConstantTrigger.INSTANCE` |

#### 2.1.2 `ManaCost` / `Sound` / `Animations`

`common/codecs/ability/ManaCost.java:10-14`
```java
public record ManaCost(ManaCostType manaCostType, LevelBasedValue manaCost) {
    public static final Codec<ManaCost> CODEC = RecordCodecBuilder.create(instance -> instance.group(
            ManaCostType.CODEC.fieldOf("type").forGetter(ManaCost::manaCostType),
            LevelBasedValue.CODEC.fieldOf("amount").forGetter(ManaCost::manaCost)
    ).apply(instance, ManaCost::new));
```
`ManaCostType` 取值：`ticking`、`reserved`（`ManaCost.java:24-28`）。
所以 `mana_cost` 的 JSON 形态是 `{"type":"ticking","amount":<LevelBasedValue>}`。

`registry/.../activation/Sound.java:18-25`
```java
public record Sound(Optional<SoundEvent> start, Optional<SoundEvent> charging, Optional<SoundEvent> looping, Optional<SoundEvent> end) {
    public static final Codec<Sound> CODEC = RecordCodecBuilder.create(instance -> instance.group(
            BuiltInRegistries.SOUND_EVENT.byNameCodec().optionalFieldOf("start").forGetter(Sound::start),
            BuiltInRegistries.SOUND_EVENT.byNameCodec().optionalFieldOf("charging").forGetter(Sound::charging),
            BuiltInRegistries.SOUND_EVENT.byNameCodec().optionalFieldOf("looping").forGetter(Sound::looping),
            BuiltInRegistries.SOUND_EVENT.byNameCodec().optionalFieldOf("end").forGetter(Sound::end)
    ).apply(instance, Sound::new));
```
全部可选，无默认值（`Optional.empty()`）。

`registry/.../activation/Animations.java:18-27`
```java
public record Animations(
        Optional<Either<CompoundAbilityAnimation, SimpleAbilityAnimation>> startAndCharging,
        Optional<SimpleAbilityAnimation> looping,
        Optional<SimpleAbilityAnimation> end
) {
    public static final Codec<Animations> CODEC = RecordCodecBuilder.create(instance -> instance.group(
            Codec.either(CompoundAbilityAnimation.CODEC, SimpleAbilityAnimation.CODEC).optionalFieldOf("start_and_charging").forGetter(Animations::startAndCharging),
            SimpleAbilityAnimation.CODEC.optionalFieldOf("looping").forGetter(Animations::looping),
            SimpleAbilityAnimation.CODEC.optionalFieldOf("end").forGetter(Animations::end)
    ).apply(instance, Animations::new));
```

#### 2.1.3 `upgrade` —— `UpgradeType` 多态

`registry/dragon/ability/upgrade/UpgradeType.java:34-59`
```java
ResourceKey<Registry<MapCodec<? extends UpgradeType<?>>>> REGISTRY_KEY = ResourceKey.createRegistryKey(DragonSurvival.res("upgrade_type"));
Registry<MapCodec<? extends UpgradeType<?>>> REGISTRY = new RegistryBuilder<>(REGISTRY_KEY).create();

Codec<UpgradeType<?>> CODEC = REGISTRY.byNameCodec().dispatch("upgrade_type", UpgradeType::codec, Function.identity());
...
static <V extends UpgradeType<?>> Products.P1<RecordCodecBuilder.Mu<V>, Integer> codecStart(final RecordCodecBuilder.Instance<V> instance) {
    return instance.group(ExtraCodecs.intRange(DragonAbilityInstance.MIN_LEVEL, DragonAbilityInstance.MAX_LEVEL).fieldOf("maximum_level").forGetter(UpgradeType::maxLevel));
}
```
已注册 id（`UpgradeType.java:46-54`）：

| `upgrade_type` | 实现类 | 额外字段 |
|---|---|---|
| `dragonsurvival:experience_points` | `ExperiencePointsUpgrade` | `maximum_level`(int, 0..255) + `experience_cost`(`LevelBasedValue`) |
| `dragonsurvival:experience_levels` | `ExperienceLevelUpgrade` | `maximum_level` + `level_requirement`(`LevelBasedValue`) |
| `dragonsurvival:dragon_growth` | `DragonGrowthUpgrade` | `maximum_level` + `growth_requirement`(`LevelBasedValue`) |
| `dragonsurvival:item_based` | `ItemUpgrade` | `items_per_level`(`List<HolderSet<Item>>`) + `downgrade_items`(`HolderSet<Item>`) —— **无 `maximum_level`** |
| `dragonsurvival:condition_based` | `ConditionUpgrade` | `conditions`(`List<LootItemCondition>`) + `require_previous`(bool, 默认 `true`) —— **无 `maximum_level`** |

逐条 codec：
- `ExperiencePointsUpgrade.java:17-23`：`UpgradeType.codecStart(instance).and(LevelBasedValue.CODEC.fieldOf("experience_cost")...)`；`maxLevel()` 由 `maximum_level` 提供。
- `ExperienceLevelUpgrade.java:12-18`：`level_requirement`。
- `DragonGrowthUpgrade.java:12-18`：`growth_requirement`。
- `ItemUpgrade.java:17-21`：`RegistryCodecs.homogeneousList(Registries.ITEM).listOf().fieldOf("items_per_level")`、`...fieldOf("downgrade_items")`。
- `ConditionUpgrade.java:19-23`：`LootItemCondition.DIRECT_CODEC.listOf().fieldOf("conditions")`、`Codec.BOOL.optionalFieldOf("require_previous", true)`。

`DragonAbilityInstance`（`registry/dragon/ability/DragonAbilityInstance.java:42-46`）：
```java
public static final int MIN_LEVEL = 0;
public static final int MIN_LEVEL_FOR_CALCULATIONS = 1;
public static final int MAX_LEVEL = 255;
```
`dragonsurvival:condition_based` 实例（`src/generated/.../dragon_ability/sea_spin.json:34-49`）：
```json
"upgrade": {
  "conditions": [ { "condition": "minecraft:entity_properties", "entity": "this", "predicate": { "type_specific": { "type": "dragonsurvival:dragon_predicate", "spin_was_granted": true } } } ],
  "require_previous": false,
  "upgrade_type": "dragonsurvival:condition_based"
}
```

#### 2.1.4 `actions` —— `ActionContainer` + `AbilityTargeting`

`common/codecs/ability/ActionContainer.java:12-17`
```java
public record ActionContainer(AbilityTargeting effect, TriggerPoint triggerPoint, LevelBasedValue triggerRate) {
    public static final Codec<ActionContainer> CODEC = RecordCodecBuilder.create(instance -> instance.group(
            AbilityTargeting.CODEC.fieldOf("target_selection").forGetter(ActionContainer::effect),
            TriggerPoint.CODEC.optionalFieldOf("trigger_point", TriggerPoint.DEFAULT).forGetter(ActionContainer::triggerPoint),
            LevelBasedValue.CODEC.optionalFieldOf("trigger_rate", LevelBasedValue.constant(1)).forGetter(ActionContainer::triggerRate)
    ).apply(instance, ActionContainer::new));
```
`TriggerPoint`：`default` / `charging` / `channel_completion`（`ActionContainer.java:34-39`）。

`AbilityTargeting` dispatch（`registry/dragon/ability/targeting/AbilityTargeting.java:44-47`）：
```java
ResourceKey<Registry<MapCodec<? extends AbilityTargeting>>> REGISTRY_KEY = ResourceKey.createRegistryKey(DragonSurvival.res("ability_targeting"));
Registry<MapCodec<? extends AbilityTargeting>> REGISTRY = new RegistryBuilder<>(REGISTRY_KEY).create();

Codec<AbilityTargeting> CODEC = REGISTRY.byNameCodec().dispatch("target_type", AbilityTargeting::codec, Function.identity());
```
已注册 `target_type`（`AbilityTargeting.java:117-125`）：

| `target_type` | 实现类 |
|---|---|
| `dragonsurvival:area` | `AreaTarget` |
| `dragonsurvival:dragon_breath` | `DragonBreathTarget` |
| `dragonsurvival:looking_at` | `LookingAtTarget` |
| `dragonsurvival:self` | `SelfTarget` |
| `dragonsurvival:disc` | `DiscTarget` |

`applied_effects` 是 `Either<BlockTargeting, EntityTargeting>`（`AbilityTargeting.java:73-109`）：
```java
record BlockTargeting(Optional<LootItemCondition> targetConditions, List<AbilityBlockEffect> effects) {
    public static final Codec<BlockTargeting> CODEC = RecordCodecBuilder.create(instance -> instance.group(
            MiscCodecs.conditional(LootItemCondition.DIRECT_CODEC).optionalFieldOf("target_conditions").forGetter(BlockTargeting::targetConditions),
            ConditionalOps.decodeListWithElementConditions(AbilityBlockEffect.CODEC).fieldOf("block_effect").forGetter(BlockTargeting::effects)
    ).apply(instance, BlockTargeting::new));
}
record EntityTargeting(Optional<LootItemCondition> targetConditions, List<AbilityEntityEffect> effects, TargetingMode targetingMode, boolean isHarmful) {
    public static final Codec<EntityTargeting> CODEC = RecordCodecBuilder.create(instance -> instance.group(
            MiscCodecs.conditional(LootItemCondition.DIRECT_CODEC).optionalFieldOf("target_conditions").forGetter(EntityTargeting::targetConditions),
            ConditionalOps.decodeListWithElementConditions(AbilityEntityEffect.CODEC).fieldOf("entity_effect").forGetter(EntityTargeting::effects),
            TargetingMode.CODEC.fieldOf("targeting_mode").forGetter(EntityTargeting::targetingMode),
            Codec.BOOL.optionalFieldOf("is_harmful", false).forGetter(EntityTargeting::isHarmful)
    ).apply(instance, EntityTargeting::new));
}
static <T extends AbilityTargeting> Products.P1<...> codecStart(...) {
    return instance.group(Codec.either(BlockTargeting.CODEC, EntityTargeting.CODEC).fieldOf("applied_effects").forGetter(AbilityTargeting::target));
}
```

#### 2.1.5 `effect_type` —— 每一个已注册的 ability effect id

`effect_type` 是 **entity effect** 的分派字段；**block effect** 的分派字段请见 `block_effects/AbilityBlockEffect.java`（同一接口模式）。
完整登记表（`registry/dragon/ability/entity_effects/AbilityEntityEffect.java:66-97`）：

| id | 实现类 |
|---|---|
| `dragonsurvival:damage` | `DamageEffect` |
| `dragonsurvival:modifier` | `ModifierEffect` |
| `dragonsurvival:potion` | `PotionEffect` |
| `dragonsurvival:projectile` | `ProjectileEffect` |
| `dragonsurvival:summon_entity` | `SummonEntityEffect`（`common_effects/`） |
| `dragonsurvival:damage_modification` | `DamageModificationEffect` |
| `dragonsurvival:breath_particles` | `BreathParticlesEffect` |
| `dragonsurvival:ignite` | `IgniteEffect` |
| `dragonsurvival:harvest_bonus` | `HarvestBonusEffect` |
| `dragonsurvival:on_attack` | `OnAttackEffect` |
| `dragonsurvival:flight` | `FlightEffect` |
| `dragonsurvival:spin` | `SpinEffect` |
| `dragonsurvival:item_conversion` | `ItemConversionEffect` |
| `dragonsurvival:swim` | `SwimEffect` |
| `dragonsurvival:effect_modification` | `EffectModificationEffect` |
| `dragonsurvival:particle` | `ParticleEffect`（`common_effects/`） |
| `dragonsurvival:glow` | `GlowEffect` |
| `dragonsurvival:oxygen_bonus` | `OxygenBonusEffect` |
| `dragonsurvival:block_vision` | `BlockVisionEffect` |
| `dragonsurvival:run_function` | `RunFunctionEffect`（`common_effects/`） |
| `dragonsurvival:smelting` | `SmeltItemEffect` |
| `dragonsurvival:heal` | `HealEffect` |
| `dragonsurvival:teleport` | `TeleportEffect` |
| `dragonsurvival:push` | `PushEffect` |
| `dragonsurvival:hunger` | `HungerEffect` |
| `dragonsurvival:effect_removal` | `MobEffectRemovalEffect` |
| `dragonsurvival:use_item` | `UseItemOnLivingEntityEffect` |
| `dragonsurvival:dragon_growth` | `DragonGrowthEffect` |
| `dragonsurvival:mana_recovery` | `ManaRecoveryEffect` |
| `dragonsurvival:experience` | `ExperienceEffect` |
| `dragonsurvival:cooldown_recovery` | `CooldownRecoveryEffect` |
| `dragonsurvival:climbable` | `ClimbEffect` |

> **修正一处常见误解**：`dragonsurvival:modifier` 的实体是 `ModifierEffect`，它内部再嵌套
> `ModifierWithDuration`（`common/codecs/ModifierWithDuration.java:44-47`）：
> ```java
> public static final Codec<ModifierWithDuration> CODEC = RecordCodecBuilder.create(instance -> instance.group(
>         DurationInstanceBase.CODEC.fieldOf("base").forGetter(identity -> identity),
>         Modifier.CODEC.listOf().fieldOf("modifiers").forGetter(ModifierWithDuration::modifiers)
> ).apply(instance, ModifierWithDuration::new));
> ```
> 没有 `dragonsurvival:modifier_with_duration` 这种 id。

节选一个最具代表性的（`registry/dragon/ability/entity_effects/DamageEffect.java:30-39`）：
```java
public record DamageEffect(Holder<DamageType> damageType, LevelBasedValue amount, Holder<Attribute> scale, Expression expression, boolean useClaw) implements AbilityEntityEffect {
    public static final Expression DEFAULT_EXPRESSION = new Expression("amount * scale");

    public static final MapCodec<DamageEffect> CODEC = RecordCodecBuilder.mapCodec(instance -> instance.group(
            DamageType.CODEC.fieldOf("damage_type").forGetter(DamageEffect::damageType),
            LevelBasedValue.CODEC.fieldOf("amount").forGetter(DamageEffect::amount),
            Attribute.CODEC.optionalFieldOf("scale", DSAttributes.DRAGON_ABILITY_DAMAGE).forGetter(DamageEffect::scale),
            MiscCodecs.expressionCodec("amount", "scale").optionalFieldOf("expression", DEFAULT_EXPRESSION).forGetter(DamageEffect::expression),
            Codec.BOOL.optionalFieldOf("use_claw", false).forGetter(DamageEffect::useClaw)
    ).apply(instance, DamageEffect::new));
```
`ProjectileEffect`（`entity_effects/ProjectileEffect.java:58-70`）：
```java
ProjectileData.CODEC.optionalFieldOf("projectile_data").forGetter(ProjectileEffect::projectileData),
BuiltInRegistries.ENTITY_TYPE.holderByNameCodec().optionalFieldOf("projectile_type").forGetter(ProjectileEffect::projectileType),
TargetDirection.CODEC.fieldOf("target_direction").forGetter(ProjectileEffect::targetDirection),
LevelBasedValue.CODEC.fieldOf("number_of_projectiles").forGetter(ProjectileEffect::numberOfProjectiles),
LevelBasedValue.CODEC.optionalFieldOf("projectile_spread", LevelBasedValue.constant(0)).forGetter(ProjectileEffect::projectileSpread),
LevelBasedValue.CODEC.fieldOf("speed").forGetter(ProjectileEffect::speed)
// .validate：projectile_data 与 projectile_type 至少给一个
```
`PotionEffect`（`entity_effects/PotionEffect.java:14-17`）只有一个 `potion` 字段，指向 `PotionData`：
```java
public record PotionEffect(PotionData potion) implements AbilityEntityEffect {
    public static final MapCodec<PotionEffect> CODEC = RecordCodecBuilder.mapCodec(instance -> instance.group(
            PotionData.CODEC.fieldOf("potion").forGetter(PotionEffect::potion)
    ).apply(instance, PotionEffect::new));
```
`PotionData`（`common/codecs/PotionData.java:35-52`）：
```java
public record PotionData(
        HolderSet<MobEffect> effects,
        LevelBasedValue amplifier,
        LevelBasedValue duration,
        LevelBasedValue probability,
        boolean effectParticles,
        boolean showIcon
) {
    public static final MapCodec<PotionData> CODEC = RecordCodecBuilder.mapCodec(instance -> instance.group(
            RegistryCodecs.homogeneousList(BuiltInRegistries.MOB_EFFECT.key()).fieldOf("effects").forGetter(PotionData::effects),
            LevelBasedValue.CODEC.fieldOf("amplifier").forGetter(PotionData::amplifier),
            LevelBasedValue.CODEC.fieldOf("duration").forGetter(PotionData::duration),
            LevelBasedValue.CODEC.optionalFieldOf("probability", DEFAULT_PROBABILITY).forGetter(PotionData::probability),
            Codec.BOOL.optionalFieldOf("effect_particles", false).forGetter(PotionData::effectParticles),
            Codec.BOOL.optionalFieldOf("show_icon", true).forGetter(PotionData::showIcon)
    ).apply(instance, PotionData::new));
```

#### 2.1.5b 若干 `effect_type` 的逐字段 codec（人工核对）

`FlightEffect`（`registry/dragon/ability/entity_effects/FlightEffect.java:24-31`）
```java
public record FlightEffect(int levelRequirement, ResourceLocation icon) implements AbilityEntityEffect {
    public static final MapCodec<FlightEffect> CODEC = RecordCodecBuilder.mapCodec(instance -> instance.group(
            Codec.INT.fieldOf("level_requirement").forGetter(FlightEffect::levelRequirement),
            ResourceLocation.CODEC.optionalFieldOf("icon", FlightData.DEFAULT_ICON).forGetter(FlightEffect::icon)
    ).apply(instance, FlightEffect::new));
```
→ `level_requirement`(int, 必需)、`icon`(`ResourceLocation`, 默认 `FlightData.DEFAULT_ICON`)。**这是“解锁飞行”的唯一数据来源**（`data.hasFlight = ability.level() >= levelRequirement`，`:42`）。

`SpinEffect`（`entity_effects/SpinEffect.java:27-34`）
```java
public record SpinEffect(int levelRequirement, Optional<HolderSet<FluidType>> fluidTypes) implements AbilityEntityEffect {
    public static final MapCodec<SpinEffect> CODEC = RecordCodecBuilder.mapCodec(instance -> instance.group(
            Codec.INT.fieldOf("level_requirement").forGetter(SpinEffect::levelRequirement),
            RegistryCodecs.homogeneousList(NeoForgeRegistries.Keys.FLUID_TYPES).optionalFieldOf("fluid_types").forGetter(SpinEffect::fluidTypes)
    ).apply(instance, SpinEffect::new));
```
→ `level_requirement`(int, 必需)、`fluid_types`(`HolderSet<FluidType>`, 可选；示例 `sea_spin.json:9` 写 `"minecraft:water"`)。

`HealEffect`（`entity_effects/HealEffect.java:20-26`）：`percentage`(`LevelBasedValue`, 必需)。

`TeleportEffect`（`entity_effects/TeleportEffect.java:24-37`）：`target_direction`(`TargetDirection`, 必需)、`range`(`LevelBasedValue`, 必需；Java 字段名叫 `maxDistance`)。

`TargetDirection`（`common/codecs/TargetDirection.java:10-13`）
```java
public record TargetDirection(Either<Type, Direction> direction) {
    public static final Codec<TargetDirection> CODEC = RecordCodecBuilder.create(instance -> instance.group(
            Codec.either(Type.CODEC, Direction.CODEC).fieldOf("direction").forGetter(TargetDirection::direction)
    ).apply(instance, TargetDirection::new));
```
→ `direction` 可以是 `towards_entity` / `looking_at`（`Type` 枚举，`:27-31`），或一个原版 `Direction`（`north`/`south`/`east`/`west`/`up`/`down`）。示例 `ball_lightning.json:12-14`：`"target_direction": {"direction": "looking_at"}`。

**未出现过**：`dragonsurvival:dragon_breath` 之外，`target_type` 共 5 个；`TargetingMode`（`targeting/AbilityTargeting.java:88` 的 `targeting_mode`，枚举 `targeting/TargetingMode.java:25-45`）取值：
`all`、`allies`、`allies_and_self`、`non_allies`、`non_enemies`、`neutral`、`enemies`、`items`、`experience_orbs`、`all_except_self`。
匹配逻辑在 `TargetingMode.isEntityRelevant(ServerPlayer, Entity, boolean isHarmful)`（`:66-96`），并受服务端配置 `abilities.player_targeting_handling`（位标志 1=always ally / 2=always enemy / 4=safe in team）影响（`:47-57, 145-147`）。

已核对的 targeting codec：

| `target_type` | 字段 | 源码 |
|---|---|---|
| `dragonsurvival:area` | `applied_effects`(`Either<BlockTargeting,EntityTargeting>`, 必需) + `radius`(`LevelBasedValue`, 必需) | `targeting/AreaTarget.java:20-29` |
| `dragonsurvival:self` | 只有 `applied_effects` | `targeting/SelfTarget.java:15-19` |

`ActivationTrigger` 的 dispatch 字段是 **`trigger_type`**（`registry/dragon/ability/activation/trigger/ActivationTrigger.java:22`），已注册 id（`:32-39`）：
| `trigger_type` | 实现类 |
|---|---|
| `dragonsurvival:constant` | `ConstantTrigger` |
| `dragonsurvival:on_self_hit` | `OnSelfHit` |
| `dragonsurvival:on_target_hit` | `OnTargetHit` |
| `dragonsurvival:on_target_killed` | `OnTargetKilled` |
| `dragonsurvival:on_death` | `OnDeath` |
| `dragonsurvival:on_block_break` | `OnBlockBreak` |
| `dragonsurvival:on_key_pressed` | `OnKeyPressed` |
| `dragonsurvival:on_key_released` | `OnKeyReleased` |

#### 2.1.5c `applied_effects` 在 JSON 中的两种形态（真实生成物）

实体分支（`sea_spin.json:4-16`）：
```json
"target_selection": {
  "applied_effects": {
    "entity_effect": [ { "effect_type": "dragonsurvival:spin", "fluid_types": "minecraft:water", "level_requirement": 1 } ],
    "targeting_mode": "allies_and_self"
  },
  "target_type": "dragonsurvival:self"
}
```
块分支用 `"block_effect": [ ... ]` 而不是 `"entity_effect"`（`BlockTargeting.CODEC` 的字段名，`AbilityTargeting.java:76`）。

#### 2.1.6 `block_effect` —— 每一个已注册的 block effect id

`block_effect` 的分派字段同样是 **`effect_type`**（`registry/dragon/ability/block_effects/AbilityBlockEffect.java:32`）：
```java
Codec<AbilityBlockEffect> CODEC = REGISTRY.byNameCodec().dispatch("effect_type", AbilityBlockEffect::blockCodec, Function.identity());
```
已注册 id（`AbilityBlockEffect.java:50-60`）：

| id | 实现类 |
|---|---|
| `dragonsurvival:bonemeal` | `BonemealEffect` |
| `dragonsurvival:conversion` | `BlockConversionEffect` |
| `dragonsurvival:summon_entity` | `SummonEntityEffect`（与 entity effect 共用同一个 MapCodec） |
| `dragonsurvival:fire` | `FireEffect` |
| `dragonsurvival:area_cloud` | `AreaCloudEffect` |
| `dragonsurvival:block_break` | `BlockBreakEffect` |
| `dragonsurvival:particle` | `ParticleEffect`（与 entity effect 共用） |
| `dragonsurvival:run_function` | `RunFunctionEffect`（与 entity effect 共用） |
| `dragonsurvival:use_item` | `UseItemOnBlockEffect` |
| `dragonsurvival:explosion` | `ExplodeBlockEffect` |
| `dragonsurvival:block_harvest` | `BlockHarvestEffect` |

`SummonEntityEffect`（`common_effects/SummonEntityEffect.java:89-100`）同时实现 `AbilityEntityEffect` 与 `AbilityBlockEffect`，其 `effect_type` 的 JSON 形态为：
```java
public static final MapCodec<SummonEntityEffect> CODEC = RecordCodecBuilder.mapCodec(instance -> instance.group(
        DurationInstanceBase.CODEC.fieldOf("base").forGetter(identity -> identity),
        Codec.either(
                SimpleWeightedRandomList.wrappedCodec(BuiltInRegistries.ENTITY_TYPE.byNameCodec()),
                RegistryCodecs.homogeneousList(Registries.ENTITY_TYPE)
        ).fieldOf("entities").forGetter(SummonEntityEffect::entities),
        LevelBasedValue.CODEC.fieldOf("max_summons").forGetter(SummonEntityEffect::maxSummons),
        AttributeScale.CODEC.listOf().optionalFieldOf("attribute_scales", List.of()).forGetter(SummonEntityEffect::attributeScales),
        CompoundTag.CODEC.optionalFieldOf("nbt").forGetter(SummonEntityEffect::nbt),
        Codec.BOOL.optionalFieldOf("is_allied", true).forGetter(SummonEntityEffect::isAllied)
).apply(instance, SummonEntityEffect::new));
```
→ 注意所有继承 `DurationInstanceBase` 的效果都有共同的 `base` 子对象（`common/codecs/duration_instance/DurationInstanceBase.java:20-27`）：
```java
DurationInstanceBase.CODEC = RecordCodecBuilder.create(instance -> instance.group(
        ResourceLocation.CODEC.fieldOf("id").forGetter(DurationInstanceBase::id),
        LevelBasedValue.CODEC.optionalFieldOf("duration", DragonAbilities.INFINITE_DURATION).forGetter(DurationInstanceBase::duration),
        Codec.BOOL.optionalFieldOf("should_remove_automatically", false).forGetter(DurationInstanceBase::shouldRemoveAutomatically),
        LootItemCondition.DIRECT_CODEC.optionalFieldOf("early_removal_condition").forGetter(DurationInstanceBase::earlyRemovalCondition),
        ResourceLocation.CODEC.optionalFieldOf("custom_icon").forGetter(DurationInstanceBase::customIcon),
        Codec.BOOL.optionalFieldOf("is_hidden", false).forGetter(DurationInstanceBase::isHidden)
).apply(instance, DurationInstanceBase::new));
```
（`id` 必需；`duration` 默认 `DragonAbilities.INFINITE_DURATION`；其余可选/带默认。）

#### 2.1.7 主类中的运行时校验

`DragonAbility.validate(RegistryAccess)`（`DragonAbility.java:75-100`）在每次 datapack reload 时执行：
- PASSIVE activation 的 action 不允许非 `DEFAULT` 的 `trigger_point`；
- 非 `CHANNELED` activation 不允许 `CHANNEL_COMPLETION` 的 `trigger_point`。
失败抛 `IllegalStateException`（被 `DataReloadHandler` catch 并 log）。

---

### 2.2 `dragon_species/<id>.json`

Java 类：`registry/dragon/DragonSpecies.java`（**class，不是 record**，但提供 record 风格的访问器）
`DragonSpecies.java:43-54`
```java
public static final ResourceKey<Registry<DragonSpecies>> REGISTRY = ResourceKey.createRegistryKey(DragonSurvival.res("dragon_species"));

public static final Codec<DragonSpecies> DIRECT_CODEC = RecordCodecBuilder.create(instance -> instance.group(
        MiscCodecs.doubleRange(1, Double.MAX_VALUE).optionalFieldOf("starting_growth").forGetter(DragonSpecies::startingGrowth),
        UnlockableBehavior.CODEC.optionalFieldOf("unlockable_behavior").forGetter(DragonSpecies::unlockableBehavior),
        ManaHandling.CODEC.optionalFieldOf("mana_handling", ManaHandling.DEFAULT).forGetter(DragonSpecies::manaHandling),
        RegistryCodecs.homogeneousList(DragonStage.REGISTRY).optionalFieldOf("custom_stage_progression").forGetter(DragonSpecies::stages),
        RegistryCodecs.homogeneousList(DragonBody.REGISTRY).optionalFieldOf("bodies", HolderSet.empty()).forGetter(DragonSpecies::bodies),
        RegistryCodecs.homogeneousList(DragonAbility.REGISTRY).optionalFieldOf("abilities", HolderSet.empty()).forGetter(DragonSpecies::abilities),
        RegistryCodecs.homogeneousList(DragonPenalty.REGISTRY).optionalFieldOf("penalties", HolderSet.empty()).forGetter(DragonSpecies::penalties),
        MiscResources.CODEC.fieldOf("misc_resources").forGetter(DragonSpecies::miscResources)
).apply(instance, instance.stable(DragonSpecies::new)));
```

| JSON 字段 | Java 类型 | 必需 | 默认 |
|---|---|---|---|
| `starting_growth` | `double`（校验范围 `[1, Double.MAX_VALUE]`） | ❌ | 空 → 取最小 stage 的 `growth_range.min` |
| `unlockable_behavior` | `UnlockableBehavior` | ❌ | 空 → 无解锁条件、立即解锁 |
| `mana_handling` | `ManaHandling` | ❌ | `ManaHandling.DEFAULT` = `(0.1, 0.25, 9)` |
| `custom_stage_progression` | `HolderSet<DragonStage>`（注册表列表 / `#tag`） | ❌ | 空 → 使用所有 `is_default=true` 的 stage |
| `bodies` | `HolderSet<DragonBody>` | ❌ | `HolderSet.empty()` |
| `abilities` | `HolderSet<DragonAbility>` | ❌ | `HolderSet.empty()` |
| `penalties` | `HolderSet<DragonPenalty>` | ❌ | `HolderSet.empty()` |
| `misc_resources` | `MiscResources` | ✅ | — |

> **没有** `growth`、`stages`、`start_stage`、`type`、`name` 这些字段。
> `stages` 在 Java 里只是 `customStageProgression` 的**访问器名**（`DragonSpecies.java:209-211`），JSON 字段名是 `custom_stage_progression`。
> 起始 stage 由 `getStartingStage()` 根据 `starting_growth` 反查（`DragonSpecies.java:189-195`）：
> ```java
> public Holder<DragonStage> getStartingStage(@Nullable final HolderLookup.Provider provider) {
>     return DragonStage.get(getStages(provider), getStartingGrowth(provider));
> }
> ```

`UnlockableBehavior`（`common/codecs/UnlockableBehavior.java:18-35`）
```java
public record UnlockableBehavior(Optional<LootItemCondition> unlockCondition, Optional<Visibility> visibility) {
    public static final Codec<UnlockableBehavior> CODEC = RecordCodecBuilder.create(instance -> instance.group(
            LootItemCondition.DIRECT_CODEC.optionalFieldOf("unlock_condition").forGetter(UnlockableBehavior::unlockCondition),
            Visibility.CODEC.optionalFieldOf("visibility").forGetter(UnlockableBehavior::visibility)
    ).apply(instance, UnlockableBehavior::new));
}
```
`visibility` 枚举：`ALWAYS_VISIBLE` / `ALWAYS_HIDDEN` / `VISIBLE_IF_LOCKED`，序列化名是 `name().toLowerCase(ENGLISH)`（`UnlockableBehavior.java:24-34`）。

**`unlock_condition` 的解析机制**：它就是一个**原版 `LootItemCondition.DIRECT_CODEC`**，因此支持全部原版条件 id（`minecraft:entity_properties`、`minecraft:all_of`、`minecraft:any_of`、`minecraft:inverted`、`minecraft:random_chance`、`minecraft:location_check` …）。
DS 额外通过 `DSSubPredicates` 向 `BuiltInRegistries.ENTITY_SUB_PREDICATE_TYPE` 注册了 3 个 `type_specific` 子谓词（`registry/DSSubPredicates.java:15-21`）：
```java
public static final DeferredRegister<MapCodec<? extends EntitySubPredicate>> REGISTRY = DeferredRegister.create(BuiltInRegistries.ENTITY_SUB_PREDICATE_TYPE, DragonSurvival.MODID);
static {
    REGISTRY.register("dragon_predicate", () -> DragonPredicate.CODEC);
    REGISTRY.register("entity_check_predicate", () -> EntityCheckPredicate.CODEC);
    REGISTRY.register("custom_predicates", () -> CustomPredicates.CODEC);
}
```
即 `type_specific.type` 可用值：
- `dragonsurvival:dragon_predicate` → `common/codecs/predicates/DragonPredicate.java:42-52`
  | 字段 | 类型 | 说明 |
  |---|---|---|
  | `dragon_species` | `HolderSet<DragonSpecies>` | |
  | `stage_specific` | `DragonStagePredicate` | 见下 |
  | `dragon_body` | `HolderSet<DragonBody>` | |
  | `ability_levels` | `List<AbilityLevel>` | `{ability, level}`，`level` 是 `MinMaxBounds.Ints` |
  | `is_growth_stopped` | bool | |
  | `marked_by_ender_dragon` | bool | |
  | `flight_was_granted` | bool | |
  | `spin_was_granted` | bool | |
  | `is_flying` | bool | |
  全部可选。`DragonStagePredicate`（`predicates/DragonStagePredicate.java:14-19`）：`dragon_stage`(`HolderSet<DragonStage>`)、`growth_percentage`(`MinMaxBounds.Doubles`, 必须 0..1)、`growth`(`MinMaxBounds.Doubles`)。
- `dragonsurvival:entity_check_predicate` → `EntityCheckPredicate`，字段 `check_for`，枚举：`living_entity`、`enemy`、`tamed`、`animal`、`item`、`experience_orb`（`predicates/EntityCheckPredicate.java:24-34`）。
- `dragonsurvival:custom_predicates` → `CustomPredicates`（`predicates/CustomPredicates.java:44-54`）
  | 字段 | 类型 |
  |---|---|
  | `eye_in_fluid` | `HolderSet<FluidType>` |
  | `weather_predicate` | `WeatherPredicate`（`is_raining`/`is_thundering`/`is_snowing`/`is_raining_or_snowing`） |
  | `sun_light_level` | `MinMaxBounds.Ints` |
  | `has_duration_effect` | `ResourceLocation` |
  | `is_nearby_entity` | `NearbyEntityPredicate` |
  | `player_hunger` | `MinMaxBounds.Ints` |
  | `health_percentage` | `MinMaxBounds.Doubles` |
  | `has_uuid` | `UUID`（`UUIDUtil.LENIENT_CODEC`） |
  | `looking_at_block` | `{predicate: BlockPredicate, distance: double}` |

`ManaHandling`（`common/codecs/ManaHandling.java:6-14`）
```java
public record ManaHandling(double manaXpConversion, double manaPerLevel, double maxManaFromLevels) {
    public static final ManaHandling DEFAULT = new ManaHandling(0.1, 0.25, 9);
    public static final ManaHandling NONE = new ManaHandling(0, 0, 0);

    public static final Codec<ManaHandling> CODEC = RecordCodecBuilder.create(instance -> instance.group(
            MiscCodecs.doubleRange(0, Double.MAX_VALUE).optionalFieldOf("mana_xp_conversion", 0d).forGetter(ManaHandling::manaXpConversion),
            MiscCodecs.doubleRange(0, Double.MAX_VALUE).optionalFieldOf("mana_per_level", 0d).forGetter(ManaHandling::manaPerLevel),
            MiscCodecs.doubleRange(0, Double.MAX_VALUE).optionalFieldOf("max_mana_from_levels", 0d).forGetter(ManaHandling::maxManaFromLevels)
    ).apply(instance, ManaHandling::new));
}
```
| JSON 字段 | 类型 | 默认 |
|---|---|---|
| `mana_xp_conversion` | double ≥0 | `0` |
| `mana_per_level` | double ≥0 | `0` |
| `max_mana_from_levels` | double ≥0 | `0` |

`MiscResources`（`common/codecs/MiscResources.java:14-41`）
| JSON 字段 | Java 类型 | 必需 | 默认 |
|---|---|---|---|
| `food_sprites` | `ResourceLocation` | ❌ | 空 |
| `mana_sprites` | `ManaSprites`（`full`/`reserved`/`recovery`/`empty`，全必需） | ❌ | 空 |
| `altar_banner` | `ResourceLocation` | ✅ | — |
| `ability_bar` | `ResourceLocation`（字段名不是 `cast_bar`） | ✅ | — |
| `growth_left_arrow` | `HoverIcon`（`hover_icon`+`icon`） | ❌ | `HoverIcon.DEFAULT_LEFT` |
| `growth_right_arrow` | `HoverIcon` | ❌ | `HoverIcon.DEFAULT_RIGHT` |
| `growth_crystal` | `FillIcon`（`empty`+`full`） | ✅ | — |
| `food_tooltip` | `FoodTooltip`（`font`(默认 `dragonsurvival:food_tooltip_icon_font`)、`nutrition_icon`、`saturation_icon`、`color`） | ✅ | — |
| `primary_color` | `TextColor` | ✅ | — |
| `secondary_color` | `TextColor` | ✅ | — |
| `claw_texture_slot` | `ClawInventoryData.Slot` | ❌ | `PICKAXE` |
| `custom_growth_info` | `Component` | ❌ | 空 |

`DragonSpecies.validate`（`DragonSpecies.java:88-106`）：若定义了 `custom_stage_progression`，则调用 `DragonStage.areStagesConnected(...)` 校验 stage 链是否首尾相连（`max` 必须等于下一段 `min`）。

实际生成物 `src/generated/resources/data/dragonsurvival/dragonsurvival/dragon_species/cave_dragon.json`：
```json
{
  "abilities": "#dragonsurvival:cave_dragon",
  "misc_resources": { ... },
  "penalties": "#dragonsurvival:cave_dragon"
}
```
可见 `abilities` / `penalties` 直接用 tag 引用（`#namespace:path`）。

---

### 2.3 `dragon_stage/<id>.json`

`registry/dragon/stage/DragonStage.java:41-60`
```java
public record DragonStage(
        boolean isDefault,
        MiscCodecs.Bounds growthRange,
        int ticksUntilGrown,
        List<Modifier> modifiers,
        List<GrowthItem> growthItems,
        Optional<EntityPredicate> isNaturalGrowthStopped,
        Optional<MiscCodecs.DestructionData> destructionData
) implements AttributeModifierSupplier {
    public static final Codec<DragonStage> DIRECT_CODEC = RecordCodecBuilder.create(instance -> instance.group(
            Codec.BOOL.optionalFieldOf("is_default", false).forGetter(DragonStage::isDefault),
            MiscCodecs.bounds().fieldOf("growth_range").forGetter(DragonStage::growthRange),
            ExtraCodecs.intRange(1, Functions.daysToTicks(365)).fieldOf("ticks_until_grown").forGetter(DragonStage::ticksUntilGrown),
            Modifier.CODEC.listOf().optionalFieldOf("modifiers", List.of()).forGetter(DragonStage::modifiers),
            GrowthItem.CODEC.listOf().optionalFieldOf("growth_items", List.of()).forGetter(DragonStage::growthItems),
            EntityPredicate.CODEC.optionalFieldOf("is_natural_growth_stopped").forGetter(DragonStage::isNaturalGrowthStopped),
            MiscCodecs.DestructionData.CODEC.optionalFieldOf("destruction_data").forGetter(DragonStage::destructionData)
    ).apply(instance, instance.stable(DragonStage::new)));
```

| JSON 字段 | Java 类型 | 必需 | 默认 |
|---|---|---|---|
| `is_default` | boolean | ❌ | `false` |
| `growth_range` | `{min,max}`（`bounds()` 校验：`min>=1` 且 `max>min`） | ✅ | — |
| `ticks_until_grown` | int，范围 `[1, daysToTicks(365)]` | ✅ | — |
| `modifiers` | `List<Modifier>` | ❌ | `[]` |
| `growth_items` | `List<GrowthItem>` | ❌ | `[]` |
| `is_natural_growth_stopped` | `EntityPredicate` | ❌ | 空 |
| `destruction_data` | `MiscCodecs.DestructionData` | ❌ | 空 |

**没有** `growth_range` 之外的 `upgrade` / `next_stage` 字段；stage 的“链接”完全靠**数值区间首尾相接**（`areStagesConnected`，`DragonStage.java:131-140`）：
```java
public static boolean areStagesConnected(final HolderSet<DragonStage> sortedStages, final StringBuilder error, boolean isForDefaultStages) {
    for (int i = 0; i < sortedStages.size() - 1; i++) {
        if (sortedStages.get(i).value().growthRange().max() != sortedStages.get(i + 1).value().growthRange().min()) {
            ...
            return false;
        }
    }
    return true;
}
```
`get(HolderSet, growth)` 用 `growthRange().matches(growth) && max != growth` 选择当前 stage（故意排除区间右端点，以便落在边界时进入下一 stage），见 `DragonStage.java:189-213`。
`ticksToGrowth` / `getProgress` / `getTimeToGrowFormatted` 用线性比例从 `growth_range` 与 `ticks_until_grown` 推算（`DragonStage.java:153-159, 272-297`）。

`growth_items` 单元 `GrowthItem`（`common/codecs/GrowthItem.java:16-23`）：
```java
public record GrowthItem(HolderSet<Item> items, int growthInTicks, int maximumUsages) {
    public static final int INFINITE_USAGES = -1;

    public static final Codec<GrowthItem> CODEC = RecordCodecBuilder.create(instance -> instance.group(
            RegistryCodecs.homogeneousList(Registries.ITEM).fieldOf("items").forGetter(GrowthItem::items),
            Codec.INT.fieldOf("growth_in_ticks").forGetter(GrowthItem::growthInTicks),
            ExtraCodecs.intRange(INFINITE_USAGES, Integer.MAX_VALUE).optionalFieldOf("maximum_usages", INFINITE_USAGES).forGetter(GrowthItem::maximumUsages)
    ).apply(instance, instance.stable(GrowthItem::new)));
}
```
| JSON 字段 | 类型 | 必需 | 默认 |
|---|---|---|---|
| `items` | `HolderSet<Item>`（id 或 `#tag`） | ✅ | — |
| `growth_in_ticks` | int（**可为负**，`-72000` 用于 `star_bone` 缩小体型） | ✅ | — |
| `maximum_usages` | int ≥ -1 | ❌ | `-1`（无限） |

`modifiers` 单元 `Modifier`（`common/codecs/Modifier.java:16-32`）：
```java
public record Modifier(Holder<Attribute> attribute, Either<LevelBasedValue, PreciseLevelBasedValue> amount, AttributeModifier.Operation operation) {
    public static final Codec<Modifier> CODEC = RecordCodecBuilder.create(instance -> instance.group(
            Attribute.CODEC.fieldOf("attribute").forGetter(Modifier::attribute),
            Codec.either(LevelBasedValue.CODEC, PreciseLevelBasedValue.CODEC).fieldOf("amount").forGetter(Modifier::amount),
            AttributeModifier.Operation.CODEC.fieldOf("operation").forGetter(Modifier::operation)
    ).apply(instance, Modifier::new));

    public record PreciseLevelBasedValue(float base, float amount) {
        public static final Codec<PreciseLevelBasedValue> CODEC = RecordCodecBuilder.create(instance -> instance.group(
                Codec.FLOAT.fieldOf("precise_base").forGetter(PreciseLevelBasedValue::base),
                Codec.FLOAT.fieldOf("precise_amount").forGetter(PreciseLevelBasedValue::amount)
        ).apply(instance, PreciseLevelBasedValue::new));
        public double calculate(double level) { return base + amount * level; }
    }
}
```
| JSON 字段 | 类型 | 必需 | 默认 |
|---|---|---|---|
| `attribute` | `Attribute`（注册表 id） | ✅ | — |
| `amount` | `LevelBasedValue` **或** `{precise_base, precise_amount}` | ✅ | — |
| `operation` | `AttributeModifier.Operation`（`add_value`/`add_multiplied_base`/`add_multiplied_total`） | ✅ | — |

`destruction_data`（`common/codecs/MiscCodecs.java:138-145`）：`entity_predicate`、`block_predicate`、`crushing_growth`、`block_destruction_growth`、`crushing_damage_scalar`（全部必需）。
`DragonStage.validate`（`DragonStage.java:79-127`）要求 `newborn`/`young`/`adult` 三个内置 stage 必须存在，且 `destruction_data` 的两个 growth 必须落在本 stage `growth_range` 内。

内置 stage：`registry/dragon/stage/DragonStages.java:23-29`（`newborn`/`young`/`adult`，`is_default=true`）。

---

### 2.4 `dragon_penalty/<id>.json`

`registry/dragon/penalty/DragonPenalty.java:34-48`
```java
public record DragonPenalty(Optional<ResourceLocation> icon, Optional<LootItemCondition> condition, PenaltyEffect effect, PenaltyTrigger trigger) {
    public static final Codec<DragonPenalty> DIRECT_CODEC = RecordCodecBuilder.create(instance -> instance.group(
            ResourceLocation.CODEC.optionalFieldOf("icon").forGetter(DragonPenalty::icon),
            MiscCodecs.conditional(LootItemCondition.DIRECT_CODEC).optionalFieldOf("condition").forGetter(DragonPenalty::condition),
            PenaltyEffect.CODEC.fieldOf("effect").forGetter(DragonPenalty::effect),
            PenaltyTrigger.CODEC.fieldOf("trigger").forGetter(DragonPenalty::trigger)
    ).apply(instance, DragonPenalty::new));
}
```
| JSON 字段 | Java 类型 | 必需 | 默认 |
|---|---|---|---|
| `icon` | `ResourceLocation` | ❌ | 空 |
| `condition` | `LootItemCondition`（可带 `neoforge:conditions`） | ❌ | 空 → 条件恒真 |
| `effect` | `PenaltyEffect`（多态，`penalty_type`） | ✅ | — |
| `trigger` | `PenaltyTrigger`（多态，`penalty_trigger`） | ✅ | — |

`effect` 的 dispatch 字段是 **`penalty_type`**（`PenaltyEffect.java:25`）；`trigger` 的 dispatch 字段是 **`penalty_trigger`**（`PenaltyTrigger.java:25`）。

`penalty_type`（`PenaltyEffect.java:40-52`）：

| id | 实现类 | 字段 |
|---|---|---|
| `dragonsurvival:take_damage` | `DamagePenalty` | `damage_type`(`Holder<DamageType>`)、`amount`(`float`)（`DamagePenalty.java:18-21`） |
| `dragonsurvival:mob_effect` | `MobEffectPenalty` | `potion`(`PotionData`)（`MobEffectPenalty.java:11-13`） |
| `dragonsurvival:item_blacklist` | `ItemBlacklistPenalty` | `items`(`List<String>`, 默认 `[]`, 支持 `#tag`/正则)、`predicate`(`ItemPredicate`)（`ItemBlacklistPenalty.java:29-32`） |
| `dragonsurvival:damage_modification` | `DamageModificationPenalty` | `modification`(`DamageModification`)、`duration`(int ≥ -1)（`DamageModificationPenalty.java:16-20`） |
| `dragonsurvival:fear` | `FearPenalty` | `fears`(`List<Fear>`)（`FearPenalty.java:17-19`） |
| `dragonsurvival:informational` | `InformationalPenalty` | 无字段（`MapCodec.unit`，`InformationalPenalty.java:9`） |
| `dragonsurvival:modifier` | `ModifierPenalty` | `modifiers`(`List<ModifierWithDuration>`)（`ModifierPenalty.java:15-17`） |
| `dragonsurvival:effect_modification` | `EffectModificationPenalty` | `modifications`(`List<EffectModification>`)（`EffectModificationPenalty.java:15-17`） |
| `dragonsurvival:run_function` | `RunFunctionPenalty` | `function`(`ResourceLocation`)（`RunFunctionPenalty.java:14-16`） |

`penalty_trigger`（`PenaltyTrigger.java:49-57`）：

| id | 实现类 | 字段 |
|---|---|---|
| `dragonsurvival:supply` | `SupplyTrigger` | `supply_type`(`ResourceLocation`)、`attribute`(`Holder<Attribute>`, 默认 `dragonsurvival:penalty_resistance_time`)、`trigger_rate`(int ≥1)、`reduction_rate`(float)、`regeneration_rate`(float)、`recovery_items`(`List<RecoveryItem>`, 默认 `[]`)、`display_like_hunger_bar`(bool, 默认 `false`)、`particles_on_trigger`(`ParticleOptions`)（`SupplyTrigger.java:45-54`） |
| `dragonsurvival:instant` | `InstantTrigger` | `trigger_rate`(int)（`InstantTrigger.java:9-11`） |
| `dragonsurvival:item_used` | `ItemUsedTrigger` | `item_predicates`(`List<ItemPredicate>`)（`ItemUsedTrigger.java:12-14`） |
| `dragonsurvival:hit_by_projectile` | `HitByProjectileTrigger` | `projectiles`(`HolderSet<EntityType<?>>`)（`HitByProjectileTrigger.java:12-14`） |
| `dragonsurvival:hit_by_water_potion` | `HitByWaterPotionTrigger` | 无字段（`MapCodec.unit`，`HitByWaterPotionTrigger.java:8`） |

`SupplyTrigger.RecoveryItem`：`item_predicates`(`List<ItemPredicate>`)、`percent_restored`(float)（`SupplyTrigger.java:56-60`）。

生成的 `dragon_penalty/water_weakness.json`：
```json
{
  "condition": { "condition": "minecraft:all_of", "terms": [ ... ] },
  "effect": { "amount": 1.0, "damage_type": "dragonsurvival:water_burn", "penalty_type": "dragonsurvival:take_damage" },
  "icon": "dragonsurvival:penalties/cave/water_weakness",
  "trigger": { "penalty_trigger": "dragonsurvival:instant", "trigger_rate": 10 }
}
```

---

### 2.5 `dragon_body/<id>.json`

`registry/dragon/body/DragonBody.java:41-95`
```java
public record DragonBody(
        boolean isDefault,
        Optional<UnlockableBehavior> unlockableBehavior,
        List<Modifier> modifiers,
        boolean canHideWings,
        ResourceLocation model,
        TextureSize textureSize,
        ResourceLocation animation,
        Optional<ResourceLocation> defaultIcon,
        List<String> bonesToHideForToggle,
        Holder<DragonEmoteSet> emotes,
        ScalingProportions scalingProportions,
        double crouchHeightRatio,
        Optional<BackpackOffsets> backpackOffsets,
        double betterCombatWeaponOffset,
        boolean noDragonModelRendering,
        boolean rideable
) implements AttributeModifierSupplier {
    private static final Codec<DragonBody> MODEL_CODEC = RecordCodecBuilder.create(instance -> instance.group(
            Codec.BOOL.optionalFieldOf("is_default", false).forGetter(DragonBody::isDefault),
            UnlockableBehavior.CODEC.optionalFieldOf("unlockable_behavior").forGetter(DragonBody::unlockableBehavior),
            Modifier.CODEC.listOf().fieldOf("modifiers").forGetter(DragonBody::modifiers),
            Codec.BOOL.optionalFieldOf("can_hide_wings", true).forGetter(DragonBody::canHideWings),
            ResourceLocation.CODEC.optionalFieldOf("model", DEFAULT_MODEL).forGetter(DragonBody::model),
            TextureSize.CODEC.optionalFieldOf("texture_size", DEFAULT_TEXTURE_SIZE).forGetter(DragonBody::textureSize),
            ResourceLocation.CODEC.fieldOf("animation").forGetter(DragonBody::animation),
            ResourceLocation.CODEC.optionalFieldOf("default_icon").forGetter(DragonBody::defaultIcon),
            Codec.STRING.listOf().optionalFieldOf("bones_to_hide_for_toggle", List.of("WingLeft", "WingRight", "SmallWingLeft", "SmallWingRight")).forGetter(DragonBody::bonesToHideForToggle),
            DragonEmoteSet.CODEC.fieldOf("emotes").forGetter(DragonBody::emotes),
            ScalingProportions.CODEC.fieldOf("scaling_proportions").forGetter(DragonBody::scalingProportions),
            MiscCodecs.doubleRange(0, 100).fieldOf("crouch_height_ratio").forGetter(DragonBody::crouchHeightRatio),
            BackpackOffsets.CODEC.optionalFieldOf("backpack_offset").forGetter(DragonBody::backpackOffsets),
            Codec.DOUBLE.optionalFieldOf("bettercombat_weapon_offset", 0d).forGetter(DragonBody::betterCombatWeaponOffset),
            Codec.BOOL.optionalFieldOf("rideable", true).forGetter(DragonBody::rideable)
    ).apply(instance, instance.stable(DragonBody::new)));

    private static final Codec<DragonBody> NO_MODEL_CODEC = RecordCodecBuilder.create(instance -> instance.group(
            Codec.BOOL.optionalFieldOf("is_default", false).forGetter(DragonBody::isDefault),
            UnlockableBehavior.CODEC.optionalFieldOf("unlockable_behavior").forGetter(DragonBody::unlockableBehavior),
            Modifier.CODEC.listOf().fieldOf("modifiers").forGetter(DragonBody::modifiers),
            ResourceLocation.CODEC.optionalFieldOf("default_icon").forGetter(DragonBody::defaultIcon)
    ).apply(instance, DragonBody::withoutDragonModel));

    public static final Codec<DragonBody> DIRECT_CODEC = Codec.either(MODEL_CODEC, NO_MODEL_CODEC).xmap(...);
}
```
**两套分支**：完整模型分支 + 无模型分支（`no_model.json` 用后者）。`noDragonModelRendering` 字段**不在 JSON 中**，由 `withoutDragonModel` 工厂硬编码为 `true`（`DragonBody.java:122-129`）。

完整分支字段表：

| JSON 字段 | Java 类型 | 必需 | 默认 |
|---|---|---|---|
| `is_default` | boolean | ❌ | `false` |
| `unlockable_behavior` | `UnlockableBehavior` | ❌ | 空 |
| `modifiers` | `List<Modifier>` | ✅ | — |
| `can_hide_wings` | boolean | ❌ | `true` |
| `model` | `ResourceLocation` | ❌ | `dragonsurvival:dragon_model` |
| `texture_size` | `{width, height}` | ❌ | `512x512` |
| `animation` | `ResourceLocation` | ✅ | — |
| `default_icon` | `ResourceLocation` | ❌ | 空 |
| `bones_to_hide_for_toggle` | `List<String>` | ❌ | `["WingLeft","WingRight","SmallWingLeft","SmallWingRight"]` |
| `emotes` | `Holder<DragonEmoteSet>` | ✅ | — |
| `scaling_proportions` | `ScalingProportions` | ✅ | — |
| `crouch_height_ratio` | double 0..100 | ✅ | — |
| `backpack_offset` | `BackpackOffsets` | ❌ | 空 |
| `bettercombat_weapon_offset` | double | ❌ | `0` |
| `rideable` | boolean | ❌ | `true` |

无模型分支：`is_default`、`unlockable_behavior`、`modifiers`(必需)、`default_icon`。

子对象：
- `TextureSize`：`width`、`height`（均必需，int）。
- `ScalingProportions`（`DragonBody.java:138-146`）：`width`、`height`、`eye_height`(**必需**，double ≥0)；`scale_multiplier`(默认 1.0)、`shadow_multiplier`(默认 1.0)、`ceiling_climbing_offset_multiplier`(范围 -10..10，默认 1.0)。
- `BackpackOffsets`（`:165-170`）：`position_offset`(Vec3，默认 `Vec3.ZERO`)、`rotation_offset`(Vec3，默认 0)、`scale`(Vec3，默认 `(1,1,1)`)。
默认值常量：`DEFAULT_MODEL = dragonsurvival:dragon_model`、`DEFAULT_ANIMATION = dragonsurvival:dragon_center`、`DEFAULT_TEXTURE_SIZE = 512x512`、`NO_MODEL_SCALING = ScalingProportions.of(0.6, 1.8, 1.62, 1.0, 1.0)`（`DragonBody.java:60-65`）。

`DragonBody.getBodies` 用 `unlockable_behavior.unlock_condition` 做 `Condition.entityContext(...)` 测试（`DragonBody.java:192`），可见性与 `DragonSpecies` 一致。

---

### 2.6 `dragon_emote_set/<id>.json`

`registry/dragon/body/emotes/DragonEmoteSet.java:20-25`
```java
public record DragonEmoteSet(List<DragonEmote> emotes) {
    public static final ResourceKey<Registry<DragonEmoteSet>> REGISTRY = ResourceKey.createRegistryKey(DragonSurvival.res("dragon_emote_set"));

    public static final Codec<DragonEmoteSet> DIRECT_CODEC = RecordCodecBuilder.create(instance -> instance.group(
            DragonEmote.CODEC.listOf().fieldOf("emotes").forGetter(DragonEmoteSet::emotes)
    ).apply(instance, DragonEmoteSet::new));
}
```
| JSON 字段 | 类型 | 必需 |
|---|---|---|
| `emotes` | `List<DragonEmote>` | ✅ |

`DragonEmote`（`registry/dragon/body/emotes/DragonEmote.java:17-46`）
```java
public record DragonEmote(
        String animationKey,
        Optional<String> translationOverride,
        double speed,
        int duration,
        boolean loops,
        boolean blend,
        boolean locksHead,
        boolean locksTail,
        boolean thirdPerson,
        boolean canMove,
        Optional<Sound> sound
) {
    public static final double DEFAULT_SPEED = 1;
    public static final int NO_DURATION = -1;

    public static final Codec<DragonEmote> CODEC = RecordCodecBuilder.create(instance -> instance.group(
            Codec.STRING.fieldOf("animation_key").forGetter(DragonEmote::animationKey),
            Codec.STRING.optionalFieldOf("translation_override").forGetter(DragonEmote::translationOverride),
            Codec.DOUBLE.optionalFieldOf("speed", DEFAULT_SPEED).forGetter(DragonEmote::speed),
            Codec.INT.optionalFieldOf("duration", NO_DURATION).forGetter(DragonEmote::duration),
            Codec.BOOL.optionalFieldOf("loops", false).forGetter(DragonEmote::loops),
            Codec.BOOL.optionalFieldOf("blend", false).forGetter(DragonEmote::blend),
            Codec.BOOL.optionalFieldOf("locks_head", false).forGetter(DragonEmote::locksHead),
            Codec.BOOL.optionalFieldOf("locks_tail", false).forGetter(DragonEmote::locksTail),
            Codec.BOOL.optionalFieldOf("third_person", false).forGetter(DragonEmote::thirdPerson),
            Codec.BOOL.optionalFieldOf("can_move", false).forGetter(DragonEmote::canMove),
            Sound.CODEC.optionalFieldOf("sound").forGetter(DragonEmote::sound)
    ).apply(instance, DragonEmote::new));
```
| JSON 字段 | 类型 | 必需 | 默认 |
|---|---|---|---|
| `animation_key` | String | ✅ | — |
| `translation_override` | String | ❌ | 空 |
| `speed` | double | ❌ | `1` |
| `duration` | int | ❌ | `-1`（无限制） |
| `loops` | bool | ❌ | `false` |
| `blend` | bool | ❌ | `false` |
| `locks_head` | bool | ❌ | `false` |
| `locks_tail` | bool | ❌ | `false` |
| `third_person` | bool | ❌ | `false` |
| `can_move` | bool | ❌ | `false` |
| `sound` | `{sound_event(必需), volume(默认 1), pitch(默认 1), interval(必需 int)}` | ❌ | 空 |

注意 `DragonEmote.Sound` 是两个同名 `Sound` 中**不同**的一个：`DragonEmote.Sound` 是 `sound_event`/`volume`/`pitch`/`interval`（`:50-59`），而 `Activation` 用的是 `registry/.../activation/Sound`（`:18-25`）。

同一 `animation_key` 可以在同一 set 中重复出现（不同 `translation_override`），见 `default_emotes.json:298-346`。

---

### 2.7 `projectile_data/<id>.json`

`registry/projectile/ProjectileData.java:30-102`
```java
public record ProjectileData(GeneralData generalData, Either<GenericBallData, GenericArrowData> typeData) {
    public static final Codec<ProjectileData> DIRECT_CODEC = RecordCodecBuilder.create(instance -> instance.group(
            GeneralData.CODEC.fieldOf("general_data").forGetter(ProjectileData::generalData),
            Codec.either(GenericBallData.CODEC, GenericArrowData.CODEC).fieldOf("type_data").forGetter(ProjectileData::typeData)
    ).apply(instance, ProjectileData::new));
```
| JSON 字段 | 类型 | 必需 |
|---|---|---|
| `general_data` | `GeneralData` | ✅ |
| `type_data` | `GenericBallData` **或** `GenericArrowData` | ✅ |

`GeneralData`（`:50-67`）：
| JSON 字段 | 类型 | 必需 | 默认 |
|---|---|---|---|
| `name` | `ResourceLocation` | ✅ | — |
| `is_impact_projectile` | bool | ❌ | `false` |
| `entity_hit_condition` | `LootItemCondition` | ❌ | 空 |
| `ticking_effects` | `List<ProjectileTargeting>` | ✅ | — |
| `common_hit_effects` | `List<ProjectileTargeting>` | ✅ | — |
| `entity_hit_effects` | `List<ProjectileEntityEffect>` | ✅ | — |
| `block_hit_effects` | `List<ProjectileBlockEffect>` | ✅ | — |

`GenericBallData`（`:77-83`）：
| JSON 字段 | 类型 | 必需 | 默认 |
|---|---|---|---|
| `resources` | `LevelBasedResource` | ✅ | — |
| `trail_particle` | `ParticleOptions` | ❌ | 空 |
| `on_destroy_effects` | `List<ProjectileTargeting>` | ❌ | `[]` |
| `behaviour_data` | `BehaviourData` | ✅ | — |

`BehaviourData`（`:86-101`）：
| JSON 字段 | 类型 | 必需 | 默认 |
|---|---|---|---|
| `width` | `LevelBasedValue` | ✅ | — |
| `height` | `LevelBasedValue` | ✅ | — |
| `max_bounces` | `LevelBasedValue` | ❌ | `constant(0)` |
| `max_lingering_ticks` | `LevelBasedValue` | ❌ | `constant(0)` |
| `max_movement_distance` | `LevelBasedValue` | ✅ | — |
| `max_lifespan` | `LevelBasedValue` | ✅ | — |

`GenericArrowData`（`:70-74`）：
| JSON 字段 | 类型 | 必需 | 默认 |
|---|---|---|---|
| `texture` | `LevelBasedResource` | ✅ | — |
| `piercing_level` | `LevelBasedValue` | ❌ | `constant(0)` |

---

### 2.8 `data_maps/dragonsurvival/...`

DataMap 定义见 §1.3。写 `data/<ns>/data_maps/dragonsurvival/<registry_path>/<data_map_id>.json`。

顶层结构（NeoForge 标准）：`{"replace": <bool, 可选>, "values": { "<entry key 或 #tag>": <value> }}`，
value 内部可带 `neoforge:conditions`（数组）+ `neoforge:value`（当 value 是数组时）。

#### 2.8.1 `diet_entries`（key: `dragon_species`，value: `List<DietEntry>`）
Codec：`DietEntry.CODEC.listOf()`（`DSDataMaps.java:32`）。`DietEntry`（`common/codecs/DietEntry.java:24-29`）：
```java
public record DietEntry(String items, Optional<FoodProperties> properties, Optional<Either<Boolean, RetainEffects>> retainEffects) {
    public static final Codec<DietEntry> CODEC = RecordCodecBuilder.create(instance -> instance.group(
            ResourceLocationWrapper.validatedCodec().fieldOf("items").forGetter(DietEntry::items),
            FoodProperties.DIRECT_CODEC.optionalFieldOf("properties").forGetter(DietEntry::properties),
            Codec.either(Codec.BOOL, RetainEffects.CODEC).optionalFieldOf("retain_effects").forGetter(DietEntry::retainEffects)
    ).apply(instance, DietEntry::new));
}
```
| JSON 字段 | 类型 | 必需 | 说明 |
|---|---|---|---|
| `items` | String | ✅ | 单个 id、`#tag`、或**正则**（`ResourceLocationWrapper.validatedCodec()`，见 `common/codecs/ResourceLocationWrapper.java:142-204`） |
| `properties` | `FoodProperties.DIRECT_CODEC`（`nutrition`/`saturation`/`can_always_eat`/`eat_seconds`/`using_converts_to`/`effects`） | ❌ | 空 → 用物品原始食物属性 |
| `retain_effects` | `bool` 或 `{beneficial, neutral, harmful}`（`DietEntry.java:118-123`，三者默认 `false`） | ❌ | 空 → 丢弃原效果（若自定义了 properties） |

生成物顶层使用 `neoforge:value`（因为 value 是数组），示例 `diet_entries.json:11-19`。

#### 2.8.2 `dragon_beacon_data`（key: `dragon_species`，value: `DragonBeaconData`）
`common/codecs/DragonBeaconData.java:14-33`：
```java
public record DragonBeaconData(List<Effect> effects, PaymentData paymentData) {
    public static final Codec<DragonBeaconData> CODEC = RecordCodecBuilder.create(instance -> instance.group(
            Effect.CODEC.listOf().fieldOf("effects").forGetter(DragonBeaconData::effects),
            PaymentData.CODEC.fieldOf("payment_data").forGetter(DragonBeaconData::paymentData)
    ).apply(instance, DragonBeaconData::new));

    public record PaymentData(int experienceCost, int durationMultiplier, int amplifierModification) {
        public static final Codec<PaymentData> CODEC = RecordCodecBuilder.create(instance -> instance.group(
                ExtraCodecs.intRange(0, Integer.MAX_VALUE).optionalFieldOf("experience_cost", 0).forGetter(PaymentData::experienceCost),
                ExtraCodecs.intRange(0, Integer.MAX_VALUE).optionalFieldOf("duration_multiplier", 1).forGetter(PaymentData::durationMultiplier),
                Codec.INT.optionalFieldOf("amplifier_modification", 0).forGetter(PaymentData::amplifierModification)
        ).apply(instance, PaymentData::new));
    }

    public record Effect(Holder<MobEffect> effect, int duration, int amplifier) {
        public static final Codec<Effect> CODEC = RecordCodecBuilder.create(instance -> instance.group(
                BuiltInRegistries.MOB_EFFECT.holderByNameCodec().fieldOf("effect").forGetter(Effect::effect),
                ExtraCodecs.intRange(MobEffectInstance.INFINITE_DURATION, Integer.MAX_VALUE).optionalFieldOf("duration", MobEffectInstance.INFINITE_DURATION).forGetter(Effect::duration),
                ExtraCodecs.intRange(0, Integer.MAX_VALUE).optionalFieldOf("amplifier", 0).forGetter(Effect::amplifier)
        ).apply(instance, Effect::new));
    }
}
```
外层：`effects`(必需)、`payment_data`(必需)；`payment_data`：`experience_cost`(默认 0)、`duration_multiplier`(默认 1)、`amplifier_modification`(默认 0)；每个 `effects[]`：`effect`(必需)、`duration`(默认 `-1` 无限)、`amplifier`(默认 0)。

#### 2.8.3 `end_platforms`（key: `dragon_species`，value: `EndPlatform`）
`common/codecs/EndPlatform.java:9-13`：
```java
public record EndPlatform(ResourceLocation structure, BlockPos spawnPosition) {
    public static final Codec<EndPlatform> CODEC = RecordCodecBuilder.create(instance -> instance.group(
            ResourceLocation.CODEC.fieldOf("structure").forGetter(EndPlatform::structure),
            BlockPos.CODEC.fieldOf("spawn_position").forGetter(EndPlatform::spawnPosition)
    ).apply(instance, EndPlatform::new));
}
```
`spawn_position` 是 `[x, y, z]` 数组（`BlockPos.CODEC`）。

#### 2.8.4 `stage_resources`（key: `dragon_species`，value: `Map<ResourceKey<DragonStage>, StageResource>`）
`common/codecs/StageResources.java:16-19, 62-81`：
```java
public static final Codec<Map<ResourceKey<DragonStage>, StageResource>> CODEC = Codec.unboundedMap(
        ResourceKey.codec(DragonStage.REGISTRY), StageResource.CODEC);

public record StageResource(GrowthIcon growthIcon, DefaultSkin defaultSkin) {
    public static final Codec<StageResource> CODEC = RecordCodecBuilder.create(instance -> instance.group(
            GrowthIcon.CODEC.fieldOf("growth_icon").forGetter(StageResource::growthIcon),
            DefaultSkin.CODEC.fieldOf("default_skin").forGetter(StageResource::defaultSkin)
    ).apply(instance, StageResource::new));
}
public record GrowthIcon(ResourceLocation hoverIcon, ResourceLocation icon) { ... "hover_icon" / "icon" ... }
public record DefaultSkin(ResourceLocation skin, ResourceLocation glowSkin) { ... "skin" / "glow_skin" ... }
```
所以 JSON 形态（见 `stage_resources.json:11-20`）：
```json
"dragonsurvival:cave_dragon": {
  "dragonsurvival:adult": {
    "default_skin": { "glow_skin": "...", "skin": "..." },
    "growth_icon": { "hover_icon": "...", "icon": "..." }
  }
}
```
三个子对象字段全部必需。`GrowthIcon`/`DefaultSkin` 的 `ResourceLocation` 在类型上非 Optional，但 `StageResources.getGrowthIcon/getDefaultSkin` 用 `Objects.requireNonNullElse(..., MISSING)` 兜底为 `dragonsurvival:missingno`（`:21,38,59`）。

#### 2.8.5 `body_icons`（key: `dragon_body`，value: `Map<ResourceKey<DragonSpecies>, ResourceLocation>`）
`registry/data_maps/BodyIcons.java:15-17`：
```java
public static final Codec<Map<ResourceKey<DragonSpecies>, ResourceLocation>> CODEC = Codec.unboundedMap(
        ResourceKey.codec(DragonSpecies.REGISTRY), ResourceLocation.CODEC);
```

#### 2.8.6 DataMap 的自定义条件 `dragonsurvival:registered`
生成物里每个 value 都带：
```json
"neoforge:conditions": [ { "type": "dragonsurvival:registered", "registry": "dragonsurvival:dragon_species", "value": "dragonsurvival:cave_dragon" } ]
```
定义在 `registry/datagen/data_maps/RegisteredCondition.java:12-30` + 注册于 `registry/DSConditions.java:14-19`：
```java
public record RegisteredCondition<T>(ResourceKey<T> registryKey) implements ICondition {
    public static final MapCodec<RegisteredCondition<?>> CODEC = RecordCodecBuilder.mapCodec(instance -> instance
            .group(ResourceLocation.CODEC.fieldOf("registry").forGetter(condition -> condition.registryKey().registry()),
                    ResourceLocation.CODEC.fieldOf("value").forGetter(condition -> condition.registryKey().location()))
            .apply(instance, RegisteredCondition::new));

    @Override
    public boolean test(@NotNull final IContext context) {
        return ((ContextExtension) context).dragonSurvival$getRegistryAccess().holder(registryKey).map(Holder::isBound).orElse(false);
    }
```
作用：若某个内置物种被其他 datapack 删除/替换，对应 DataMap 条目自动失效（因为其 id 不再 registered）。

---

## 3. 数值提供器（Number/Value Provider）系统

**结论：Dragon Survival 没有自己的数值提供器 codec。所有 `amount` / `duration` / `cooldown` 之类字段用的都是原版 `net.minecraft.world.item.enchantment.LevelBasedValue`。**
`grep "NumberProvider"` 在整个 `src/main/java` 下**零命中**。

### 3.1 `LevelBasedValue` 的 codec（原版 1.21.1）

`build/tmp/.cache/expanded/zip_0ed57fda7455acedc715cd4cdde77a99/net/minecraft/world/item/enchantment/LevelBasedValue.java:14-32`
```java
public interface LevelBasedValue {
    Codec<LevelBasedValue> DISPATCH_CODEC = BuiltInRegistries.ENCHANTMENT_LEVEL_BASED_VALUE_TYPE
        .byNameCodec()
        .dispatch(LevelBasedValue::codec, codec -> BuiltInRegistries.ENCHANTMENT_LEVEL_BASED_VALUE_TYPE.getKey(codec));
    Codec<LevelBasedValue> CODEC = Codec.either(LevelBasedValue.Constant.CODEC, DISPATCH_CODEC)
        .xmap(
            either -> either.map(c -> (LevelBasedValue) c, c -> (LevelBasedValue) c),
            value -> value instanceof LevelBasedValue.Constant constant ? Either.left(constant) : Either.right(value)
        );

    static MapCodec<? extends LevelBasedValue> bootstrap(Registry<MapCodec<? extends LevelBasedValue>> registry) {
        Registry.register(registry, "clamped", LevelBasedValue.Clamped.CODEC);
        Registry.register(registry, "fraction", LevelBasedValue.Fraction.CODEC);
        Registry.register(registry, "levels_squared", LevelBasedValue.LevelsSquared.CODEC);
        Registry.register(registry, "linear", LevelBasedValue.Linear.CODEC);
        return Registry.register(registry, "lookup", LevelBasedValue.Lookup.CODEC);
    }
```
> 注：`build/tmp/.cache/expanded/...` 是 NeoForm 解压出的**源文件**，其 `DISPATCH_CODEC` 因反编译/解码器差异显示为单参数形式；`bootstrap` 中的注册顺序与 id 字符串是权威信息。
> `CODEC` 是 `either(Constant.CODEC, DISPATCH_CODEC)`，`Constant.CODEC` 是**裸 float**（`:81`），因此
> **`"amount": 1.0` 直接写数字是合法的**，而带 `type` 的对象则走 dispatch 分支。

### 3.2 全部 `type` 取值

| `type` | 记录类 | JSON 形态 | `calculate` 语义 |
|---|---|---|---|
| （无 type，裸数字） | `Constant(float value)` | `1.0` | 恒为 `value` |
| `minecraft:linear` | `Linear(float base, float perLevelAboveFirst)` | `{"type":"minecraft:linear","base":B,"per_level_above_first":P}` | `base + perLevelAboveFirst * (level - 1)`（`:136-148`） |
| `minecraft:lookup` | `Lookup(List<Float> values, LevelBasedValue fallback)` | `{"type":"minecraft:lookup","values":[...],"fallback":{...}}` | `level <= values.size() ? values.get(level-1) : fallback.calculate(level)`（`:156-168`） |
| `minecraft:clamped` | `Clamped(LevelBasedValue value, float min, float max)` | `{"type":"minecraft:clamped","value":{...},"min":m,"max":M}` | `Mth.clamp(value.calculate(level), min, max)`；**校验 `max > min`**（`:54-67`） |
| `minecraft:fraction` | `Fraction(LevelBasedValue numerator, LevelBasedValue denominator)` | `{"type":"minecraft:fraction","numerator":{...},"denominator":{...}}` | `den==0 ? 0 : num/den`（`:98-111`） |
| `minecraft:levels_squared` | `LevelsSquared(float added)` | `{"type":"minecraft:levels_squared","added":a}` | `level^2 + added`（`:119-128`） |

`Constant` 还有 typed 形式 `{"type":"minecraft:constant","value":v}`（`TYPED_CODEC`，`:82-85`），但 `CODEC` 的 Either 只对 `Constant.CODEC`（裸 float）短路匹配，因此 typed 形式走 dispatch 分支也可解析。

### 3.3 `{"type":"minecraft:lookup","values":[...],"fallback":{...}}` 合法性 + `fallback` 使用点

**合法，且是本 mod 实际生成的形态。** 证据：

1. 原版 codec（上表）明确要求 `values` + `fallback` 两个字段（`LevelBasedValue.java:156-163`）：
```java
public static record Lookup(List<Float> values, LevelBasedValue fallback) implements LevelBasedValue {
    public static final MapCodec<LevelBasedValue.Lookup> CODEC = RecordCodecBuilder.mapCodec(
        i -> i.group(
            Codec.FLOAT.listOf().fieldOf("values").forGetter(LevelBasedValue.Lookup::values),
            LevelBasedValue.CODEC.fieldOf("fallback").forGetter(LevelBasedValue.Lookup::fallback)
        ).apply(i, LevelBasedValue.Lookup::new));
```
2. 该形态在 datagen 中由 `LevelBasedValue.lookup(List<Float>, LevelBasedValue)` 产生（`LevelBasedValue.java:46-48`），例如 `registry/datagen/abilities/SeaDragonAbilities.java:184`：
```java
Optional.of(new ExperienceLevelUpgrade(4, LevelBasedValue.lookup(List.of(0f, 10f, 30f, 50f), LevelBasedValue.perLevel(15))))
```
3. 序列化落盘实例 `src/generated/resources/data/dragonsurvival/dragonsurvival/dragon_ability/ball_lightning.json:72-89`：
```json
"upgrade": {
  "level_requirement": {
    "type": "minecraft:lookup",
    "fallback": { "type": "minecraft:linear", "base": 15.0, "per_level_above_first": 15.0 },
    "values": [ 0.0, 20.0, 45.0, 50.0 ]
  },
  "maximum_level": 4,
  "upgrade_type": "dragonsurvival:experience_levels"
}
```

**`fallback` 何时被使用**：当 `level > values.size()` 时。`Lookup.calculate`（`LevelBasedValue.java:165-168`）：
```java
@Override
public float calculate(int level) {
    return level <= this.values.size() ? this.values.get(level - 1) : this.fallback.calculate(level);
}
```
即上例中 `values` 只有 4 个元素，能力等级 1..4 用 `values[0..3]`；若等级 > 4（`MAX_LEVEL` 允许到 255，或 `maximum_level` 被其它配置放大）则用 `linear(15, 15)` 外推。

**DS 的注意点**：等级 0 被特殊处理为“能力启用/禁用”而非等级（`DragonAbilityInstance.java:42-44`）：
```java
public static final int MIN_LEVEL = 0;
/** Since {@link LevelBasedValue} does not expect a level of 0 we handle 0 as "ability is disabled" */
public static final int MIN_LEVEL_FOR_CALCULATIONS = 1;
```
所以 `values[0]` 对应等级 1（`0f` 通常代表“等级 1 免费”）。

### 3.4 其它 "LevelBased*" 系列（DS 自定义，仅用于图标/tier，不是数值提供器）

| 类 | 文件 | JSON |
|---|---|---|
| `LevelBasedResource` | `common/codecs/LevelBasedResource.java:15-39` | `{"texture_entries":[{"texture_resource":..., "from_level":int}]}`，内部按 `from_level` 降序排序，取第一个 `level >= from_level` |
| `LevelBasedTier` | `common/codecs/LevelBasedTier.java:16-39` | `{"tiers":[{"tier":<Tiers 枚举>, "from_level":int}]}` |
| `LevelBasedBoolean` | `common/codecs/LevelBasedBoolean.java:14-46` | `{"fallback":bool(默认 false), "entries":[{"value":bool,"from_level":int}]}` |
| `LevelBasedBlockPredicate` | `common/codecs/LevelBasedBlockPredicate.java:17-53` | `{"fallback":<BlockPredicate, 默认 alwaysTrue>, "entries":[{"value":<BlockPredicate>,"from_level":int}]}` |

`from_level` 一律受 `ExtraCodecs.intRange(MIN_LEVEL=0, MAX_LEVEL=255)` 限制。

---

## 4. 飞行相关属性

`registry/DSAttributes.java:22-34, 74-75`
```java
@Translation(type = Translation.Type.ATTRIBUTE, comments = "Flight Stamina")
@Translation(type = Translation.Type.ATTRIBUTE_DESCRIPTION, comments = "Reduces the food exhaustion of flying")
public static final Holder<Attribute> FLIGHT_STAMINA_COST = REGISTRY.register("flight_stamina", () -> new RangedAttribute(Translation.Type.ATTRIBUTE.wrap("flight_stamina"), 1, 0, 5).setSyncable(true));
...
@Translation(type = Translation.Type.ATTRIBUTE, comments = "Flight Speed")
@Translation(type = Translation.Type.ATTRIBUTE_DESCRIPTION, comments = "A multiplier to the flight speed")
public static final Holder<Attribute> FLIGHT_SPEED = REGISTRY.register("flight_speed", () -> new RangedAttribute(Translation.Type.ATTRIBUTE.wrap("flight_speed"), 1, 0, 1024).setSyncable(true));
...
event.add(EntityType.PLAYER, FLIGHT_STAMINA_COST);
event.add(EntityType.PLAYER, FLIGHT_SPEED);
```

| 注册 id | Java 常量 | 类型 | 默认/base | 范围 | 同步 |
|---|---|---|---|---|---|
| `dragonsurvival:flight_stamina` | `FLIGHT_STAMINA_COST` | `RangedAttribute` | `1` | `0 .. 5` | `setSyncable(true)` |
| `dragonsurvival:flight_speed` | `FLIGHT_SPEED` | `RangedAttribute` | `1` | `0 .. 1024` | `setSyncable(true)` |

> **不存在 `flight_level` 属性**。`grep "flight_level"` 零命中。
> （`flight_was_granted` 是 `DragonPredicate` 的**布尔谓词字段**，见 `common/codecs/predicates/DragonPredicate.java:49`，不是属性。）

### 应用点

**`FLIGHT_STAMINA_COST`：飞行饥饿消耗的除数**（`server/handlers/ServerFlightHandler.java:326-340`）
```java
Vec3 delta = player.getDeltaMovement();
float moveSpeed = (float) delta.horizontalDistance();
float l = 4f / flightHungerTicks;
float moveSpeedReq = 1.0F;
float minFoodReq = l / 10f;
float drain = Math.max(minFoodReq, (float) (Math.min(1.0, Math.max(0, Math.max(moveSpeedReq - moveSpeed, 0) / moveSpeedReq)) * l));

double flightStamina = player.getAttributeValue(DSAttributes.FLIGHT_STAMINA_COST);

if (flightStamina > 0) {
    drain /= (float) flightStamina;
}

player.causeFoodExhaustion(drain);
```
默认值 1 → 无修正；值越高，消耗越低（属性描述也写明 “Reduces the food exhaustion of flying”）。

**`FLIGHT_SPEED`：飞行加速度/速度上限的乘数**（`client/handlers/ClientFlightHandler.java:344` 读取，`:404-481` 使用）
```java
Double flightSpeedMultiplier = player.getAttributeValue(DSAttributes.FLIGHT_SPEED);
...
double speedThreshold = flightSpeedMultiplier;                     // :404
double downwardMomentum = deltaMovement.y * -0.1D * (double) verticalDelta * flightSpeedMultiplier;  // :411
double delta = horizontalMovement * -Mth.sin(pitch) * 0.04D * flightSpeedMultiplier;                  // :417
deltaMovement = deltaMovement.add((viewVector.x * flightSpeedMultiplier / horizontalView * horizontalMovement - deltaMovement.x) * 0.1D, 0.0D, (viewVector.z * flightSpeedMultiplier / horizontalView * horizontalMovement - deltaMovement.z) * 0.1D); // :422
ax += (Math.cos(yaw) * flightSpeedMultiplier * 2) / 500;            // :427
az += (Math.sin(yaw) * flightSpeedMultiplier * 2) / 500;            // :428
double speedLimit = ServerFlightHandler.maxFlightSpeed * flightSpeedMultiplier; // :435
double maxForward = 0.5 * flightSpeedMultiplier * 2;                // :462
moveVector.multiply(1.3 * flightSpeedMultiplier * 2, 0, 1.3 * flightSpeedMultiplier * 2); // :465
```

**其它飞行相关硬编码/配置**（`server/handlers/ServerFlightHandler.java:45-98`）：`SPIN_DURATION`、`maxFlightSpeed = 0.3`、`flightHungerThreshold = 6`、`foldWingsThreshold = 0`、`flightSpinCooldown = 5`、`flightHungerTicks = 50`、`stableHover = false`、`collisionDamageSpeedFactor = 10.0f`、`collisionDamageThreshold = 3.0f` 等均为 `@ConfigOption`，非属性。

体型/阶段对飞行的影响来自 `DragonBodies` / `DragonStages` 的 `modifiers`（例：`registry/dragon/body/DragonBodies.java:70, 95-96, 118, 140-141, 162-163` 对 `FLIGHT_SPEED` / `FLIGHT_STAMINA_COST` 施加 `Modifier`）。

---

## 5. Tag 的运行时消费点与 `order.json` 的作用

### 5.1 `dragonsurvival:dragon_species/order` —— **祭坛（Altar）物种显示顺序**

`client/gui/screens/DragonAltarScreen.java:114-132`
```java
public DragonAltarScreen(final List<UnlockableBehavior.SpeciesEntry> entries) {
    super(Component.translatable(CHOOSE_SPECIES));

    Minecraft.getInstance().player.registryAccess().registryOrThrow(DragonSpecies.REGISTRY).getTag(DSDragonSpeciesTags.ORDER).ifPresent(order -> {
        List<Holder<DragonSpecies>> list = ((HolderSet$NamedAccess<DragonSpecies>) order).dragonSurvival$contents();

        Comparator<UnlockableBehavior.SpeciesEntry> comparator = Comparator.comparingInt(entry -> {
            int index = list.indexOf(entry.species());
            // Sort entries that are not present to the end
            return index == -1 ? Integer.MAX_VALUE : index;
        });

        entries.sort(comparator);
    });

    this.entries = entries;
}
```
Tag 源定义：`registry/datagen/tags/DSDragonSpeciesTags.java:19, 41`
```java
public static final TagKey<DragonSpecies> ORDER = key("order");
...
tag(ORDER).add(BuiltInDragonSpecies.CAVE_DRAGON).add(BuiltInDragonSpecies.FOREST_DRAGON).add(BuiltInDRAGON...SEA_DRAGON);
```
生成物 `tags/dragonsurvival/dragon_species/order.json`：`[cave_dragon, forest_dragon, sea_dragon]`。

**顺序语义**：`getTag(ORDER)` 返回的 `HolderSet.Named`，其 `contents()` 顺序即 `values` 数组顺序；比较器按该索引升序排序；**未出现在 tag 中的物种排在最后**（`Integer.MAX_VALUE`）。

> ⚠️ **注意**：`registry/datagen/tags/DSDragonAbilityTags.java:116` 自带一条 TODO 质疑：
> ```java
> tag(ORDER) // TODO :: if the tags are added instead, are the orders within them respected / guaranteed?
> ```
> 即作者自己也不确定 order tag 在不展开子 tag 时顺序是否被保证。`DSDragonSpeciesTags.ORDER` 的生成物不含子 tag 引用，所以顺序是稳定的。

### 5.2 `dragonsurvival:dragon_ability/order` —— **能力界面（Ability Screen）排序**

`client/gui/screens/DragonAbilityScreen.java:219-231`
```java
minecraft.player.registryAccess().registryOrThrow(DragonAbility.REGISTRY).getTag(DSDragonAbilityTags.ORDER).ifPresent(order -> {
    List<Holder<DragonAbility>> list = ((HolderSet$NamedAccess<DragonAbility>) order).dragonSurvival$contents();
    Comparator<DragonAbilityInstance> comparator = Comparator.comparingInt(instance -> {
        int index = list.indexOf(instance.ability());
        // Sort entries that are not present to the end
        return index == -1 ? Integer.MAX_VALUE : index;
    });

    actives.sort(comparator);
    upgradablePassives.sort(comparator);
    constantPassives.sort(comparator);
});
```
三段列表（主动 / 可手动升级被动 / 恒定被动）分别排序，来源 `:215-217`。

`HolderSet$NamedAccess` 是一个 mixin accessor（`mixins/HolderSet$NamedAccess.java:10-14`）：
```java
@Mixin(HolderSet.Named.class)
public interface HolderSet$NamedAccess<T> {
    @Invoker("contents")
    List<Holder<T>> dragonSurvival$contents();
}
```
Tag 定义 `registry/datagen/tags/DSDragonAbilityTags.java:25-26`，生成物 `tags/dragonsurvival/dragon_ability/order.json`（43 项，顺序为 cave → forest → sea）。

### 5.3 `dragonsurvival:dragon_ability/<species>` —— **物种的技能集合**

Tag key：`DSDragonAbilityTags.CAVE/SEA/FOREST`（`DSDragonAbilityTags.java:28-33`，path 分别是 `cave_dragon` / `sea_dragon` / `forest_dragon`）。

消费点 1 —— **内置物种构造**（`registry/dragon/BuiltInDragonSpecies.java:67, 105, 143`）：
```java
context.lookup(DragonAbility.REGISTRY).getOrThrow(DSDragonAbilityTags.CAVE),
```
即把 tag 解析成 `HolderSet<DragonAbility>` 塞进 `DragonSpecies.abilities`。生成物 `dragon_species/cave_dragon.json:2` 写的就是 `"abilities": "#dragonsurvival:cave_dragon"`。

消费点 2 —— **`magic_stick` 物品的 `DSDataComponents.DRAGON_ABILITIES`**（`registry/DSItems.java:461-486`）：
```java
.component(DSDataComponents.DRAGON_ABILITIES, new DragonAbilityHolder(List.of(
        new DragonAbilityHolder.AbilityPair(List.of(ResourceLocationWrapper.convert(DSDragonAbilityTags.TEST_ABILITIES)), List.of(), false),
        new DragonAbilityHolder.AbilityPair(List.of(ResourceLocationWrapper.convert(SeaDragonAbilities.ORE_GLOW)), List.of(), true),
        new DragonAbilityHolder.AbilityPair(List.of(ResourceLocationWrapper.convert(DSDragonAbilityTags.CAVE)), List.of(ResourceLocationWrapper.convert(DSDragonAbilityTags.FOREST)), true)
), Optional.empty(), List.of(ResourceLocationWrapper.convert(BuiltInDragonSpecies.FOREST_DRAGON))))
```
`ResourceLocationWrapper.convert(TagKey)` 把 tag 转成 `"#dragonsurvival:cave_dragon"` 字符串（`common/codecs/ResourceLocationWrapper.java:95-97`），后续通过 `ResourceLocationWrapper.map(String, Registry)` 展开（`:39-89`，支持 tag / 单 id / **正则**）。

消费点 3 —— 技能 `usage_blocked` 条件（`registry/dragon/ability/DragonAbilities.java:342`）用 `DSDragonAbilityTags.CAVE` 作为 `DragonPredicate.dragon_species`。

### 5.4 `dragonsurvival:dragon_species/all` 与 `/true_dragons`

定义：`DSDragonSpeciesTags.java:24, 26`；生成物：
- `all.json`：`cave_dragon, forest_dragon, sea_dragon`
- `true_dragons.json`：`cave_dragon, sea_dragon, forest_dragon`
- `none.json`：空（`:44`）

消费点：
- `registry/DSEnchantments.java:130, 147, 169`：反龙附魔的效果条件
  ```java
  Condition.thisEntity(EntityCondition.isSpecies(context.lookup(DragonSpecies.REGISTRY).getOrThrow(DSDragonSpeciesTags.TRUE_DRAGONS)))
  ```
- `registry/datagen/data_maps/DragonBeaconDataProvider.java:38`：`dragon_beacon_data` 的默认条目挂在 `#dragonsurvival:all` 上（生成物 `dragon_beacon_data.json:3` 的 `"#dragonsurvival:all"`）。运行时由 `common/blocks/DragonBeacon.java:116` 读取：
  ```java
  DragonBeaconData beaconData = handler.species().getData(DSDataMaps.DRAGON_BEACON_DATA);
  ```
- `registry/DSBlocks.java:1047, 1059`：压力板判断 `DSDragonSpeciesTags.ALL` / `NONE`（`DragonPressurePlateBlock` 的允许物种集合）
- `DSBlocks.java:201, 214, 227, 359, 371, 383, 1071, 1084, 1096`：各物种传送门/门的 block 行为
- `common/effects/ConfoundedEffect.java:77`（`FOREST_DRAGONS`）、`common/effects/BlastDustedEffect.java:50, 100`（`CAVE_DRAGONS`）

### 5.5 `dragonsurvival:dragon_penalty/<species>`

定义：`registry/datagen/tags/DSDragonPenaltyTags.java:17-23`（path：`cave_dragon` / `sea_dragon` / `forest_dragon`）。
生成物 `tags/dragonsurvival/dragon_penalty/cave_dragon.json` 等。

消费点 1 —— 内置物种构造（`BuiltInDragonSpecies.java:68, 106, 144`）：
```java
context.lookup(DragonPenalty.REGISTRY).getOrThrow(DSDragonPenaltyTags.CAVE),
```
消费点 2 —— 运行时逐 tick 应用（`common/handlers/DragonPenaltyHandler.java:42-48`）：
```java
for (Holder<DragonPenalty> penalty : handler.species().value().penalties()) {
    if (penalty.value().trigger().hasCustomTrigger()) {
        continue;
    }
    penalty.value().apply(serverPlayer, penalty);
}
```
另有专门事件分支：`LivingEntityUseItemEvent.Finish` → `ItemUsedTrigger`（`:63-67`）；`ProjectileImpactEvent` → `HitByProjectileTrigger`（`:82-87`）。
`ThrownPotionMixin.java:42` 处理 `HitByWaterPotionTrigger`。
`registry/attachments/PenaltySupply.java:145` 用于建立 supply 表；`server/handlers/PlayerLoginHandler.java:81` 用于清除已不存在的 supply。
UI：`client/gui/screens/DragonSpeciesScreen.java:315` 用 `penalty.icon()` 生成 `PenaltyButton`。

### 5.6 `dragonsurvival:dragon_body/order`

`registry/datagen/tags/DSDragonBodyTags.java:20-30, 32-53`
```java
public static final TagKey<DragonBody> ORDER = key("order");
...
tag(ORDER).add(DragonBodies.CENTER, DragonBodies.EAST, DragonBodies.NORTH, DragonBodies.SOUTH, DragonBodies.WEST);

public static List<Holder<DragonBody>> getOrdered(@Nullable final HolderLookup.Provider provider) {
    ...
    registry.get(ORDER).ifPresent(set -> set.forEach(bodies::add));
    registry.listElements().forEach(body -> { if (!bodies.contains(body)) { bodies.add(body); } });
    return bodies;
}
```
消费点：`client/gui/screens/DragonSkinsScreen.java:317` —— `for (Holder<DragonBody> dragonBodyHolder : DSDragonBodyTags.getOrdered(null))`。
语义与物种 order 相同（tag 内优先，其余追加到末尾），但**用的是 `DSDragonBodyTags.getOrdered` 辅助方法，而不是比较器**。

### 5.7 `dragonsurvival:dragon_ability/test_abilities`

由 datagen 自动收集所有以 `DragonAbilities.TEST_PREFIX` 开头的 ability（`DSDragonAbilityTags.java:44-56`），产物 `tags/dragonsurvival/dragon_ability/test_abilities.json`。消费点：`DSItems.java:467`（`magic_stick`）。

---

## 6. datapack 覆盖语义 & `data/dragonsurvival/datapacks/` 内置 datapack

### 6.1 能否用同 id 覆盖？

**能。** 7 个 `DataPackRegistryEvent.dataPackRegistry(...)` 注册的都是标准 datapack registry，语义完全遵循原版：
- 高优先级数据包（`datapacks/` 目录内、或 mod 用 `Pack.Position.TOP` 注册的内置包）中**同 namespace+path 的条目会整体覆盖**低优先级条目；
- **单个 JSON 文件是原子的** —— 不存在“字段级 merge”，要改一个字段必须复制整份 JSON 再改；
- DS 自身**没有**任何自定义的 merge/replace 逻辑（`grep "replace"` 在 registry 相关代码中只有 `NoPenaltiesPenaltyProvider` 对 **tag** 用 `tag(...).replace(true)`，见 `registry/datagen/datapacks/NoPenaltiesPenaltyProvider.java:24-26`）。

**Tag 的覆盖**是另一套机制：`tags/**/*.json` 顶层默认是**追加**；要整体替换必须写 `{"replace": true, "values": [...]}`。本 mod 的唯一示例是 no_penalties 内置包：
```java
tag(DSDragonPenaltyTags.CAVE).replace(true);
tag(DSDragonPenaltyTags.SEA).replace(true);
tag(DSDragonPenaltyTags.FOREST).replace(true);
```
（`NoPenaltiesPenaltyProvider.java:24-26`）

**DataMap 的覆盖**：`DataMapProvider.add(key, value, replace, conditions...)` 的第三参数即 `replace`；`AdvancedDataMapType` 还支持通过 `merger` 做值级合并（`DIET_ENTRIES` 用 `DietEntryMerger`，`STAGE_RESOURCES`/`BODY_ICONS` 用 `DataMapValueMerger.mapMerger()`），并可通过 `remover` 删除单个条目（`DietEntryRemover` 按 `items` 字符串删除，`common/codecs/DietEntry.java:100-111` 的 `equals`/`hashCode` 只比较 `items`）。

`DataReloadHandler` 在 reload 后**只做校验、不做改写**：若某个 `custom_stage_progression` 链断裂、或缺少内置 `newborn`/`young`/`adult`，会抛异常并 log（`DragonStage.java:88-90`、`DragonSpecies.java:103-105`、`DragonAbility.java:97-99`）。

### 6.2 `src/generated/resources/data/dragonsurvival/datapacks/` 是什么

这是 **mod 内置的、可选择启用的子数据包（built-in datapacks）**，编译时打包进 jar 的 `data/dragonsurvival/datapacks/<name>/`（内部是完整的 `pack.mcmeta` + `data/...` 结构）。

目录清单（`src/generated/resources/data/dragonsurvival/datapacks/`）：
| 子目录 | 内容 |
|---|---|
| `ancient_stage/` | 新增 `dragonsurvival:ancient` 龙阶段（含 `end_platform` 皮肤等） |
| `ancient_stage_no_crushing/` | 同上但禁用 crushing |
| `unlock_wings/` | 自动解锁飞行、阻止末影龙禁用翅膀 |
| `no_penalties/` | 用 `tags` + `data_maps` 把三个内置物种的 penalty 清空 |
| `create/` | Create 兼容（战利品表） |
| `silentgems/` | Silent Gems 兼容（战利品表） |

每个子包均有自己的 `pack.mcmeta`，例如 `datapacks/ancient_stage/pack.mcmeta`：
```json
{
  "features": { "enabled": [] },
  "pack": {
    "description": { "translate": "dragonsurvival.gui.datapack.ancient_stage" },
    "pack_format": 48
  }
}
```
（`pack_format = 48` 与 `gradle.properties:pack_format_number=48` 一致。）

**启用机制：NeoForge `AddPackFindersEvent`**
`registry/datagen/DataGeneration.java:183-212`
```java
@SubscribeEvent
public static void addPackFinders(final AddPackFindersEvent event) {
    if (event.getPackType() == PackType.CLIENT_RESOURCES) {
        registerResourcePack(event, Component.literal("DS - Draconized Armor"), "resourcepacks/draconized_armor");
        registerResourcePack(event, Component.literal("DS - Dark GUI"), "resourcepacks/ds_dark_gui");
    } else if (event.getPackType() == PackType.SERVER_DATA) {
        registerDataPack(event, Component.literal("DS - Ancient Dragons"), ANCIENT_STAGE_DATAPACK, PackSource.DEFAULT, false);
        registerDataPack(event, Component.literal("DS - Unlock Wings"), UNLOCK_WINGS_DATAPACK, PackSource.DEFAULT, false);

        if (ModID.SILENTGEMS.isLoaded()) {
            registerDataPack(event, Component.literal("DS - Silent Gems"), SILENT_GEMS_DATAPACK, PackSource.BUILT_IN, true);
        }
        if (ModID.CREATE.isLoaded()) {
            registerDataPack(event, Component.literal("DS - Create"), CREATE_DATAPACK, PackSource.BUILT_IN, true);
        }

        // Feature datapacks (things that are not enabled by default)
        registerDataPack(event, Component.literal("DS - Ancient (no crushing)"), ANCIENT_STAGE_DATAPACK_NO_CRUSHING, PackSource.FEATURE, false);
        registerDataPack(event, Component.literal("DS - No Penalties"), NO_PENALTIES_DATAPACK, PackSource.FEATURE, false);
    }
}

private static void registerDataPack(final AddPackFindersEvent event, final MutableComponent name, final String datapack, final PackSource source, final boolean alwaysActive) {
    event.addPackFinders(DragonSurvival.res("data/" + DragonSurvival.MODID + "/datapacks/" + datapack), PackType.SERVER_DATA, name, source, alwaysActive, Pack.Position.TOP);
}
```

| 内置包 | 显示名 | `PackSource` | `alwaysActive` | 默认是否启用 |
|---|---|---|---|---|
| `ancient_stage` | DS - Ancient Dragons | `DEFAULT` | `false` | 否（可在「数据包」界面启用） |
| `unlock_wings` | DS - Unlock Wings | `DEFAULT` | `false` | 否 |
| `ancient_stage_no_crushing` | DS - Ancient (no crushing) | `FEATURE` | `false` | 否（需开启实验性功能） |
| `no_penalties` | DS - No Penalties | `FEATURE` | `false` | 否（需开启实验性功能） |
| `silentgems` | DS - Silent Gems | `BUILT_IN` | `true` | 是（仅当检测到 Silent Gems） |
| `create` | DS - Create | `BUILT_IN` | `true` | 是（仅当检测到 Create） |

`Pack.Position.TOP` 让这些内置包在优先级上**高于**普通资料包（因此 `no_penalties` 的 `replace(true)` tag 能生效）。
`ancient_stage` 的 stage 定义不是手写 JSON，而是 datagen 生成（`DataGeneration.java:214-222` → `AncientDatapacks.registerAncient`，`registry/datagen/datapacks/AncientDatapacks.java:28-64`），并在客户端通过 `ResourceHelper.get(..., AncientDatapacks.ancient).isPresent()` 检测该包是否加载（`client/gui/screens/DragonSkinsScreen.java:361-363`）。

---

## 7. 附录：全部 `effect_type` 的逐字段 codec（entity effect 32 个 / block effect 11 个）

> 全部路径前缀：`src/main/java/by/dragonsurvivalteam/dragonsurvival/registry/dragon/ability/`。
> “注入”列的含义：若该效果类 `extends DurationInstanceBase<...>`，则它的 JSON **必须**带一个嵌套对象 `"base"`（见 §7.2 的 `DurationInstanceBase` 字段表）。

### 7.1 entity effect

| `effect_type` | 类 / 文件 | 字段（JSON 名 → 类型 / 必需性 / 默认） | codec 行 |
|---|---|---|---|
| `damage` | `DamageEffect`<br>`entity_effects/DamageEffect.java` (96 行) | `damage_type`→`Holder<DamageType>`/必需；`amount`→`LevelBasedValue`/必需；`scale`→`Holder<Attribute>`/默认 `dragonsurvival:dragon_ability_damage`；`expression`→`Expression`（变量仅 `amount`,`scale`）/默认 `"amount * scale"`；`use_claw`→bool/默认 `false` | L33-39 |
| `modifier` | `ModifierEffect`<br>`entity_effects/ModifierEffect.java` (89) | `modifiers`→`List<ModifierWithDuration>`/必需 | L23-25 |
| `potion` | `PotionEffect`<br>`entity_effects/PotionEffect.java` (46) | `potion`→`PotionData`/必需 | L15-17 |
| `projectile` | `ProjectileEffect`<br>`entity_effects/ProjectileEffect.java` (238) | `projectile_data`→`Holder<ProjectileData>`/可选；`projectile_type`→`Holder<EntityType<?>>`/可选（二者皆空则 `validate` 报错 `"Need to specify either 'projectile_data' or 'projectile_type'"`）；`target_direction`→`TargetDirection`/必需；`number_of_projectiles`→`LevelBasedValue`/必需；`projectile_spread`→`LevelBasedValue`/默认 `constant(0)`；`speed`→`LevelBasedValue`/必需 | L58-70 |
| `summon_entity` | `SummonEntityEffect`<br>`common_effects/SummonEntityEffect.java` (472)，**同时注册为 block effect** | `base`→`DurationInstanceBase`/必需；`entities`→`Either<SimpleWeightedRandomList<EntityType<?>>, HolderSet<EntityType<?>>>`/必需；`max_summons`→`LevelBasedValue`/必需；`attribute_scales`→`List<{attributes: HolderSet<Attribute>, scale: LevelBasedValue}>`/默认 `[]`（两者皆必需）；`nbt`→`CompoundTag`/可选；`is_allied`→bool/默认 `true` | L89-106（`AttributeScale` L103-106） |
| `damage_modification` | `DamageModificationEffect`<br>`entity_effects/DamageModificationEffect.java` (65) | `modifications`→`List<DamageModification>`/必需 | L17-19 |
| `breath_particles` | `BreathParticlesEffect`<br>`entity_effects/BreathParticlesEffect.java` (47) | `spread`→float/必需；`speed_per_growth`→float/必需；`main_particle`→`ParticleOptions`/必需；`secondary_particle`→`ParticleOptions`/必需 | L21-26 |
| `ignite` | `IgniteEffect`<br>`entity_effects/IgniteEffect.java` (24) | `ignite_ticks`→`LevelBasedValue`/必需 | L11-13 |
| `harvest_bonus` | `HarvestBonusEffect`<br>`entity_effects/HarvestBonusEffect.java` (69) | `harvest_bonuses`→`List<HarvestBonus>`/必需 | L17-19 |
| `on_attack` | `OnAttackEffect`<br>`entity_effects/OnAttackEffect.java` (57) | `potion`→`PotionData`/必需 | L21-23 |
| `flight` | `FlightEffect`<br>`entity_effects/FlightEffect.java` (90) | `level_requirement`→int/必需；`icon`→`ResourceLocation`/默认 `FlightData.DEFAULT_ICON` | L28-31 |
| `spin` | `SpinEffect`<br>`entity_effects/SpinEffect.java` (92) | `level_requirement`→int/必需；`fluid_types`→`HolderSet<FluidType>`/可选 | L31-34 |
| `item_conversion` | `ItemConversionEffect`<br>`entity_effects/ItemConversionEffect.java` (127) | `item_conversions`→`List<ItemConversionData>`/必需；`probability`→`LevelBasedValue`/必需。嵌套 `ItemConversionData`：`item_predicate`→`ItemPredicate`/必需，`items_to`→`WeightedRandomList<ItemTo>`/必需；嵌套 `ItemTo`：`item`→`Holder<Item>`/必需，`conversion_rate`→double/默认 `1.0`，`weight`→int/必需，`particles`→`ParticleData`/可选 | L30-33（嵌套 L35-39、L42-50） |
| `swim` | `SwimEffect`<br>`entity_effects/SwimEffect.java` (117) | `max_oxygen`→`LevelBasedValue`/默认 `constant(0)`；`has_stable_swim`→`LevelBasedBoolean`/默认 `constant(false)`；`fluid_type`→`Holder<FluidType>`/必需 | L38-44 |
| `effect_modification` | `EffectModificationEffect`<br>`entity_effects/EffectModificationEffect.java` (70) | `modifications`→`List<EffectModification>`/必需 | L18-20 |
| `particle` | `ParticleEffect`<br>`common_effects/ParticleEffect.java` (51)，**同时注册为 block effect** | `particle_data`→`SpawnParticles`/必需；`particle_count`→`LevelBasedValue`/必需 | L22-25 |
| `glow` | `GlowEffect`<br>`entity_effects/GlowEffect.java` (56) | `glows`→`List<Glow>`/必需 | L15-17 |
| `oxygen_bonus` | `OxygenBonusEffect`<br>`entity_effects/OxygenBonusEffect.java` (69) | `bonuses`→`List<OxygenBonus>`/必需 | L17-19 |
| `block_vision` | `BlockVisionEffect`<br>`entity_effects/BlockVisionEffect.java` (68) | `block_visions`→`List<BlockVision>`/必需 | L18-20 |
| `run_function` | `RunFunctionEffect`<br>`common_effects/RunFunctionEffect.java` (87)，**同时注册为 block effect** | `function`→`ResourceLocation`/必需 | L29-31 |
| `smelting` | `SmeltItemEffect`<br>`entity_effects/SmeltItemEffect.java` (115) | `item_predicate`→`ItemPredicate`/可选；`progress`→`LevelBasedValue`/可选；`grants_experience`→bool/默认 `true` | L41-45 |
| `heal` | `HealEffect`<br>`entity_effects/HealEffect.java` (51) | `percentage`→`LevelBasedValue`/必需（按最大生命值比例） | L24-26 |
| `teleport` | `TeleportEffect`<br>`entity_effects/TeleportEffect.java` (101) | `target_direction`→`TargetDirection`/必需；`range`→`LevelBasedValue`/必需 | L34-37 |
| `push` | `PushEffect`<br>`entity_effects/PushEffect.java` (70) | `target_direction`→`TargetDirection`/必需；`push_force`→`LevelBasedValue`/必需 | L33-36 |
| `hunger` | `HungerEffect`<br>`entity_effects/HungerEffect.java` (102) | `hunger_gain`→`LevelBasedValue`/可选；`saturation_gain`→`LevelBasedValue`/可选；`maximum_saturation`→`LevelBasedValue`/可选；`conversion_rate`→`LevelBasedValue`/可选 | L40-45 |
| `effect_removal` | `MobEffectRemovalEffect`<br>`entity_effects/MobEffectRemovalEffect.java` (118) | `categories`→`List<MobEffectCategory>`/可选；`valid_effects`→`HolderSet<MobEffect>`/可选；`max_amount`→`LevelBasedValue`/可选；`maximum_effect_level`→`LevelBasedValue`/可选 | L53-58 |
| `use_item` | `UseItemOnLivingEntityEffect`<br>`entity_effects/UseItemOnLivingEntityEffect.java` (56) | `item`→`ItemStack`/必需；`probability`→`LevelBasedValue`/默认 `constant(1)`；`sound`→`Holder<SoundEvent>`/可选；`valid_entities`→`EntityPredicate`/可选 | L22-28 |
| `dragon_growth` | `DragonGrowthEffect`<br>`entity_effects/DragonGrowthEffect.java` (144) | `growth_type`→`set`\|`add`/必需；`action_type`→`percent`\|`flat`/必需；`amount`→`LevelBasedValue`/必需；`probability`→`LevelBasedValue`/默认 `constant(1)` | L38-44（枚举 L108-138） |
| `mana_recovery` | `ManaRecoveryEffect`<br>`entity_effects/ManaRecoveryEffect.java` (128) | `action_type`→`set`\|`add`/必需；`adjustment_type`→`percent`\|`flat`/必需；`amount`→`LevelBasedValue`/必需；`probability`→`LevelBasedValue`/默认 `constant(1)` | L34-39 |
| `experience` | `ExperienceEffect`<br>`entity_effects/ExperienceEffect.java` (110) | `experience_type`→`levels`\|`points`/必需；`amount`→`LevelBasedValue`/必需；`probability`→`LevelBasedValue`/默认 `constant(1)` | L36-40（枚举 L83-87） |
| `cooldown_recovery` | `CooldownRecoveryEffect`<br>`entity_effects/CooldownRecoveryEffect.java` (173) | `abilities`→`HolderSet<DragonAbility>`/可选（缺省=目标全部能力）；`action_type`→`set`\|`reduce`/必需；`adjustment_type`→`percent`\|`flat`/必需；`amount`→`LevelBasedValue`/必需；`probability`→`LevelBasedValue`/默认 `constant(1)`；`exclude_this`→bool/默认 `true` | L52-59（枚举 L137-167） |
| `climbable` | `ClimbEffect`<br>`entity_effects/ClimbEffect.java` (65) | `climbables`→`List<Climbable>`/必需 | L17-19 |

### 7.1b block effect（`block_effects/AbilityBlockEffect.java:50-60`）

| `effect_type` | 类 / 文件 | 字段 | codec 行 |
|---|---|---|---|
| `bonemeal` | `BonemealEffect` (48) | `attempts`→`LevelBasedValue`/必需；`probability`→`LevelBasedValue`/必需 | L15-18 |
| `conversion` | `BlockConversionEffect` (70) | `conversion_data`→`List<BlockConversionData>`/必需；`probability`→`LevelBasedValue`/必需。嵌套 `BlockConversionData`：`from_predicate`→`BlockPredicate`/必需，`blocks_to`→`WeightedRandomList<BlockTo>`/必需；嵌套 `BlockTo`：`state`→`BlockState`/必需，`weight`→int/必需，`particles`→`ParticleData`/可选 | L25-28（嵌套 L30-42） |
| `summon_entity` | `SummonEntityEffect`（共用） | 见 8.1 | L89-100 |
| `fire` | `FireEffect` (46) | `ignite_probability`→`LevelBasedValue`/必需 | L19-21 |
| `area_cloud` | `AreaCloudEffect` (47) | `potion`→`PotionData`/必需；`duration`→`LevelBasedValue`/必需；`probability`→`LevelBasedValue`/必需；`delay`→`LevelBasedValue`/可选（运行时兜底 `constant(0)`）；`radius`→`LevelBasedValue`/可选（运行时兜底 `constant(1)`）；`particle`→`ParticleOptions`/必需 | L19-26 |
| `block_break` | `BlockBreakEffect` (38) | `valid_blocks`→`BlockPredicate`/必需；`probability`→`LevelBasedValue`/必需；`drop_loot`→bool/默认 `false` | L15-21 |
| `particle` | `ParticleEffect`（共用） | 见 8.1 | L22-25 |
| `run_function` | `RunFunctionEffect`（共用） | 见 8.1 | L29-31 |
| `use_item` | `UseItemOnBlockEffect` (66) | `item`→`ItemStack`/必需；`probability`→`LevelBasedValue`/默认 `constant(1)`；`sound`→`Holder<SoundEvent>`/可选；`valid_blocks`→`BlockPredicate`/可选 | L26-32 |
| `explosion` | `ExplodeBlockEffect` (35) | `probability`→`LevelBasedValue`/默认 `constant(1)`；`power`→`LevelBasedValue`/必需；`fire`→bool/默认 `true`；`damage_type`→`Holder<DamageType>`/必需 | L18-24 |
| `block_harvest` | `BlockHarvestEffect` (45) | `valid_blocks`→`BlockPredicate`/必需；`probability`→`LevelBasedValue`/默认 `constant(1)`；`tool`→`ItemStack`/可选 | L20-25 |

### 7.2 被上述效果引用的公共 codec 完整字段表

**`DurationInstanceBase`（`common/codecs/duration_instance/DurationInstanceBase.java:20-27`）** —— 所有 `extends DurationInstanceBase` 的效果都在嵌套 `"base"` 下带这些字段：

| 字段 | 类型 | 必需 | 默认 |
|---|---|---|---|
| `id` | `ResourceLocation` | ✅ | — |
| `duration` | `LevelBasedValue` | ❌ | `DragonAbilities.INFINITE_DURATION` = `LevelBasedValue.constant(-1)`（`DragonAbilities.java:95` + `DurationInstance.INFINITE_DURATION = -1`，`DurationInstance.java:33`） |
| `should_remove_automatically` | bool | ❌ | `false` |
| `early_removal_condition` | `LootItemCondition` | ❌ | 空 |
| `custom_icon` | `ResourceLocation` | ❌ | 空 |
| `is_hidden` | bool | ❌ | `false` |

继承 `DurationInstanceBase` 的 11 个效果：`SummonEntityEffect`、`ModifierWithDuration`、`DamageModification`、`EffectModification`、`Glow`、`OxygenBonus`、`HarvestBonus`、`Climbable`、`Fear`、`BlockVision`（`common/codecs/block_vision/BlockVision.java`）、`ModifierWithDuration`。
其中 8 个作为效果被引用：`modifier`(→`ModifierWithDuration`)、`damage_modification`、`effect_modification`、`glow`、`oxygen_bonus`、`harvest_bonus`、`climbable`、`block_vision`；`potion`/`on_attack` 用的是 `PotionData`（非 base 结构）。

**`ModifierWithDuration`（`common/codecs/ModifierWithDuration.java:44-47`）**：`base`(`DurationInstanceBase`/必需) + `modifiers`(`List<Modifier>`/必需)。

**`DamageModification`（`common/codecs/DamageModification.java:57-61`）**：`base`/必需 + `damage_types`(`HolderSet<DamageType>`/可选，缺省=所有伤害类型) + `multiplier`(`LevelBasedValue`/必需)。

**`EffectModification`（`common/codecs/EffectModification.java:56-63`）**：`base`/必需 + `effects`(`HolderSet<MobEffect>`/必需) + `duration_modification`(`Modification`/默认 `{type:"additive",amount:0}`) + `amplifier_modification`(`Modification`/默认同上)。
`Modification`（`common/codecs/Modification.java:10-13`）：`type`→`additive`\|`multiplicative`/必需；`amount`→`LevelBasedValue`/必需。

**`Glow`（`common/codecs/Glow.java:29-32`）**：`base`/必需 + `color`(`TextColor`/必需)。

**`OxygenBonus`（`common/codecs/OxygenBonus.java:52-56`）**：`base`/必需 + `fluid_types`(`HolderSet<FluidType>`/可选，缺省=所有流体) + `oxygen_bonus`(`LevelBasedValue`/必需)。

**`HarvestBonus`（`common/codecs/HarvestBonus.java:59-65`）**：`base`/必需 + `blocks`(`HolderSet<Block>`/可选) + `base_speed`(`LevelBasedTier`/可选) + `harvest_bonus`(`LevelBasedValue`/默认 `constant(0)`) + `break_speed_multiplier`(`LevelBasedValue`/默认 `constant(0)`)。
> ⚠️ JSON 名 `base_speed` 对应 Java 组件 `tiers`（`HarvestBonus::tiers`），是**已知的命名不一致**。

**`Climbable`（`common/codecs/Climbable.java:45-50`）**：`base`/必需 + `blocks`(`LevelBasedBlockPredicate`/必需) + `can_stick_to_walls`(`LevelBasedBoolean`/默认 `constant(false)`) + `can_climb_ceilings`(`LevelBasedBoolean`/默认 `constant(false)`)。

**`Fear`（`common/codecs/Fear.java:27-33`）** —— **不被任何 ability effect 引用**，只被 `registry/dragon/penalty/FearPenalty.java:18` 的 `fears` 列表使用：
`base`/必需 + `entity_condition`(`LootItemCondition`/可选) + `distance`(`LevelBasedValue`/必需) + `walk_speed`(`LevelBasedValue`/默认 `constant(1)`) + `sprint_speed`(`LevelBasedValue`/默认 `constant(1.3f)`)。
（`DEFAULT_WALK_SPEED = 1`、`DEFAULT_SPRINT_SPEED = 1.3f`，`Fear.java:24-25`。）

**`BlockVision`（`common/codecs/block_vision/BlockVision.java:55-70`）**：
`base`/必需 + `blocks`(`HolderSet<Block>`/必需) + `range`(`LevelBasedValue`/必需) + `display_type`(`outline`\|`particles`\|`simple_shader`\|`none`/必需) + `colors`(`Either<List<TextColor>, List<ColorEntry>>`/必需) + `particle_rate`(int, 1..MAX/默认 `10`) + `color_shift_rate`(double 0..10/默认 `1`)。
嵌套 `ColorEntry`（`:72-77`）：`color`(`TextColor`/必需) + `alpha`(float/默认 `0.3f`)。

**`ParticleData`（`common/codecs/ParticleData.java:11-14`）**：`particle_data`(`SpawnParticles`/必需) + `particle_count`(`LevelBasedValue`/必需)。
**`SpawnParticles`（`common/codecs/SpawnParticles.java:24-31`）**：`particle`(`ParticleOptions`/必需) + `horizontal_position`(`PositionSource`/必需) + `vertical_position`(`PositionSource`/必需) + `horizontal_velocity`(`VelocitySource`/必需) + `vertical_velocity`(`VelocitySource`/必需) + `speed`(`FloatProvider`/默认 `ConstantFloat.ZERO`)。

**`TargetDirection`（`common/codecs/TargetDirection.java:11-13`）**：`direction`(`Either<TargetDirection.Type, Direction>`/必需)；`Type` = `towards_entity` \| `looking_at`。

**`LevelBasedTier`（`common/codecs/LevelBasedTier.java:17-23`）**：`tiers`→`List<{tier: <Tiers 枚举常量名>, from_level: int(0..255)}>`/必需。
**`LevelBasedBoolean`（`common/codecs/LevelBasedBoolean.java:15-22`）**：`fallback`(bool/默认 `false`) + `entries`→`List<{value: bool, from_level: int}>`/必需。
**`LevelBasedBlockPredicate`（`common/codecs/LevelBasedBlockPredicate.java:18-25`）**：`fallback`(`BlockPredicate`/默认 `alwaysTrue`) + `entries`→`List<{value: BlockPredicate, from_level: int}>`/必需。

**`MiscCodecs`（`common/codecs/MiscCodecs.java`）关键工具**：
- `conditional(Codec<T>)`（`:82-84`）= `optionalCodec(ConditionalOps.createConditionalCodec(codec))` —— 让字段支持 `neoforge:conditions`/`neoforge:value` 包装。
- `expressionCodec(String... variables)`（`:56-72`）—— 校验表达式字符串；`DamageEffect` 只允许变量 `amount`、`scale`。
- `Bounds`（`:117-126`）：`min`/`max` 均必需；`bounds()`（`:128-136`）额外校验 `min>=1 && max>min`。
- `DestructionData`（`:138-159`）：`entity_predicate`、`block_predicate`、`crushing_growth`、`block_destruction_growth`、`crushing_damage_scalar` 全部必需。
- `enumCodec(Class<E>)`（`:22-31`）—— 用 `Enum.valueOf` + `Enum::name`，所以接受字符串是**枚举常量原样**（如 `LevelBasedTier` 的 `WOOD`/`STONE`/`IRON`/`DIAMOND`/`GOLD`/`NETHERITE`）。

### 7.3 明确的不存在项 / 陷阱

- `block_vision` 曾经有一个子类型 registry `dragonsurvival:block_vision_type`（`common/codecs/block_vision/BlockVisionType.java`），但它**整段被注释掉**：`//@EventBusSubscriber`（`BlockVisionType.java:15`），`register`/`registerEntries` 方法体是死代码，4 行 `event.register(...)` 全是注释占位（`:31-34`）。所以 `BlockVisionParticle`（`18 行`）**当前没有任何注册点**，`display_type`/`particle_rate` 是内联在 `BlockVision` 里的字段。
- 没有 `TargetType` 枚举（`AbilityTargeting` 只有嵌套 record `BlockTargeting`/`EntityTargeting`）。
- 没有 `UpgradeType.Type` 枚举；“手动升级”判定用的是 `UpgradeType.IS_MANUAL`（`UpgradeType.java:39`，`instanceof ExperiencePointsUpgrade`）。
- 没有 `EntityFilter` / `EffectFilter` 记录。
- `ResourceLocationWrapper` 是静态工具类（`common/codecs/ResourceLocationWrapper.java:33`），不是 record、没有字段表；它唯一与 codec 相关的方法是 `validatedCodec(): Codec<String>`（`:142-158`）。

### 7.4 定位（targeting）与触发（trigger）逐字段表

`ability_targeting` registry（`registry/dragon/ability/targeting/AbilityTargeting.java:120-124`）：

| `target_type` | 类 | 字段 |
|---|---|---|
| `area` | `AreaTarget` (72 行) | `applied_effects`/必需 + `radius`(`LevelBasedValue`/必需) |
| `dragon_breath` | `DragonBreathTarget` (106) | `applied_effects`/必需 + `range_multiplier`(`LevelBasedValue`/必需) |
| `looking_at` | `LookingAtTarget` (88) | `applied_effects`/必需 + `range`(`LevelBasedValue`/必需) |
| `self` | `SelfTarget` (55) | `applied_effects`/必需 |
| `disc` | `DiscTarget` (79) | `applied_effects`/必需 + `radius`(`LevelBasedValue`/必需) + `height`(`LevelBasedValue`/默认 `constant(1)`) + `height_starts_below`(bool/默认 `false`) |

`applied_effects`（`AbilityTargeting.java:108-110`）= `Codec.either(BlockTargeting.CODEC, EntityTargeting.CODEC).fieldOf("applied_effects")` —— **没有判别字段，先尝试 block 分支再尝试 entity 分支**（`BlockTargeting` 用 `block_effect`，`EntityTargeting` 用 `entity_effect` + `targeting_mode` + `is_harmful`，所以实际不会歧义）。

`activation_trigger` registry（`.../activation/trigger/ActivationTrigger.java:32-39`）：

| `trigger_type` | 类 | 字段 |
|---|---|---|
| `constant` | `ConstantTrigger` | 无字段（`MapCodec.unit`） |
| `on_self_hit` | `OnSelfHit` | `condition`(`LootItemCondition`/可选) |
| `on_target_hit` | `OnTargetHit` | `condition`(`LootItemCondition`/可选) |
| `on_target_killed` | `OnTargetKilled` | `condition`(`LootItemCondition`/可选) |
| `on_death` | `OnDeath` | 无字段（`MapCodec.unit`） |
| `on_block_break` | `OnBlockBreak` | `condition`(`LootItemCondition`/可选) |
| `on_key_pressed` | `OnKeyPressed` | `keys`(`List<String>`/必需，内部转 `HashSet`) |
| `on_key_released` | `OnKeyReleased` | `keys`(`List<String>`/必需，内部转 `HashSet`) |

`upgrade_type` registry 逐字段（`.../upgrade/UpgradeType.java:49-53`）：

| `upgrade_type` | 类 | 字段 |
|---|---|---|
| `experience_points` | `ExperiencePointsUpgrade` (98 行) | `maximum_level`(int 0..255/必需) + `experience_cost`(`LevelBasedValue`/必需) |
| `experience_levels` | `ExperienceLevelUpgrade` (53) | `maximum_level`(int 0..255/必需) + `level_requirement`(`LevelBasedValue`/必需) |
| `dragon_growth` | `DragonGrowthUpgrade` (53) | `maximum_level`(int 0..255/必需) + `growth_requirement`(`LevelBasedValue`/必需) |
| `item_based` | `ItemUpgrade` (78) | `items_per_level`(`List<HolderSet<Item>>`/必需) + `downgrade_items`(`HolderSet<Item>`/必需)；**无 `maximum_level`**，`maxLevel() = items_per_level.size()` |
| `condition_based` | `ConditionUpgrade` (83) | `conditions`(`List<LootItemCondition>`/必需) + `require_previous`(bool/默认 `true`)；**无 `maximum_level`**，`maxLevel() = conditions.size()` |

`maximum_level` 来自 `UpgradeType.codecStart`（`UpgradeType.java:57-59`）：
```java
static <V extends UpgradeType<?>> Products.P1<RecordCodecBuilder.Mu<V>, Integer> codecStart(final RecordCodecBuilder.Instance<V> instance) {
    return instance.group(ExtraCodecs.intRange(DragonAbilityInstance.MIN_LEVEL, DragonAbilityInstance.MAX_LEVEL).fieldOf("maximum_level").forGetter(UpgradeType::maxLevel));
}
```
`InputData`（`upgrade/InputData.java:11`）是纯内存载体，**没有 codec**；其枚举 `Type` = `experience_levels` \| `growth`（`:20-24`）。

**`Amount`/`Duration` 等字段的类型总结**：全部是 `LevelBasedValue`（原版），没有 DS 自定义的 provider。

---

## 9. 未找到 / 需要澄清的点

1. **`flight_level` 属性不存在**。搜索 `flight_level`（java + generated 资源）无任何命中。飞行相关只有 `dragonsurvival:flight_speed` 与 `dragonsurvival:flight_stamina`。
2. **`dragon_species` 没有 `growth` / `stages` / `start_stage` / `type` 字段**。JSON 字段名为 `starting_growth` 与 `custom_stage_progression`；起始 stage 由 growth 反查。
3. **`dragon_ability` 没有顶层 `mana_cost` / `cooldown` / `range` / `duration` / `effect_type` 字段**。`effect_type` 只出现在 `applied_effects.entity_effect[]` / `.block_effect[]` 的**元素**上。
4. **不存在 `dragonsurvival:modifier_with_duration` 这个 `effect_type`**；`modifier` 的 value 内部才是 `base` + `modifiers`。
5. **没有自定义 NumberProvider / ValueProvider**；`amount` 全部是原版 `LevelBasedValue`。
6. **没有 `AddReloadListenerEvent` / `RegistryDataLoader` 的使用**；重载钩子是 `TagsUpdatedEvent`。
7. **`dragon_stage` 没有显式的 next-stage 字段**；stage 链完全依赖 `growth_range` 数值首尾相接。
8. `DSDragonAbilityTags.java:116` 作者自己的 TODO 指出 order tag 的顺序保证存在疑问（但生成的 `order.json` 不含子 tag，顺序稳定）。

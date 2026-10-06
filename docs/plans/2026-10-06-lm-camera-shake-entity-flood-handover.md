# 悚域 camera_shake 实体洪水导致服务端主线程卡死 —— 根因分析与修复交接

**Date:** 2026-10-06
**Status:** 根因已定位并交叉验证；**修复未开始**
**接收方:** BeLoong-Core 侧会话
**提出方:** 整合包侧会话（本文作者只做了取证，未改动任何代码）
**适用版本:** BeLoong Core 0.10.1 · 传奇怪物 2.2.3 · MC 1.21.1 · NeoForge 21.1.248
**Core 基线:** `master` `eba35f7`（结构效果系统优化）
**故障实例:** `D:\ZonlongIX\BeLoong Server\[25565]delete-test`（联机测试服）
**原版源码:** `D:\Minecraft\开源模组参考文件\Legendary-Monsters-1.21.1-NeoForge`
**关联文档:** [`天灾传送门主线程死锁-根因与修复复盘.md`](../天灾传送门主线程死锁-根因与修复复盘.md)（同为"主线程卡死"家族，但**根因完全不同**，勿套用其结论）

> ### 📌 接收方须知（必读）
>
> 本文写在**整合包仓库**（`D:\BeLoong\.minecraft\versions\BeLoong\docs\plans\`），
> 但**修复动作全部在 Core 仓库**。请执行：
>
> 1. **把本文复制到 Core 仓库** `D:\Minecraft\BeLoong-Core\docs\plans\`
>    —— 本文的两条相对链接（`../天灾传送门主线程死锁-根因与修复复盘.md`、
>    `../reviews/2026-09-18-post-0.9.3-bug-list.md`）是**按 Core 仓库的目录结构写的**，
>    在当前整合包仓库里点不开，复制过去才正确。
> 2. 原始日志已归档在**整合包仓库**
>    `D:\BeLoong\.minecraft\versions\BeLoong\docs\evidence\2026-10-06-lm-camera-shake-crash\`
>    （**不要**复制进 Core，避免仓库里塞 750 KB 日志；复核命令见 §7.2）。
> 3. 传奇怪物源码在 `D:\Minecraft\开源模组参考文件\Legendary-Monsters-1.21.1-NeoForge`；
>    Core 侧的编译依赖已有该模组（`AnnihilationPursuerDamageCapMixin` 即引用其 `ModConfig`），
>    **写 Mixin 用编译期引用即可，不必依赖源码目录**。

---

## 〇、一句话结论

传奇怪物的 `legendary_monsters:camera_shake` 是一个**只能靠自身 `tick()` 自毁、不受任何实体上限约束、区块卸载后永不清除**的裸 `Entity`。
联机测试服悚域维度（`iceandfire_dreadland:dreadland`）累积到 **1,830,969 个**，玩家重新登录时主线程在
`ChunkMap$TrackedEntity.updatePlayer` 里给这一个玩家逐个下发实体配对包，**单 tick 超过 60 秒**被看门狗强杀。

**修复落在 Core 侧**（模组侧不可改）：需要给这个实体加**全局上限**与**残留清扫**。

---

## 一、现象

服务器在悚域测试传奇怪物时被 `ServerHangWatchdog` 强杀：

```
java.lang.Error: ServerHangWatchdog detected that a single server tick took 60000184.00 seconds (should be max 0.05)
	    at net.minecraft.server.level.ChunkMap$TrackedEntity.updatePlayer(ChunkMap.java:1299)
	    at net.minecraft.server.level.ChunkMap.move(ChunkMap.java:1002)
	    at net.minecraft.server.level.ServerChunkCache.move(ServerChunkCache.java:463)
	    at net.minecraft.server.network.ServerGamePacketListenerImpl.handleMovePlayer(ServerGamePacketListenerImpl.java:955)
	    at net.minecraft.network.protocol.game.ServerboundMovePlayerPacket.handle(ServerboundMovePlayerPacket.java:142)
```

- 崩溃报告 `Description:` 为 **`Watching Server`**（不是 `Exception in server tick loop`）
- `-- Head --` 一节即为完整栈，**无 `Caused by`** —— 不是抛异常，是主线程**卡死**
- 玩家事后可重新登录（实体数据仍完整），说明**无数据损坏**，只是同步不过来

**时间线**（`latest.log`，UTF-8，事故日志 4100 行）：

| 时刻 | 行号 | 事件 |
|---|---|---|
| 14:14:15 | 1225 | 玩家 `InkRedragon` 退出 |
| 14:14:17 / 14:14:22 | 1230 / 1240 | `Liger_dragon`、`SSSYunLong` **登录**（坐标分别在 `(7337,-22,2400)` 与 `(1155,65,1024)`） |
| 14:14:20 | 1235 | `Can't keep up! Running 2611ms or 52 ticks behind` ← **首次告警** |
| 14:15:06 | 1248 | `Liger_dragon was slain by Possessed Paladin`（在悚域打堕落圣骑） |
| 14:15:56 | 1249 | `Can't keep up! Running 2923ms or 58 ticks behind` |
| 14:16:05 | 1250 | spark: `Timed out waiting for world statistics` |
| 14:16:29 | 1251 | `SSSYunLong` 掉线 |
| **14:16:48** | 1254 | **`SSSYunLong` 重新登录** ← 触发器 |
| 14:16:56 | 1255 | 看门狗：`A single server tick took 60.00 seconds` |
| 14:17:07 | 1258 | 生成崩溃报告 |

> 复现特征：**玩家进入/重新登录到已有大量残留实体的维度**时触发，不是瞬时故障。

---

## 二、决定性证据：维度实体普查

崩溃报告 `-- Performance stats --`（`crash-2026-10-06_14.17.07-server.txt:2545`）：

```
ResourceKey[minecraft:dimension / iceandfire_dreadland:dreadland]:
  players: 1, entities: 1831330,1831330,143,625,625,0,0
  [legendary_monsters:camera_shake:1830969, minecraft:rabbit:67, minecraft:item:49,
   iceandfire:stymphalian_bird:39, iceandfire:dread_ghoul:34],
  block_entities: 126, block_ticks: 1065, fluid_ticks: 123,
  chunk_source: Chunks[S] W: 2209 E: 1831330,1831330,143,625,625,0,0
```

| 项 | 数值 |
|---|---|
| 悚域实体总数 | **1,831,330** |
| 其中 `camera_shake` | **1,830,969（99.98%）** |
| 其余全部生物 | **361** |
| 已加载区块 | 2209 |

对照同报告的主世界：`entities: 45,45,28,52,52,0,0` —— 正常运行时**单个玩家 45~52 个实体**。
悚域是它的 **4 万倍**。

### 2.1 两个线程正好互锁

| 线程 | 栈顶 | 含义 |
|---|---|---|
| **Server thread**（`:852`） | `ChunkMap$TrackedEntity.updatePlayer` | 主线程在"给该玩家逐个同步实体"的循环里 |
| **Netty Server IO #62**（`:2281`） | `JavaVelocityCipher.process` ← `AESCipher.engineUpdate` ← `MinecraftCipherEncoder.encode` | 网络线程在做 AES 加密封包，`Connection.doSendPacket$mixinextras$wrapped$83`（`:2336`） |

主线程在 `ChunkMap.move → TrackedEntity.updatePlayer` 里逐实体调用 `serverEntity.addPairing(player)`
（`ChunkMap.java:1336-1339`，条件成立即登记并发送实体生成包）；
网络线程被这百万级的小包淹没在 AES 加密里 —— 主线程推进不动，60 秒后看门狗开火。

> **行号说明：** 报告中的 `TrackedEntity.updatePlayer:1299` 与本机 1.21.1 源码的 `:1326` 差 27 行
> （NeoForge 21.1.248 对 `ChunkMap` 打过补丁，且该文件有 balm/ftbchunks/lithostitched 等 mixin）。
> **方法与调用路径一致，仅行号偏移**，不影响结论。判断依据是 `-- Head --` 与 `Server thread` 两处栈完全吻合。

### 2.2 已排除的其他假设

| 假设 | 排除依据 |
|---|---|
| 天灾传送门 `getChunk` 阻塞（0.9.1 老问题） | 本次栈里**没有** `DisasterPortalBlock`，且该问题 2026-09-12 已修 |
| 结构集 `exclusion_zone` 双向递归 | 本次**无 `StackOverflowError`**；该环 2026-09-12 已断 |
| 区块生成流水线卡死 | 无 `Worker-Main-*` 崩溃；`W: 2209` 区块已加载 |
| 单个 Boss 性能问题 | 1.8M 实体不是"一个 Boss 卡"，是**存量数据** |
| 内存不足 / GC | `-- System Details --` 无 OOM；且 `-XX:+DisableExplicitGC`（AllTheLeaks 注释） |

---

## 三、根因：`CameraShakeEntity` 的生命周期没有任何兜底

源码：`entity/AnimatedMonster/Effect/CameraShakeEntity.java`（全文件仅 118 行）

### 3.1 生成：无条件、无上限

```java
// CameraShakeEntity.java:111-116
public static void cameraShake(Level world, Vec3 position, float radius, float magnitude, int duration, int fadeDuration) {
    if (!world.isClientSide) {
        CameraShakeEntity cameraShake = new CameraShakeEntity(world, position, radius, magnitude, duration, fadeDuration);
        world.addFreshEntity(cameraShake);      // ← 无计数、无冷却、无并发限制
    }
}
```

### 3.2 注册：MISC 分类 + 裸 Entity

```java
// ModEntities.java:173-176
public static final Supplier<EntityType<CameraShakeEntity>> CAMERA_SHAKE = ENTITY_TYPES.register("camera_shake",
        () -> EntityType.Builder.<CameraShakeEntity>of(CameraShakeEntity::new, MobCategory.MISC)
                .sized(1F, 1F)
                .build(ResourceLocation.fromNamespaceAndPath(MOD_ID, "camera_shake").toString()));
```

```java
// CameraShakeEntity.java:19
public class CameraShakeEntity extends Entity {     // ← 不是 Mob
```

**没有 `noCulling`**（对比 `LightningBeamEntity.java:66`、`AnnihilationBeamEntity.java:126`、
`EnergyBeamEntity.java:70` 都显式设了 `noCulling = true`）。

### 3.3 下场：唯一出路是 `tick()` 自毁

```java
// CameraShakeEntity.java:47-51
@Override
public void tick() {
    super.tick();
    if (tickCount > getDuration() + getFadeDuration()) discard();
}
```

### 3.4 四个特征叠加 = 必然溢出

| 特征 | 依据 | 后果 |
|---|---|---|
| 不受刷怪上限约束 | `MobCategory.MISC` | 刷怪笼/生物上限管不到 |
| 不是 `Mob` | `extends Entity`（`:19`） | 无 `removeWhenFarAway` / 无自然消失 |
| 只能靠 `tick()` 自毁 | `:47-51` | **区块不 tick ⇒ 实体永久驻留** |
| 生成点极密、总数巨大 | 见 §四 | 存量增长快于清理 |

**"区块不 tick"这一条是长期堆积的关键**：玩家打完 Boss 离开悚域，那些区块卸载，
其中成千上万个 `camera_shake` 就**永远不会执行到 `discard()`**；下次玩家回来，
它们在 `ChunkMap` 里被立刻纳入追踪，于是就有了 1.83M。

### 3.5 旁证：模组作者自己撞过这个坑，但修错了地方

模组内 5 处写了这种防御：

```java
// Chorus_BombEntity.java:49-50
if (entity instanceof LivingEntity livingEntity && entity != this) {
    if (!(entity instanceof CameraShakeEntity)) {        // ← 永远为真，死代码
```

| 文件 | 行 |
|---|---|
| `Projectile/Chorus_BombEntity.java` | 50 |
| `Mobs/Withered_AbominationEntity.java` | 141 |
| `Mobs/Frostbitten_GolemEntity.java` | 315 |
| `Mobs/Overgrown_colossusEntity.java` | 130 |
| `Mobs/SkeletosaurusEntity.java` | 430 |

因为 `CameraShakeEntity extends Entity`（**不是** `LivingEntity`），外层
`instanceof LivingEntity` 已把它过滤掉，内层守卫**恒不可达**。
作者显然察觉了"特效实体被卷进生物逻辑"，但真正的问题（无限堆积）没堵上。

---

## 四、生成源清单（量级参考）

`CameraShakeEntity.cameraShake(` **生效调用点 182 处 / 41 个文件**
（统计口径：剔除整行 `//` 注释；源码 = `D:\Minecraft\开源模组参考文件\Legendary-Monsters-1.21.1-NeoForge\src`）

| 调用点 | 文件 |
|---|---|
| **46** | `entity/AnimatedMonster/IAnimatedBoss/PossessedPaladin/PossessedPaladinEntity.java` |
| **35** | `entity/AnimatedMonster/IAnimatedBoss/TheObliterator/TheObliteratorEntity.java` |
| 14 | `entity/AnimatedMonster/Mobs/CollapsedKingdom/BeheadedKnight/BeheadedKnightEntity.java` |
| 9 | `entity/AnimatedMonster/Mobs/AncientStronghold/Ancient_GuardianEntity.java` |
| 8 | `entity/AnimatedMonster/Mobs/Overgrown_colossusEntity.java` |
| 6 | `Mobs/Frostbitten_GolemEntity.java`、`Mobs/Chorusling/EndersentEntity.java`、`Mobs/SpaceStation/Flameborn/AnnihilationPursuer/AnnihilationPursuerEntity.java` |
| 5 | `CloudGolem/Cloud_GolemEntity.java`、`Mobs/SkeletosaurusEntity.java`、`Mobs/Withered_AbominationEntity.java` |
| ≤4 | 其余 30 个文件（投射物、物品、消息处理器、方块实体） |

**注意参数**：绝大多数调用传 `duration = 0`（如 `20.0F, 0.15F, 0, 20`），
即"立即进入淡出"，`discard()` 门限只有约 20 tick —— 在**正常 tick** 下能自清。
**所以问题从来不是"自毁条件写错"，而是"区块卸载后根本 tick 不到"。**

**事故相关**：`PossessedPaladin`（堕落圣骑）是调用点最密的 Boss（46 处），
且 `latest.log:1248` 正是 `Liger_dragon was slain by Possessed Paladin`。
但**不要据此只修圣骑** —— 1.83M 是全服长期累积，与悚域所有 LM 结构都有关。

---

## 五、⚠ 关键提醒：现成配置开关是无效的，不要浪费时间去试

`config/legendary_monsters-common.toml:285-287` 里确实有一项：

```toml
["Mob Settings"."General Settings"]
    #allow Camera Shake
    "Allow Camera Shake" = true
```

**它管不了这件事。** 全模组只有两处引用：

| 位置 | 用法 |
|---|---|
| `config/ModConfig.java:339` | `public final ModConfigSpec.BooleanValue allowCameraShake;` |
| `client/event/ClientEvent.java:240` | `if (ModConfig.MOB_CONFIG.allowCameraShake.get() && !Minecraft.getInstance().isPaused()) { ... }` |

**只在客户端渲染时读一次**（`Dist.CLIENT` 路径）。关掉它只会让画面不抖，
**服务端照旧 `addFreshEntity`、照旧进 `ChunkMap`、照旧下发追踪包**。

> 因此：**`"Allow Camera Shake" = false` 不是修复方案**，只是掩盖症状。
> 建议整合包侧在本项上方补一行注释说明"此项仅影响客户端视觉，不阻止服务端生成实体"，
> 避免后续会话误以为关掉开关就解决了。

---

## 六、Core 侧候选修复方案

### 6.1 推荐方案：`legendarymonsters` 包下新增上限 Mixin

**位置**：`src/main/java/com/zonlong/beloong/mixin/legendarymonsters/CameraShakeCapMixin.java`
（新文件，与既有 `AnnihilationPursuerDamageCapMixin.java` 同包）

**注册**：`src/main/resources/beloong.mixins.json` 的 `mixins` 数组追加
`"legendarymonsters.CameraShakeCapMixin"`（放在既有的
`"legendarymonsters.AnnihilationPursuerDamageCapMixin"` 相邻位置）

**必须遵守本项目的可选依赖约定**（见
[`reviews/2026-09-18-post-0.9.3-bug-list.md`](../reviews/2026-09-18-post-0.9.3-bug-list.md) 严重级第 2 条——
该条已明确"5 个里唯一照做的是 `AnnihilationPursuerDamageCapMixin`"）：

```java
@Pseudo
@Mixin(value = CameraShakeEntity.class, remap = false)
```

并给每个 `@Inject` 加 `require = 0`。

**两个注入点：**

**① 入口限流（治本，阻止继续堆积）** —— 注入静态工厂 `cameraShake`：

```java
// 目标：CameraShakeEntity.java:111
public static void cameraShake(Level world, Vec3 position, float radius,
                               float magnitude, int duration, int fadeDuration)
```

建议双重闸门（具体阈值由 Core 侧定，以下为量级建议）：

| 闸门 | 建议 | 理由 |
|---|---|---|
| **每维度在存量上限** | 例如 200 ~ 500 | 超过即 `return`。`MobCategory.MISC` 不占刷怪上限，必须自建计数 |
| **同位置短冷却** | 同 (x,z) 在 5 tick 内只放行一个 | 消除"同一次爆炸被多路径重复生成"的放大 |

计数实现建议：`ServerLevel` 维度 key → 计数。**最稳的是不自己维护计数器**，
而是在入口用 `level.getEntitiesOfClass(CameraShakeEntity.class, 大 AABB)` 之类**周期采样**，
或维护一个"每 tick 重新统计、写入 `ServerLevel` 自定义 attachment / 静态 `WeakHashMap<ServerLevel, Integer>`"的缓存，
避免与 `discard()` 路径不同步导致计数只增不减。

> ⚠ 这是本方案**唯一容易写错的地方**：一旦计数器泄漏（生成 +1、`discard()` 没 -1），
> 上限会永久饱和，抖动效果**彻底消失**且难以察觉。建议**不要**做增量计数，
> 改为"每 N tick 用一次 `getEntities` 重新数"或"用 `ServerLevel` 的实体列表按类型过滤"
> —— 悚域有 1.8M 实体的场景下，**采样频率必须低**（如每 20 tick 一次），并且
> **只在确实需要判断时才统计**（例如先做便宜的位置冷却，通过后再统计）。

**② 存量清扫（治标，处理已污染的存档）** —— 注入 `CameraShakeEntity#tick`（`:47`）
或挂 `ServerLevel` 每 N tick 的清扫逻辑：

- 清掉"已超出 `duration + fadeDuration` 却仍在世界里的"实体
- 清掉坐标所在区块**长期未加载**的残留（可用 `level.isLoaded(pos)` 或 chunk holder 状态判别）
- **必须限制每 tick 清算量**（例如每次最多 200 个），否则 1.8M 规模下"清扫"本身就会变成新的卡死源

### 6.2 备选：NeoForge 事件拦截

在 `EntityJoinLevelEvent` 里对 `legendary_monsters:camera_shake` 计数，超阈值 `event.setCanceled(true)`。

| 优点 | 缺点 |
|---|---|
| 不触碰 mixin 约定，纯事件代码，最好维护 | 无法区分"玩家身边正常抖动"与"远处残留堆积"，阈值定小会误伤手感 |
| 上限发生时只依赖实体类型，不需要访问模组内部字段 | `setCanceled(true)` 的副作用（实体是否已被纳入 `ChunkMap`、是否留下半初始化状态）**请 Core 侧自行实测确认**——本文未验证此语义 |

若 Core 侧已有 `EntityJoinLevelEvent`（或 `EntityJoinLevelEvent` 之外的
`EntityTravelToDimensionEvent` 等）的使用先例，**这条路线性价比可能更高**（更少 mixin 风险）。

### 6.3 被否方案

| 方案 | 否决理由 |
|---|---|
| 把 `"Allow Camera Shake" = false` 当作修复 | 见 §五 —— 只在客户端读，服务端照旧生成 |
| 降低悚域 LM 结构密度 / 移除悚域 LM 结构 | 只降低生成速率，**不能清除已有 1.8M**，治不了本次故障；且与整合包已定稿的悚域设计冲突（见 `docs/plans/2026-08-23-legendary-monsters-dreadland-migration-design.md`） |
| 直接删悚域 `entities/` 目录文件 | 可以用作**紧急一次性手段**（见 §七 第 1 步），但不是可重复的工程方案 |
| 升级传奇怪物到新版本 | 上游**未修**此问题：`CameraShakeEntity.java` 自 `Dynamic Camera Zoom` 系列提交（`0dac08f` 等）以来，`cameraShake` 与 `tick` 的逻辑未见兜底改动；其 git log 里没有相关修复提交 |
| 在 `mods.toml` 里把传奇怪物改为必需并锁死版本 | 与本 bug 无关；但它**确实是可选依赖**，mixin 必须 `@Pseudo` + `require = 0`，否则模组缺席时启动崩溃 |

---

## 七、取证材料与复核命令

### 7.1 原始材料（**只读**，已归档入库）

两份日志已**逐字节原样复制**到整合包仓库，**引用请用本目录路径**：

| 材料 | 归档路径 | 行数 | SHA256 |
|---|---|---|---|
| 服务端日志 | `docs\evidence\2026-10-06-lm-camera-shake-crash\latest.log` | 4100 | `e2d0c85d2c624f337866f73cde0c88ec133bedc45b04e5ef15cff1e3d3a9fb94` |
| 崩溃报告 | `docs\evidence\2026-10-06-lm-camera-shake-crash\crash-2026-10-06_14.17.07-server.txt` | 2838 | `7a55c5acf3fdc701f3ae9eff92bad2fbd8c3028c589bbb81ebfbed1ea99500e5` |

（上表路径相对整合包仓库根 `D:\BeLoong\.minecraft\versions\BeLoong\`；
副本 SHA256 已与原附件核对一致。该目录另有 `README.md` 说明来源与复核入口。）

> ⚠ **编码**：`latest.log` 的服务端自身输出是 **GBK**（`[0610月2026 ...]`），
> PowerShell 读取必须 `[System.Text.Encoding]::GetEncoding(936)`，否则中文全乱。
> 崩溃报告是 UTF-8。

**故障实例不在本机**：`D:\ZonlongIX\BeLoong Server` 在当前环境**不可访问**（`Test-Path` = False）。
本文所有"实例侧"证据均来自上述两份日志，**未直接检查服务端存档**（见 §九 第 4 条）。

### 7.2 复核命令

**A. 确认实体普查（最关键的一步）**

```powershell
$crash = 'docs\evidence\2026-10-06-lm-camera-shake-crash\crash-2026-10-06_14.17.07-server.txt'
Select-String -Path $crash -Pattern 'camera_shake' | ForEach-Object { $_.Line.Trim() }
# 期望看到：entities: 1831330 ... [legendary_monsters:camera_shake:1830969, ...]
```

**B. 确认两线程互锁**

```powershell
# Server thread 的栈
Select-String -Path $crash -Pattern '"Server thread"' -Context 0,6
# Netty 加密线程
Select-String -Path $crash -Pattern 'CipherFeedback.encrypt|MinecraftCipherEncoder' |
  Select-Object -First 5
```

**C. 确认配置开关无效（源码级）**

```powershell
$lm = 'D:\Minecraft\开源模组参考文件\Legendary-Monsters-1.21.1-NeoForge\src'
# 全模组只有 3 处命中
Select-String -Path "$lm\*.java" -Recurse -Pattern 'allowCameraShake' |
  ForEach-Object { "$($_.Path.Replace($lm,'')):$($_.LineNumber)  $($_.Line.Trim())" }
# 期望：ModConfig.java:339（声明）、ModConfig.java:783（定义）、ClientEvent.java:240（唯一使用点）
```

**D. 确认生成点密度**

```powershell
$lm = 'D:\Minecraft\开源模组参考文件\Legendary-Monsters-1.21.1-NeoForge\src'
Get-ChildItem $lm -Recurse -Filter *.java | ForEach-Object {
  $c = 0
  Get-Content $_.FullName | ForEach-Object {
    if ($_ -match 'CameraShakeEntity\.cameraShake\(' -and $_ -notmatch '^\s*//') { $c++ }
  }
  if ($c) { [pscustomobject]@{ N = $c; File = $_.FullName.Replace("$lm\", '') } }
} | Sort-Object N -Descending | Select-Object -First 8
# 期望：PossessedPaladinEntity 45 / TheObliteratorEntity 35 / BeheadedKnightEntity 14 ...
```

**E. 扫描存档里的堆积情况（整合包侧已提供工具）**

`D:\BeLoong\.minecraft\versions\BeLoong\docs\tools\count-camera-shake.py`
（Anvil region 解析器，已用 zlib 解压 + NBT 断言校验过，纯只读）

```powershell
cd 'D:\BeLoong\.minecraft\versions\BeLoong\docs\tools'
# 单个存档：输出非空 chunk 数 / 含 camera_shake 的 chunk 数 / 出现总次数 / 各字段分布
python count-camera-shake.py "..\saves\<存档名>\dimensions\iceandfire_dreadland\dreadland\entities"
```

> **本文作者已跑过的结论**：整合包侧 **全部 37 个本地测试存档均为 0**
> （已扫描 `region/` 与 `entities/` 两处）。
> ⇒ **该问题未在本地单人测试复现，只在联机测试服上发生**，符合"反复进出悚域、打完就走"的累积机理。
> 因此**不要**指望本地存档能复现——验收必须上联机服（见 §八）。

### 7.3 紧急止血（非工程修复，供处置现网用）

```mcfunction
# 逐维度执行；1.8M 规模下建议分区块跑，或直接停服清理
/kill @e[type=legendary_monsters:camera_shake]
/kill @e[type=legendary_monsters:dynamic_camera_zoom]
```

更彻底的方式是**停服**后删除该维度目录下的实体数据：

```
world/dimensions/iceandfire_dreadland/dreadland/entities/
```

（区块地形保留，只丢实体。**执行前务必备份**。）

---

## 八、验收协议

### 前置

1. 用本次构建的 `build/libs/beloong-<新版本>.jar` 覆盖服务端 `mods/` 下对应 jar
2. 确认改动已进入 `beloong.mixins.json` 的 `mixins` 数组
3. `gradlew.bat build` 通过；启动日志中 **不得出现**
   `Mixin apply ... failed` / `@Mixin target ... was not found`

### 第 0 步｜确认上限生效（静态）

```
/execute in iceandfire_dreadland:dreadland run summon legendary_monsters:possessed_paladin ...
```
或直接对 Boss 触发抖动技能，观察 `camera_shake` 数量**是否稳定收敛在阈值附近**：

```mcfunction
/execute in iceandfire_dreadland:dreadland run execute if entity @e[type=legendary_monsters:camera_shake]
```

建议 Core 侧加一条 **ASCII 锚点日志**（本项目惯例，见
`天灾传送门主线程死锁-根因与修复复盘.md` 第三节第 4 条：
实例日志是 GBK，中文锚点不便脚本判读），例如：
`[BeLoongCore][CameraShake:cap] dim=... count=... suppressed=...`

### 第 1 步｜确认存量被清（关键回归）

在**已被污染的存档**上（或先用 §7.3 复制一份污染存档）执行 `-- Performance stats --` 观察：

```
# 期望：camera_shake 计数从 7 位数降到阈值量级
```

获取方式：服务端执行任意触发崩溃报告的命令不便，可改用：

```powershell
# 整合包侧工具，直接数磁盘上的实体数据
python docs\tools\count-camera-shake.py "<存档>\dimensions\iceandfire_dreadland\dreadland\entities"
```

### 第 2 步｜复现原故障场景（**这是真正的验收点**）

1. 两名玩家同时在线
2. 一名在悚域打 LM Boss（堕落圣骑 / 湮灭构造体优先）
3. 该玩家**掉线 → 重新登录**
4. **期望**：不出现
   - `A single server tick took 60.00 seconds`
   - `Can't keep up! Is the server overloaded?`
   - 崩溃报告 `Description: Watching Server`
5. **期望**：`Server thread` 不再停在 `ChunkMap$TrackedEntity.updatePlayer`

### 第 3 步｜回归（确认没修坏）

| 项 | 期望 |
|---|---|
| 正常 Boss 战 | 屏幕抖动**仍然存在**且手感与修复前无可见差异（验证上限阈值不过紧） |
| 传奇怪物缺席 | 移除 `[传奇怪物] legendary_monsters-*.jar` 后服务端**能正常启动**（验证 `@Pseudo` + `require = 0`） |
| 悚域常规探索 | `Can't keep up!` 不新增 |
| 其他维度 | 主世界/天灾/龙宫实体数无异常增长 |

### 日志判据（PowerShell，注意实例日志是 GBK 936）

```powershell
$log = '<服务端>\logs\latest.log'
$lines = [System.IO.File]::ReadAllLines($log, [System.Text.Encoding]::GetEncoding(936))
'--- 卡死证据（修复后应无新增）---'
($lines | Select-String -Pattern 'A single server tick took|Watching Server|Can''t keep up').Count
'--- 本次修复的锚点 ---'
$lines | Select-String -Pattern '\[BeLoongCore\]\[CameraShake:' | ForEach-Object { $_.Line }
```

---

## 九、尚未知 / 需 Core 侧自行确认的事项

1. **上限阈值该取多少**：本文只给出量级（200~500/维度）。需要实机测"多少并发抖动实体仍能保证手感"，
   建议先用可配置项（Core 已有 `ModConfig` 体系）落地，便于调参。
2. **`ServerLevel` 实体计数的最优实现**：本文给的两条路线（周期采样 / 非增量缓存）各有取舍，
   未在 1.8M 实体规模下实测过性能，请自行评估。
3. **`dynamic_camera_zoom` 是否有同类问题**：`ModEntities.java:178-181` 与 `camera_shake` 注册方式完全相同
   （`MobCategory.MISC` + 裸 Entity）。本次事故统计里**没有出现它**，但**建议一并加同类上限**，
   理由见其注册代码与 `camera_shake` 逐字对称。
4. **服务端存档未直接检查**：本文未能访问 `D:\ZonlongIX\BeLoong Server`，
   `1,830,969` 这个数字来自崩溃报告的运行时统计而非磁盘扫描。若需要磁盘级确认，
   请向用户索取该存档的 `dimensions/iceandfire_dreadland/dreadland/` 目录。
5. **是否需要同步修整合包侧配置注释**（§五）：属整合包侧改动，本文未执行，已单独提示。

---

## 十、教训（供后续会话）

1. **"特效实体"是最容易被忽视的无界容器**。原版有 `MobCategory` 刷怪上限、`Mob#removeWhenFarAway`、
   `EntityType` 的 `noCulling` 等多层兜底；一旦第三方模组用**裸 `Entity` + `MISC` 分类**
   做纯视觉特效，这些兜底**全部不适用**，而它的自毁只依赖 `tick()` —— **区块卸载就不 tick 了**。
2. **"我关了配置开关" ≠ "问题被解决"**。本 bug 的配置项名字极具误导性（`Allow Camera Shake`），
   实际只在 `Dist.CLIENT` 路径读取。**判断一个开关是否有效，必须看它的全部引用点，而不是它的名字。**
3. **崩溃报告的 `-- Performance stats --` 是这类问题的第一现场**。
   本次若只看主栈（`updatePlayer` —— 看起来像普通的实体同步代码），很难想到真凶在**维度实体普查**里。
   **"栈说在哪卡"与"什么数据导致卡"是两个独立问题，都要查。**
4. **不要看到"主线程卡死"就套用同项目的历史结论**。本项目已有一份
   `天灾传送门主线程死锁` 复盘，但那是 `getChunk` 阻塞 + `exclusion_zone` 递归环；
   本次是**实体洪水**，两者唯一的共同点是"都卡主线程"。**先看 `-- Head --` 与 `-- Performance stats --` 再下判断。**
5. **模组作者的防御代码可能是死代码**。`if (!(entity instanceof CameraShakeEntity))` 出现在 5 个文件里，
   看起来很像是"已经处理过了"，实际恒不可达。
   **看到防御性代码要先验证它可达**，否则会得出"这里没问题"的错误结论。
6. **交叉验证要动到磁盘**。本文用 Anvil region 解析器扫描了全部 37 个本地存档
   （结果全为 0），从而确认"这是联机服特有的累积问题"，
   避免了"本地无法复现 ⇒ 结论存疑"的误判，也避免了让 Core 侧在本地无效地复现。

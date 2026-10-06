# 事故取证归档：2026-10-06 悚域 camera_shake 实体洪水

本目录保存 **2026-10-06 联机测试服服务端卡死事故**的原始日志，供 BeLoong-Core 侧修复时复核。

> **分析结论（不要只看原始日志，先读交接文档）：**
> [`../../plans/2026-10-06-lm-camera-shake-entity-flood-handover.md`](../../plans/2026-10-06-lm-camera-shake-entity-flood-handover.md)

---

## 文件清单

| 文件 | 大小 | SHA256 | 说明 |
|---|---|---|---|
| `latest.log` | 476,303 B | `e2d0c85d2c624f337866f73cde0c88ec133bedc45b04e5ef15cff1e3d3a9fb94` | 服务端完整会话日志，4100 行，覆盖 14:02:13 启动 → 14:17:13 崩溃 |
| `crash-2026-10-06_14.17.07-server.txt` | 272,233 B | `7a55c5acf3fdc701f3ae9eff92bad2fbd8c3028c589bbb81ebfbed1ea99500e5` | 崩溃报告，2838 行，含完整线程转储与**维度实体普查** |

两份文件均为**逐字节原样复制**，SHA256 已与本目录的副本核对一致。

> 编码说明：`latest.log` 的**服务端自身输出为 GBK**（如 `[0610月2026 ...]`）。
> 用 PowerShell 读取需显式指定：`[System.Text.Encoding]::GetEncoding(936)`。
> 崩溃报告为 UTF-8。

---

## 原始来源

两份文件原本由用户以附件形式提供，DSH 会话附件缓存路径为：

```
D:\DSH Latest\dsh-home\attachments\v1\files\e2\e2d0c85d...\latest.log
D:\DSH Latest\dsh-home\attachments\v1\files\7a\7a55c5ac...\crash-2026-10-06_14.17.07-server.txt
```

**该缓存可能被清理**，故复制入库。本目录是长期归档，引用时请用本目录路径。

**服务端实例本身已不可访问**（`D:\ZonlongIX\BeLoong Server` 在当前环境不存在），
因此以下内容**没有**原始材料，如需请另行索取：

- 服务端存档 `world/dimensions/iceandfire_dreadland/dreadland/`（磁盘级实体数据）
- 崩溃报告之外的更早日志（`logs/` 中更早的 `latest.log.*` / `debug.log`）
- spark 性能剖析结果

---

## 复核入口（按此顺序看）

1. **崩溃报告 `-- Performance stats --` 段**（约 2539 行起）
   → 悚域 `entities: 1831330` 其中 `legendary_monsters:camera_shake:1830969`。**这是全案最关键的一行。**

2. **崩溃报告 `-- Head --` 段**（第 36 行起）
   → `ChunkMap$TrackedEntity.updatePlayer` ← `ChunkMap.move` ← `handleMovePlayer`，**无 `Caused by`**。

3. **崩溃报告线程转储**（第 60 行起）
   → `"Server thread"`（第 852 行）与 `"Netty Server IO #62"`（第 2281 行）互锁。

4. **`latest.log` 时间线**（1225–1258 行）
   → 玩家掉线 → **重登** → 8 秒后看门狗开火。触发点在 `:1254`。

---

## 分析工具

扫描存档中该实体堆积情况的解析器：

```
docs/tools/count-camera-shake.py
```

用法与结果见交接文档 §7.2 的 E 节。

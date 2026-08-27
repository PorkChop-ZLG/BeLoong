# 传奇怪物数值调整清单（legendary_monsters-common.toml）

> 应用方式：关闭 Minecraft / 相关 Java 进程后，将下列值写入 `config/legendary_monsters-common.toml`。
> 所有倍率均为一位小数。
> 伤害上限请使用 **1000**（模组配置允许的最大值），不要使用 1000，否则模组会回退。

---

## 通用

| 配置项 | 新值 |
|---|---|
| `"MiniBoss DamageCap"` | `1000` |

---

## 三大 Boss

| 配置项 | 新值 |
|---|---|
| `"Cloud Golem Health Multiplier"` | `17.5` |
| `"Cloud Golem Damage Multiplier"` | `12.5` |
| `"Cloud Golem Damage Cap"` | `1000` |
| `"Posessed Paladin Health Multiplier"` | `17.5` |
| `"Posessed Paladin Damage Multiplier"` | `16.6` |
| `"Damage Cap"` | `1000` |
| `"The Obliterator Health Multiplier"` | `18.0` |
| `"The Obliterator Damage Multiplier"` | `20.4` |
| `DamageCap` | `1000` |

---

## MiniBoss（按流程顺序）

| 顺序 | MiniBoss | Health Multiplier | Damage Multiplier |
|---|---:|---:|---:|
| 1 | 沙丘哨兵 | `"Dune Sentinel Health Multiplier" = 11.8` | `"Dune Sentinel Damage Multiplier" = 7.5` |
| 2 | 霜冻傀儡 | `"Frostbitten Golem Health Multiplier" = 10.9` | `"Frostbitten Golem Damage Multiplier" = 10.4` |
| 3 | 蔓生巨像 | `"Overgrown Colosuss Health Multiplier" = 16.5` | `"Overgrown Colosuss Damage Multiplier" = 9.1` |
| 4 | 荒古守卫者 | `"Ancient Guardian Health Multiplier" = 18.8` | `"Ancient Guardian Damage Multiplier" = 9.4` |
| 5 | 噬焰蜥 | `"Lava Eater Health Multiplier" = 20.6` | `"Lava Eater Damage Multiplier" = 9.4` |
| 6 | 凋零恶煞 | `"Withered Abomination Health Multiplier" = 20.0` | `"Withered Abomination Damage Multiplier" = 7.9` |
| 7 | 骸骨巨龙 | `"Skeletosaurus Health Multiplier" = 20.0` | `"Skeletosaurus Damage Multiplier" = 12.9` |
| 8 | 复生骑士 | `"Resurrected Knight Health Multiplier" = 22.1` | `"Resurrected Knight Damage Multiplier" = 12.7` |
| 9 | 无头骑士 | `"Beheaded Knight Health Multiplier" = 23.1` | `"Beheaded Knight Damage Multiplier" = 11.8` |
| 10 | 紫颂遣使 | `"Endersent Health Multiplier" = 22.5` | `"Endersent Damage Multiplier" = 12.7` |
| 11 | 潜影拟态者 | `"Shulker Mimic Health Multiplier" = 24.0` | `"Shulker Mimic Damage Multiplier" = 14.0` |
| 12 | 湮灭猎影 | `"Annihilation Pursuer Health Multiplier" = 23.8` | `"Annihilation Pursuer Damage Multiplier" = 13.3` |

---

## 说明

- 小怪数值不调整。
- 所有倍率均按“一位小数”设计。
- 伤害上限统一改为 1000，等效于移除原版伤害限制。
- 当前检测到游戏进程正在运行，配置会被游戏回写；请关闭游戏后再应用本清单。

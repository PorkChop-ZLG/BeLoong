# -*- coding: utf-8 -*-
# 校验饰品收购价 = 饰品商店价 / 2，并确认饰品商店与其他分类未被改动。
import sys
from pathlib import Path

import nbtlib

TOOLS_DIR = Path(__file__).resolve().parent
PACK_ROOT = TOOLS_DIR.parent.parent
SHOP = PACK_ROOT / "ldlib2" / "assets" / "viscript_shop" / "shop" / "beloong.shop"

ok = True


def chk(cond, msg):
    global ok
    print(("  [OK]   " if cond else "  [FAIL] ") + msg)
    if not cond:
        ok = False


nbt = nbtlib.load(str(SHOP))
cats = {str(c["id"]): c for c in nbt["categoryInfos"]}


def money_map(cid):
    return {str(m["itemResult"]["item"]["id"]): float(m["money"])
            for m in cats[cid]["merchants"]}


buy = money_map("curios_bug")
sell = money_map("curios_sell")

print(f"文件: {SHOP}")
print(f"version_num = {int(nbt['version_num'])}   分类数 = {len(cats)}")
print()

print("=== 饰品收购 = 饰品商店 / 2 ===")
chk(set(buy) == set(sell), f"两边物品集合一致（{len(buy)} / {len(sell)}）")
bad = [(i, buy[i], sell[i]) for i in buy if i in sell and sell[i] * 2 != buy[i]]
chk(not bad, f"全部 {len(buy)} 条满足 回收价 × 2 = 出售价（异常 {len(bad)} 条）")
for i, b, s in bad:
    print(f"        异常: {i} 出售={b:.0f} 回收={s:.0f}")

nonint = [(i, s) for i, s in sell.items() if s != int(s)]
chk(not nonint, "回收价均为整数")
print()

print("=== 饰品商店价格分布（应为你手动设置的 5 档）===")
from collections import Counter
dist = Counter(int(v) for v in buy.values())
for price, n in sorted(dist.items()):
    print(f"  {price:>8} 货币 -> {n} 条")
chk(set(dist) <= {10000, 30000, 60000, 100000, 200000}, "价格档位符合手动设置")
print()

print("=== 饰品商店交易类型未变 ===")
bad_trade = [str(m["itemResult"]["item"]["id"]) for m in cats["curios_bug"]["merchants"]
             if not str(m["tradeType"]).endswith(".buy")]
chk(not bad_trade, "饰品商店全部为 buy")

print("=== 饰品收购交易类型 ===")
bad_trade2 = [str(m["itemResult"]["item"]["id"]) for m in cats["curios_sell"]["merchants"]
              if not str(m["tradeType"]).endswith(".sell")]
chk(not bad_trade2, "饰品收购全部为 sell")
print()

print("=== 其他分类完整性 ===")
expect = {"loong_palace_bug": 35, "loong_palace_sell": 19,
          "loong_palace_exchange": 4, "building_materials": 169}
for cid, n in expect.items():
    got = len(cats[cid]["merchants"])
    chk(got == n, f"{cid}: {got} 条 (期望 {n})")
print()

print("=== 完整对照表（前 10 + 后 5）===")
rows = [(i.split(":")[1], buy[i], sell[i]) for i in buy]
for name, b, s in rows[:10] + [("…", 0, 0)] + rows[-5:]:
    if name == "…":
        print("  …")
    else:
        print(f"  {name:<28} 出售 {b:>10.0f}   回收 {s:>10.0f}")
print()

print("=== 结论 ===")
print("全部通过" if ok else "存在失败项")
sys.exit(0 if ok else 1)

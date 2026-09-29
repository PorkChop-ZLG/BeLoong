# -*- coding: utf-8 -*-
# 按「饰品商店」(curios_bug) 的出售价重算「饰品收购」(curios_sell) 的回收价。
# 回收价 = 出售价 / 2，逐条按物品 ID 配对（不依赖列表顺序）。
#
# 只修改 curios_sell 的 money 字段，不动 curios_bug，也不动其他分类。
# 若某条回收价不是整数，会报错退出（避免静默取整）。
#
# 用法: python update-artifacts-sell-price.py [--dry-run] [-i <shop文件>]
import argparse
import shutil
import sys
from pathlib import Path

import nbtlib
from nbtlib.tag import Double

TOOLS_DIR = Path(__file__).resolve().parent
PACK_ROOT = TOOLS_DIR.parent.parent
DEFAULT_SHOP = PACK_ROOT / "ldlib2" / "assets" / "viscript_shop" / "shop" / "beloong.shop"

BUY_CAT = "curios_bug"    # 饰品商店（不修改）
SELL_CAT = "curios_sell"  # 饰品收购（只改这个）


def item_id(merchant):
    return str(merchant["itemResult"]["item"]["id"])


def main():
    ap = argparse.ArgumentParser(description="重算饰品收购价 = 饰品商店价 / 2")
    ap.add_argument("-i", "--input", default=str(DEFAULT_SHOP))
    ap.add_argument("--dry-run", action="store_true", help="只报告，不写入")
    ap.add_argument("--no-backup", action="store_true")
    args = ap.parse_args()

    shop_path = Path(args.input)
    if not shop_path.exists():
        sys.exit(f"找不到商店文件: {shop_path}")

    nbt = nbtlib.load(str(shop_path))
    cats = {str(c["id"]): c for c in nbt["categoryInfos"]}
    for cid in (BUY_CAT, SELL_CAT):
        if cid not in cats:
            sys.exit(f"缺少分类 {cid}")

    buy_map = {}
    for m in cats[BUY_CAT]["merchants"]:
        iid = item_id(m)
        if iid in buy_map:
            sys.exit(f"饰品商店存在重复物品: {iid}")
        buy_map[iid] = float(m["money"])

    sell_merchants = cats[SELL_CAT]["merchants"]
    sell_ids = [item_id(m) for m in sell_merchants]
    if len(set(sell_ids)) != len(sell_ids):
        sys.exit("饰品收购存在重复物品")
    missing = [i for i in sell_ids if i not in buy_map]
    if missing:
        sys.exit(f"以下物品在饰品商店中不存在，无法定价: {missing}")

    # 计算目标价并检查整除性
    changes = []
    for iid, price in buy_map.items():
        half = price / 2
        if half != int(half):
            sys.exit(f"{iid} 的出售价 {price:.1f} 不是偶数，半数非整数")
    for m in sell_merchants:
        iid = item_id(m)
        old = float(m["money"])
        new = buy_map[iid] / 2
        if old != new:
            changes.append((iid, old, new))

    # 报告
    print(f"商店文件 : {shop_path}")
    print(f"配对方式 : 按物品 ID（饰品商店 {len(buy_map)} 条 / 饰品收购 {len(sell_merchants)} 条）")
    print(f"需修改   : {len(changes)} 条；保持原价 {len(sell_merchants) - len(changes)} 条")
    print()
    if changes:
        print(f"{'物品':<30} {'原回收价':>12} {'新回收价':>12} {'对应出售价':>12}")
        print("-" * 70)
        for iid, old, new in changes:
            print(f"{iid.split(':')[1]:<30} {old:>12.0f} {new:>12.0f} {buy_map[iid]:>12.0f}")
        print()

    if args.dry_run:
        print("--dry-run：未写入")
        return

    if not args.no_backup:
        bak = shop_path.with_suffix(shop_path.suffix + ".bak")
        shutil.copy2(shop_path, bak)
        print(f"已备份 -> {bak}")

    for m in sell_merchants:
        m["money"] = Double(buy_map[item_id(m)] / 2)

    nbt.save(str(shop_path))
    print(f"已写入 -> {shop_path}（修改 {len(changes)} 条）")


if __name__ == "__main__":
    main()

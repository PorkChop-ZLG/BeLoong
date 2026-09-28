# -*- coding: utf-8 -*-
# 读取 ViScriptShop 商店文件(.shop, gzip+NBT)，导出为结构化 JSON。
#
# 格式依据：ViScriptShop 源码 Shop.java
#   - Shop.FORMAT = EditorFileFormat.compressed(...)  -> 文件是 gzip 压缩
#   - Shop.java 用 NbtIo.readCompressed() 读取        -> 压缩内容为 NBT
#   - Shop.serializeNBT() = shopInfo.serializeNBT()   -> 根结构就是 ShopInfo
#
# 结构与字段（与源码 gui/data 下的数据类一一对应）：
#   ShopInfo      name, version_num, isQuickOpening, promotionEnabled,
#                 promotionAggregation, lockedMerchantVisibility, categoryInfos[]
#   CategoryInfo  id, name, shopType{currency|item_for_item}, iconType,
#                 iconItem{id,count}, flagGroups[], lockMessages[], merchants[]
#   MerchantInfo  id, stock, xp, tradeType{buy|sell}, money,
#                 itemA/itemB{item{id,count}, matchRule, display},
#                 itemResult{item{id,count}, display}, commands[], flagGroups[]
#
# 依赖: nbtlib   安装: python -m pip install nbtlib
# 用法: python read-viscriptshop-nbt.py [-i <商店文件>] [-o <输出JSON>]
#   默认读取 <整合包>/ldlib2/assets/viscript_shop/shop/ 下全部 .shop 文件，
#   输出到 docs/tools/out/<商店名>.json
import argparse
import json
import sys
from pathlib import Path

import nbtlib

# 本脚本位于 <整合包>/docs/tools/，据此定位整合包根目录与默认输出目录
TOOLS_DIR = Path(__file__).resolve().parent
PACK_ROOT = TOOLS_DIR.parent.parent
DEFAULT_SHOP_DIR = PACK_ROOT / "ldlib2" / "assets" / "viscript_shop" / "shop"
DEFAULT_OUT_DIR = TOOLS_DIR / "out"

# enum backing keys -> readable labels
SHOP_TYPE = {
    "viscript_shop.data.category.shopType.currency": "currency",
    "viscript_shop.data.category.shopType.item_for_item": "item_for_item",
}
TRADE_TYPE = {
    "viscript_shop.data.merchant.tradeType.buy": "buy",
    "viscript_shop.data.merchant.tradeType.sell": "sell",
}


def s(v):
    """NBT String -> python str."""
    return str(v) if v is not None else ""


def item_of(compound, key="item"):
    """Extract {id, count} from a MerchantItemInfo/MerchantCostItemInfo compound."""
    if compound is None:
        return None
    node = compound.get(key)
    if node is None:
        return None
    iid = s(node.get("id"))
    if not iid:
        return None
    cnt = node.get("count")
    return {"id": iid, "count": int(cnt) if cnt is not None else 1}


def flags(cat_or_merchant):
    """Collect lock flags from flagGroups."""
    out = []
    for grp in cat_or_merchant.get("flagGroups", []) or []:
        mode = s(grp.get("mode", ""))
        for f in grp.get("flags", []) or []:
            out.append({"mode": mode, "flag": s(f)})
    return out


def money(v):
    if v is None:
        return None
    f = float(v)
    return int(f) if f == int(f) else f


def read_shop(shop_path):
    """解析单个 .shop 文件，返回结构化 dict。"""
    shop_path = Path(shop_path)
    nbt = nbtlib.load(str(shop_path))

    shop = {
        "file": str(shop_path),
        "name": s(nbt.get("name")),
        "version_num": int(nbt.get("version_num", 0)),
        "isQuickOpening": bool(nbt.get("isQuickOpening", 0)),
        "promotionEnabled": bool(nbt.get("promotionEnabled", 0)),
        "promotionAggregation": s(nbt.get("promotionAggregation")),
        "lockedMerchantVisibility": s(nbt.get("lockedMerchantVisibility")),
    }

    categories = []
    for cat in nbt.get("categoryInfos", []) or []:
        raw_type = s(cat.get("shopType"))
        c = {
            "id": s(cat.get("id")),
            "name": s(cat.get("name")),
            "shopType": SHOP_TYPE.get(raw_type, raw_type),
            "iconItem": item_of({"item": cat.get("iconItem")}),
            "stageRestrictionEnabled": bool(cat.get("stageRestrictionEnabled", 0)),
            "flags": flags(cat),
            "merchants": [],
        }
        for m in cat.get("merchants", []) or []:
            raw_trade = s(m.get("tradeType"))
            mer = {
                "id": s(m.get("id")),
                "stock": int(m.get("stock", -1)),
                "xp": int(m.get("xp", 0)),
                "tradeType": TRADE_TYPE.get(raw_trade, raw_trade),
                "money": money(m.get("money")),
                "result": item_of(m.get("itemResult")),
                "costA": item_of(m.get("itemA")),
                "costB": item_of(m.get("itemB")),
                "commands": [s(x) for x in (m.get("commands", []) or [])],
                "flags": flags(m),
            }
            c["merchants"].append(mer)
        categories.append(c)

    shop["categories"] = categories
    shop["stats"] = {
        "categories": len(categories),
        "merchants": sum(len(c["merchants"]) for c in categories),
    }
    return shop


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="解析 ViScriptShop 商店文件(.shop, gzip+NBT)")
    ap.add_argument("-i", "--input", help="单个 .shop 文件；缺省则扫描默认商店目录下全部 .shop")
    ap.add_argument("-o", "--outdir", default=str(DEFAULT_OUT_DIR), help="JSON 输出目录")
    args = ap.parse_args()

    if args.input:
        targets = [Path(args.input)]
    else:
        targets = sorted(DEFAULT_SHOP_DIR.glob("*.shop"))
        if not targets:
            sys.exit(f"未找到 .shop 文件: {DEFAULT_SHOP_DIR}")

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    for tgt in targets:
        data = read_shop(tgt)
        out_path = outdir / (tgt.stem + ".json")
        out_path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        st = data["stats"]
        print(f"{tgt.name} -> {out_path.name}")
        print(f"  商店: {data['name']}  v{data['version_num']}")
        print(f"  分类 {st['categories']} 个 / 商品 {st['merchants']} 条")
        for c in data["categories"]:
            print(f"    - {c['name']} [{c['shopType']}] merchants={len(c['merchants'])}")

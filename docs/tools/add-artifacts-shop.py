# -*- coding: utf-8 -*-
# 把「奇异饰品」(artifacts) 的全部饰品批量写入 beloong.shop 的
# 「饰品商店」(curios_bug) 与「饰品收购」(curios_sell) 两个分类。
#
# 做法：以现有商品的 NBT 结构为模板深拷贝（保证字段类型与游戏规范序列化一致），
#       只替换 itemResult.item.id 与 money / stock / tradeType / id。
#
# 物品清单与顺序来自 artifacts 模组 ModItems.class 的 <clinit>（= 创造模式物品栏注册顺序），
#       已通过 en_us.json 的 item.artifacts.<id> 语言键校验。
#
# 用法: python add-artifacts-shop.py [-i <shop文件>] [--dry-run]
import argparse
import copy
import shutil
import sys
import uuid
from pathlib import Path

import nbtlib
from nbtlib.tag import Compound, Double, Int, List, String

TOOLS_DIR = Path(__file__).resolve().parent
PACK_ROOT = TOOLS_DIR.parent.parent
DEFAULT_SHOP = PACK_ROOT / "ldlib2" / "assets" / "viscript_shop" / "shop" / "beloong.shop"

NS = "artifacts"

# 创造栏顺序（ModItems.<clinit> 注册顺序），已排除刷怪蛋 mimic_spawn_egg
ARTIFACT_IDS = [
    "umbrella", "everlasting_beef", "eternal_steak", "plastic_drinking_hat",
    "novelty_drinking_hat", "snorkel", "night_vision_goggles", "villager_hat",
    "superstitious_hat", "cowboy_hat", "anglers_hat", "lucky_scarf",
    "scarf_of_invisibility", "cross_necklace", "panic_necklace", "shock_pendant",
    "flame_pendant", "thorn_pendant", "charm_of_sinking", "charm_of_shrinking",
    "cloud_in_a_bottle", "obsidian_skull", "antidote_vessel", "universal_attractor",
    "crystal_heart", "helium_flamingo", "chorus_totem", "warp_drive",
    "digging_claws", "feral_claws", "power_glove", "fire_gauntlet",
    "pocket_piston", "vampiric_glove", "golden_hook", "onion_ring",
    "pickaxe_heater", "withered_bracelet", "aqua_dashers", "bunny_hoppers",
    "kitty_slippers", "running_shoes", "snowshoes", "steadfast_spikes",
    "flippers", "rooted_boots", "strider_shoes", "whoopee_cushion",
]

SLOTS = {
    "curios_bug": {"money": 10000.0, "stock": 10, "trade": "buy", "label": "饰品商店"},
    "curios_sell": {"money": 5000.0, "stock": 5, "trade": "sell", "label": "饰品收购"},
}

ATTR = "viscript_shop.data.merchant"
PRODUCT_NS = uuid.UUID("6f1b9a2c-3d4e-4f50-8a6b-7c8d9e0f1a2b")


def stable_uuid(cat_id, item_id):
    """由分类与物品 ID 派生稳定 UUID，保证脚本可重复运行结果一致。"""
    return str(uuid.uuid5(PRODUCT_NS, f"{cat_id}|{item_id}"))


def build_merchant(template, cat_id, item_id, spec):
    """深拷贝模板商品，替换物品 ID 与数值。"""
    m = copy.deepcopy(template)

    # itemResult.item = {count:1, id:<artifacts:xxx>}
    m["itemResult"]["item"]["count"] = Int(1)
    m["itemResult"]["item"]["id"] = String(f"{NS}:{item_id}")

    m["money"] = Double(spec["money"])
    m["stock"] = Int(spec["stock"])
    m["tradeType"] = String(f"{ATTR}.tradeType.{spec['trade']}")
    m["xp"] = Int(0)
    m["id"] = String(stable_uuid(cat_id, item_id))
    # 清空可选字段，避免从模板继承
    m["commands"] = List[String]([])
    m["flagGroups"] = List[Compound]([])
    m["lockMessages"] = List[String]([])
    m["promotionRules"] = List[Compound]([])
    return m


def main():
    ap = argparse.ArgumentParser(description="批量写入奇异饰品商店")
    ap.add_argument("-i", "--input", default=str(DEFAULT_SHOP), help=".shop 文件路径")
    ap.add_argument("--no-backup", action="store_true", help="跳过备份（默认会备份）")
    ap.add_argument("--dry-run", action="store_true", help="只报告，不写入")
    args = ap.parse_args()

    shop_path = Path(args.input)
    if not shop_path.exists():
        sys.exit(f"找不到商店文件: {shop_path}")

    nbt = nbtlib.load(str(shop_path))
    cats = nbt["categoryInfos"]
    by_id = {str(c["id"]): c for c in cats}

    plan = {}
    templates = {}
    for cat_id, spec in SLOTS.items():
        if cat_id not in by_id:
            sys.exit(f"商店文件里没有分类 {cat_id}（{spec['label']}）")
        cat = by_id[cat_id]
        ms = cat["merchants"]
        if len(ms) == 0:
            sys.exit(f"分类 {cat_id} 没有任何商品，无法取得结构模板")
        templates[cat_id] = copy.deepcopy(ms[0])
        plan[cat_id] = build_all(templates[cat_id], cat_id, spec)

    # 报告
    print(f"商店文件: {shop_path}")
    print(f"物品数  : {len(ARTIFACT_IDS)}")
    print()
    for cat_id, spec in SLOTS.items():
        print(f"  [{spec['label']}] {cat_id}: "
              f"{len(plan[cat_id])} 条, money={spec['money']:.0f}, "
              f"stock={spec['stock']}, tradeType={spec['trade']}")
    print()

    if args.dry_run:
        print("--dry-run：未写入。前 5 条预览：")
        for m in plan["curios_bug"][:5]:
            print(f"  {m['itemResult']['item']['id']}  "
                  f"money={float(m['money']):.0f} stock={int(m['stock'])}")
        return

    if not args.no_backup:
        bak = shop_path.with_suffix(shop_path.suffix + ".bak")
        shutil.copy2(shop_path, bak)
        print(f"已备份 -> {bak}")

    # 应用并写回
    for cat_id, merchants in plan.items():
        by_id[cat_id]["merchants"] = List[Compound](merchants)

    nbt.save(str(shop_path))
    print(f"已写入 -> {shop_path}")
    for cat_id, spec in SLOTS.items():
        print(f"  {spec['label']}: {len(plan[cat_id])} 条")


def build_all(template, cat_id, spec):
    return [build_merchant(template, cat_id, iid, spec) for iid in ARTIFACT_IDS]


if __name__ == "__main__":
    main()

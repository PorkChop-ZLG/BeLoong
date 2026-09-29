# -*- coding: utf-8 -*-
# 校验 beloong.shop 写入结果：饰品商店/饰品收购 的商品数量、数值、顺序与结构完整性。
import sys
from pathlib import Path

import nbtlib

TOOLS_DIR = Path(__file__).resolve().parent
PACK_ROOT = TOOLS_DIR.parent.parent
SHOP = PACK_ROOT / "ldlib2" / "assets" / "viscript_shop" / "shop" / "beloong.shop"

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
EXPECT = {
    "curios_bug": {"money": 10000.0, "stock": 10, "trade": "buy", "label": "饰品商店"},
    "curios_sell": {"money": 5000.0, "stock": 5, "trade": "sell", "label": "饰品收购"},
}
EXPECT_OTHER = {  # 其他分类应保持原样
    "loong_palace_bug": 35, "loong_palace_sell": 19,
    "loong_palace_exchange": 4, "building_materials": 169,
}

ok = True


def chk(cond, msg):
    global ok
    print(("  [OK]   " if cond else "  [FAIL] ") + msg)
    if not cond:
        ok = False


nbt = nbtlib.load(str(SHOP))
cats = {str(c["id"]): c for c in nbt["categoryInfos"]}

print(f"文件: {SHOP}")
print(f"根 version_num = {int(nbt['version_num'])} (期望 7)")
print(f"分类总数 = {len(cats)} (期望 6)")
print()

print("=== 其他分类未受影响 ===")
for cid, n in EXPECT_OTHER.items():
    got = len(cats[cid]["merchants"])
    chk(got == n, f"{cid}: {got} 条 (期望 {n})")
print()

for cid, spec in EXPECT.items():
    cat = cats[cid]
    ms = cat["merchants"]
    print(f"=== {spec['label']} ({cid}) ===")
    chk(len(ms) == 48, f"商品数 = {len(ms)} (期望 48)")

    ids = [str(m["itemResult"]["item"]["id"]) for m in ms]
    expect_ids = [f"artifacts:{i}" for i in ARTIFACT_IDS]
    chk(ids == expect_ids, "物品顺序与创造栏顺序一致")

    bad_money = [i for i, m in enumerate(ms) if float(m["money"]) != spec["money"]]
    chk(not bad_money, f"所有 money = {spec['money']:.0f}（异常 {len(bad_money)} 条）")

    bad_stock = [i for i, m in enumerate(ms) if int(m["stock"]) != spec["stock"]]
    chk(not bad_stock, f"所有 stock = {spec['stock']}（异常 {len(bad_stock)} 条）")

    trade_field = f"viscript_shop.data.merchant.tradeType.{spec['trade']}"
    bad_trade = [i for i, m in enumerate(ms) if str(m["tradeType"]) != trade_field]
    chk(not bad_trade, f"所有 tradeType = {spec['trade']}（异常 {len(bad_trade)} 条）")

    bad_count = [i for i, m in enumerate(ms) if int(m["itemResult"]["item"]["count"]) != 1]
    chk(not bad_count, "所有 itemResult.item.count = 1")

    # 结构完整性：模板关键字段必须齐全
    need_m = {"itemResult", "itemA", "itemB", "money", "stock", "xp", "tradeType",
              "id", "commands", "flagGroups", "lockMessages", "promotionRules",
              "promotionEnabled", "inheritParentPromotions", "promotionAggregation",
              "flagGroupMode", "stageRestrictionEnabled"}
    miss = [str(ms[0]["itemResult"]["item"]["id"])] if not need_m <= set(ms[0].keys()) else []
    chk(not miss, f"商品字段完整（缺: {sorted(need_m - set(ms[0].keys())) or '无'}）")

    uuids = [str(m["id"]) for m in ms]
    chk(len(set(uuids)) == len(uuids), "商品 id 唯一")

    print(f"  前 3 条: {[i.split(':')[1] for i in ids[:3]]}")
    print(f"  后 3 条: {[i.split(':')[1] for i in ids[-3:]]}")
    print()

print("=== 结论 ===")
print("全部通过" if ok else "存在失败项，请检查")
sys.exit(0 if ok else 1)

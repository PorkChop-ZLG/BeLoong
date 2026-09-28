# -*- coding: utf-8 -*-
# 把 read-viscriptshop-nbt.py 导出的商店 JSON 渲染成可读的 Markdown 清单。
#
# 输入: docs/tools/out/*.json （由 read-viscriptshop-nbt.py 生成）
# 输出: docs/tools/out/*_summary.md
#
# 用法: python summarize-viscriptshop.py [-i <商店JSON>] [-o <输出md>]
#   缺省渲染 out/ 目录下全部商店 JSON
import argparse
import json
import sys
from collections import Counter
from pathlib import Path

# 本脚本位于 <整合包>/docs/tools/
TOOLS_DIR = Path(__file__).resolve().parent
DEFAULT_OUT_DIR = TOOLS_DIR / "out"
STOCK_INF = "无限"


def render(d):
    """把单个商店 dict 渲染成 markdown 行列表。"""
    L = []
    w = L.append

    w(f"# {d['name']} — 商店内容清单")
    w("")
    w(f"- 文件：`{d['file']}`")
    w(f"- 数据版本：v{d['version_num']}　快速打开：{d['isQuickOpening']}　促销：{d['promotionEnabled']}")
    w(f"- 分类 **{d['stats']['categories']}** 个，商品条目 **{d['stats']['merchants']}** 条")
    w("")

    for cat in d["categories"]:
        w(f"## {cat['name']}")
        w("")
        w(f"- 分类 ID：`{cat['id']}`")
        w(f"- 类型：`{cat['shopType']}`" + ("（货币交易）" if cat["shopType"] == "currency" else "（以物换物）"))
        if cat["iconItem"]:
            w(f"- 图标：`{cat['iconItem']['id']}`")
        if cat["flags"]:
            w(f"- 解锁条件：{len(cat['flags'])} 条 flag")
        w("")

        buys = [m for m in cat["merchants"] if m["tradeType"] == "buy"]
        sells = [m for m in cat["merchants"] if m["tradeType"] == "sell"]

        # 以物换物分类用物品计价，货币分类用 money 计价
        is_i4i = cat["shopType"] == "item_for_item" or any(
            m["costA"] or m["costB"] for m in cat["merchants"]
        )

        def price_txt(m):
            if is_i4i:
                parts = []
                for k in ("costA", "costB"):
                    c = m[k]
                    if c:
                        parts.append(f"`{c['id']}` x{c['count']}")
                return " + ".join(parts) if parts else "—"
            return f"{m['money']} 货币" if m["money"] is not None else "—"

        def stock_txt(m):
            return STOCK_INF if m["stock"] < 0 else str(m["stock"])

        for label, rows in (("买入 (buy)", buys), ("收购 (sell)", sells)):
            if not rows:
                continue
            w(f"### {label}　共 {len(rows)} 条")
            w("")
            w("| # | 产出/物品 | 价格 | 库存 | XP |")
            w("|---|---|---|---|---|")
            for i, m in enumerate(rows, 1):
                res = m["result"] or {}
                rid = res.get("id", "—")
                rc = res.get("count", 1)
                name = f"`{rid}`" + (f" x{rc}" if rc != 1 else "")
                w(f"| {i} | {name} | {price_txt(m)} | {stock_txt(m)} | {m['xp']} |")
            w("")

        ncmd = [m for m in cat["merchants"] if m["commands"]]
        if ncmd:
            w(f"<details><summary>含指令的商品（{len(ncmd)} 条）</summary>")
            w("")
            for m in ncmd:
                w(f"- `{(m['result'] or {}).get('id','—')}` → {m['commands']}")
            w("")
            w("</details>")
            w("")

    allm = [m for c in d["categories"] for m in c["merchants"]]
    mods = Counter((m["result"] or {}).get("id", "?").split(":")[0] for m in allm)
    w("## 统计")
    w("")
    w(f"- 商品总条目：{len(allm)}")
    w(f"- 涉及模组命名空间：{len(mods)} 个")
    w("")
    w("| 命名空间 | 条目数 |")
    w("|---|---|")
    for mod, n in mods.most_common():
        w(f"| `{mod}` | {n} |")
    w("")
    return L


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="把商店 JSON 渲染成 Markdown 清单")
    ap.add_argument("-i", "--input", help="单个商店 JSON；缺省则渲染 out/ 下全部")
    ap.add_argument("-o", "--output", help="输出 md 路径（仅单文件模式可用）")
    args = ap.parse_args()

    if args.input:
        srcs = [Path(args.input)]
    else:
        srcs = sorted(DEFAULT_OUT_DIR.glob("*.json"))
        if not srcs:
            sys.exit(f"未找到商店 JSON: {DEFAULT_OUT_DIR}")

    for src in srcs:
        d = json.loads(src.read_text(encoding="utf-8"))
        lines = render(d)
        out = Path(args.output) if (args.output and len(srcs) == 1) \
            else src.with_name(src.stem + "_summary.md")
        out.write_text("\n".join(lines), encoding="utf-8")
        print(f"{src.name} -> {out.name}  ({len(lines)} 行)")

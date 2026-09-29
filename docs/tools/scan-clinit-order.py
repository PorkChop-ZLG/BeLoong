# -*- coding: utf-8 -*-
# 解析 .class 文件 <clinit> 字节码，提取 ldc_w(String) 与 getstatic(ModItems字段) 的配对顺序。
# 用于还原创造模式物品栏 displayItems 的实际注册顺序。
import struct
import sys

# 各操作码的操作数长度
OPERAND_LEN = {
    0x10: 1, 0x11: 2, 0x12: 1, 0x13: 2, 0x14: 2, 0x15: 1, 0x16: 1, 0x17: 1, 0x18: 2, 0x19: 1,
    0x36: 1, 0x37: 1, 0x38: 1, 0x39: 1, 0x3a: 1, 0x3b: 1, 0x3c: 1, 0x3d: 1,
    0x84: 2,
    0x99: 2, 0x9a: 2, 0x9b: 2, 0x9c: 2, 0x9d: 2, 0x9e: 2, 0x9f: 2,
    0xa0: 2, 0xa1: 2, 0xa2: 2, 0xa3: 2, 0xa4: 2, 0xa5: 2, 0xa6: 2, 0xa7: 2, 0xa8: 2,
    0xa9: 1,
    0xb2: 2, 0xb3: 2, 0xb4: 2, 0xb5: 2, 0xb6: 2, 0xb7: 2, 0xb8: 2, 0xb9: 2, 0xba: 2,
    0xbb: 2, 0xbc: 1, 0xbd: 2, 0xbe: 0, 0xbf: 2, 0xc0: 2, 0xc1: 2,
    0xc5: 3, 0xc6: 2, 0xc7: 2, 0xc8: 4, 0xc9: 4,
    0xca: 3, 0xcb: 3, 0xcc: 0, 0xcd: 0, 0xce: 0, 0xcf: 0, 0xd0: 0, 0xd1: 0, 0xd2: 0, 0xd3: 0,
    0xd4: 0, 0xd5: 0, 0xd6: 0, 0xd7: 0, 0xd8: 2, 0xd9: 2, 0xda: 2, 0xdb: 2, 0xdc: 2, 0xdd: 2,
    0xde: 2, 0xdf: 2, 0xe0: 2, 0xe1: 2, 0xe2: 2, 0xe3: 2, 0xe4: 2, 0xe5: 2, 0xe6: 2,
    0xe7: 2, 0xe8: 2, 0xe9: 4, 0xea: 4, 0xeb: 4, 0xec: 4, 0xed: 4, 0xee: 4, 0xef: 4,
    0xf0: 4, 0xf1: 4, 0xf2: 4, 0xf3: 4, 0xf4: 4, 0xf5: 4, 0xf6: 4, 0xf7: 4, 0xf8: 4,
    0xf9: 4, 0xfa: 4, 0xfb: 4, 0xfc: 4, 0xfd: 4, 0xfe: 4, 0xff: 4,
}


def parse(path):
    b = open(path, "rb").read()
    p = 8
    cp_count = struct.unpack_from(">H", b, p)[0]
    p += 2
    cp = {}
    i = 1
    while i < cp_count:
        tag = b[p]
        p += 1
        if tag == 1:
            ln = struct.unpack_from(">H", b, p)[0]
            p += 2
            cp[i] = ("Utf8", b[p:p + ln].decode("utf-8", "replace"), None)
            p += ln
        elif tag in (7, 8, 16, 19, 20):
            cp[i] = (tag, struct.unpack_from(">H", b, p)[0], None)
            p += 2
        elif tag == 15:
            cp[i] = (tag, b[p], struct.unpack_from(">H", b, p + 1)[0])
            p += 3
        elif tag in (3, 4, 9, 10, 11, 12, 17, 18):
            cp[i] = (tag, struct.unpack_from(">I", b, p)[0], None)
            p += 4
        elif tag in (5, 6):
            cp[i] = (tag, struct.unpack_from(">Q", b, p)[0], None)
            p += 8
            i += 1
        else:
            raise ValueError(f"unknown cp tag {tag}")
        i += 1

    def utf(idx):
        e = cp.get(idx)
        return e[1] if e and e[0] == "Utf8" else None

    def cls_name(idx):
        e = cp.get(idx)
        if e and e[0] == 7:
            return utf(e[1])
        return None

    p += 6
    ic = struct.unpack_from(">H", b, p)[0]
    p += 2 + 2 * ic

    def skip_attrs(p):
        n = struct.unpack_from(">H", b, p)[0]
        p += 2
        for _ in range(n):
            ln = struct.unpack_from(">I", b, p + 2)[0]
            p += 6 + ln
        return p

    # 跳过字段
    fc = struct.unpack_from(">H", b, p)[0]
    p += 2
    for _ in range(fc):
        p += 6
        p = skip_attrs(p)
    # 跳过方法
    mc = struct.unpack_from(">H", b, p)[0]
    p += 2
    methods = []
    for _ in range(mc):
        acc, ni, di = struct.unpack_from(">HHH", b, p)
        p += 6
        ac = struct.unpack_from(">H", b, p)[0]
        p += 2
        code = None
        for _ in range(ac):
            an = utf(struct.unpack_from(">H", b, p)[0])
            alen = struct.unpack_from(">I", b, p + 2)[0]
            if an == "Code":
                clen = struct.unpack_from(">I", b, p + 6)[0]
                code = b[p + 10: p + 10 + clen]
            p += 6 + alen
        methods.append((utf(ni), utf(di), code))
    return cp, utf, cls_name, methods


def scan_clinit(cp, utf, cls_name, methods, self_class):
    """扫描全部方法，找出引用本类物品字段的 getstatic 聚簇（创造栏 displayItems 顺序）。"""
    ITEM_TYPES = {"Holder", "Item", "ItemLike", "RegistryHolder"}
    for name, desc, code in methods:
        if not code:
            continue
        refs = []
        pos = 0
        while pos < len(code):
            op = code[pos]
            if op == 0xB2:  # getstatic
                idx = struct.unpack_from(">H", code, pos + 1)[0]
                e = cp.get(idx)
                if e and e[0] == 9:
                    cn = cls_name(e[1])
                    nt = cp.get(e[2])
                    if nt and cn == self_class:
                        fname = utf(nt[1])
                        fdesc = utf(nt[2]) or ""
                        simple = fdesc.split("/")[-1].rstrip(";")
                        if simple in ITEM_TYPES and fname not in ("ITEMS", "CREATIVE_MODE_TABS", "CREATIVE_TAB"):
                            refs.append(fname)
            pos += 1 + OPERAND_LEN.get(op, 0)
        if len(refs) >= 5:
            print(f"--- 方法 {name}{desc}: {len(refs)} 个物品字段引用 ---")
            seen = set()
            ordered = []
            for f in refs:
                if f not in seen:
                    seen.add(f)
                    ordered.append(f)
            for i, f in enumerate(ordered, 1):
                print(f"{i:>3}. artifacts:{f.lower():<26} <- ModItems.{f}")
            return ordered
    print("未找到包含物品字段聚簇的方法")
    return []


if __name__ == "__main__":
    path = sys.argv[1]
    cp, utf, cls_name, methods = parse(path)
    scan_clinit(cp, utf, cls_name, methods, "artifacts/registry/ModItems")

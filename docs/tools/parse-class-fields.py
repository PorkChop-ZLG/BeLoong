# -*- coding: utf-8 -*-
# 解析 Java .class 文件的常量池与字段表，提取 static final String 的声明顺序与取值。
# 用于从 ModItems.class 还原物品注册顺序（= 创造模式物品栏顺序）。
import struct
import sys


def parse(path):
    b = open(path, "rb").read()
    assert b[:4] == b"\xca\xfe\xba\xbe", "not a class file"
    p = 8
    cp_count = struct.unpack_from(">H", b, p)[0]
    p += 2

    cp = {}
    i = 1
    while i < cp_count:
        tag = b[p]
        p += 1
        if tag == 1:  # Utf8
            ln = struct.unpack_from(">H", b, p)[0]
            p += 2
            cp[i] = ("Utf8", b[p:p + ln].decode("utf-8", "replace"))
            p += ln
        elif tag in (7, 8, 16, 19, 20):  # Class, String, MethodType, Module, Package
            cp[i] = (tag, struct.unpack_from(">H", b, p)[0])
            p += 2
        elif tag in (15,):  # MethodHandle
            cp[i] = (tag, b[p], struct.unpack_from(">H", b, p + 1)[0])
            p += 3
        elif tag in (3, 4, 9, 10, 11, 12, 17, 18):  # int/float/refs/NameAndType/Dynamic
            cp[i] = (tag, struct.unpack_from(">I", b, p)[0])
            p += 4
        elif tag in (5, 6):  # Long, Double (占两个槽位)
            cp[i] = (tag, struct.unpack_from(">Q", b, p)[0])
            p += 8
            i += 1
        else:
            raise ValueError(f"unknown cp tag {tag} at {p-1}")
        i += 1

    # access_flags, this_class, super_class
    p += 6
    iface_count = struct.unpack_from(">H", b, p)[0]
    p += 2 + 2 * iface_count

    def skip_attrs(p):
        n = struct.unpack_from(">H", b, p)[0]
        p += 2
        for _ in range(n):
            _ni = struct.unpack_from(">H", b, p)[0]
            ln = struct.unpack_from(">I", b, p + 2)[0]
            p += 6 + ln
        return p

    # fields
    fc = struct.unpack_from(">H", b, p)[0]
    p += 2
    fields = []
    for _ in range(fc):
        acc, name_i, desc_i = struct.unpack_from(">HHH", b, p)
        p += 6
        name = cp[name_i][1]
        desc = cp[desc_i][1]
        const = None
        ac = struct.unpack_from(">H", b, p)[0]
        p += 2
        for _ in range(ac):
            an_i = struct.unpack_from(">H", b, p)[0]
            alen = struct.unpack_from(">I", b, p + 2)[0]
            an = cp[an_i][1]
            if an == "ConstantValue":
                idx = struct.unpack_from(">H", b, p + 6)[0]
                const = cp.get(idx)
            p += 6 + alen
        fields.append((name, desc, const))
    return cp, fields


if __name__ == "__main__":
    cp, fields = parse(sys.argv[1])
    print(f"字段总数: {len(fields)}")
    print()
    print(f"{'#':>3}  {'字段名':<28} {'描述符':<22} 常量")
    print("-" * 78)
    for i, (n, d, c) in enumerate(fields, 1):
        cv = ""
        if c:
            t, v = c
            cv = cp[v][1] if (t == 8 and isinstance(v, int)) else str(v)
        print(f"{i:>3}  {n:<28} {d:<22} {cv}")

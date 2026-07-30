#!/usr/bin/env python3
"""Macraft 图标生成器 — 与侧边栏 brand 一致：accent 绿方块 + 浅绿背景"""
import os
import math
from PIL import Image, ImageDraw

SIZE = 1024
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RESOURCES = os.path.join(ROOT, "Resources")
ICONSET = os.path.join(RESOURCES, "AppIcon.iconset")

# 颜色（与 Theme.swift 一致）
ACCENT = (16, 185, 129, 255)       # #10B981 emerald-500
ACCENT_DARK = (5, 150, 105, 255)   # #059669 emerald-600
ACCENT_SOFT = (236, 253, 245, 255) # #ECFDF5 emerald-50


def draw_icon(size=SIZE):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 圆角矩形背景 — accentSoft 浅绿
    margin = int(size * 0.02)
    radius = int(size * 0.22)
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=radius,
        fill=ACCENT_SOFT
    )

    # 绘制 SF Symbol cube.fill 风格：三个面之间有明确缝隙
    cx, cy = size // 2, size // 2
    s = size * 0.28  # 方块尺度
    gap = size * 0.018  # 面与面之间的间隙（关键！）

    # 等距投影关键坐标
    # 顶部顶点
    top_pt = (cx, cy - s * 1.0)
    # 左右肩点
    left_shoulder = (cx - s, cy - s * 0.42)
    right_shoulder = (cx + s, cy - s * 0.42)
    # 中心点（三面交汇处）
    center_pt = (cx, cy + s * 0.16)
    # 左右底点
    left_bottom = (cx - s, cy + s * 0.58)
    right_bottom = (cx + s, cy + s * 0.58)
    # 底部顶点
    bottom_pt = (cx, cy + s * 1.16)

    # 计算各面内缩（沿法线方向缩小 gap 制造分离感）
    def shrink_polygon(pts, cx_poly, cy_poly, amount):
        """将多边形各顶点向质心收缩 amount"""
        result = []
        for (px, py) in pts:
            dx = px - cx_poly
            dy = py - cy_poly
            dist = math.sqrt(dx*dx + dy*dy)
            if dist < 1:
                result.append((px, py))
            else:
                result.append((px - dx/dist * amount, py - dy/dist * amount))
        return result

    # 顶面 — accent 绿 #10B981
    top_face = [top_pt, right_shoulder, center_pt, left_shoulder]
    top_cx = sum(p[0] for p in top_face) / 4
    top_cy = sum(p[1] for p in top_face) / 4
    top_face_s = shrink_polygon(top_face, top_cx, top_cy, gap)
    draw.polygon(top_face_s, fill=ACCENT)

    # 左面 — accent_dark #059669
    left_face = [left_shoulder, center_pt, bottom_pt, left_bottom]
    left_cx = sum(p[0] for p in left_face) / 4
    left_cy = sum(p[1] for p in left_face) / 4
    left_face_s = shrink_polygon(left_face, left_cx, left_cy, gap)
    draw.polygon(left_face_s, fill=ACCENT_DARK)

    # 右面 — accent 绿 #10B981
    right_face = [right_shoulder, center_pt, bottom_pt, right_bottom]
    right_cx = sum(p[0] for p in right_face) / 4
    right_cy = sum(p[1] for p in right_face) / 4
    right_face_s = shrink_polygon(right_face, right_cx, right_cy, gap)
    draw.polygon(right_face_s, fill=ACCENT)

    return img


def main():
    os.makedirs(ICONSET, exist_ok=True)

    img = draw_icon(SIZE)
    master_path = os.path.join(RESOURCES, "AppIcon_clean.png")
    img.save(master_path)
    print(f"Master icon: {master_path} ({SIZE}x{SIZE})")

    specs = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]
    for name, sz in specs:
        resized = img.resize((sz, sz), Image.LANCZOS)
        resized.save(os.path.join(ICONSET, name))
        print(f"  {name} ({sz}x{sz})")

    # 生成 .icns
    icns_path = os.path.join(RESOURCES, "AppIcon.icns")
    os.system(f'iconutil -c icns "{ICONSET}" -o "{icns_path}"')
    print(f"icns: {icns_path}")


if __name__ == "__main__":
    main()

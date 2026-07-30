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

    # 中心绘制一个 SF Symbol cube.fill 风格的方块
    cx, cy = size // 2, size // 2
    s = size * 0.26  # 方块半边长

    # 顶面 — accent 绿 #10B981
    top_pts = [
        (cx, cy - s * 0.95),
        (cx + s, cy - s * 0.4),
        (cx, cy + s * 0.15),
        (cx - s, cy - s * 0.4),
    ]
    draw.polygon(top_pts, fill=ACCENT)

    # 左面 — accent 绿（稍深一点营造层次）
    left_pts = [
        (cx - s, cy - s * 0.4),
        (cx, cy + s * 0.15),
        (cx, cy + s * 1.1),
        (cx - s, cy + s * 0.55),
    ]
    draw.polygon(left_pts, fill=ACCENT_DARK)

    # 右面 — accent 绿（与顶面相同，保持"两种绿色"）
    right_pts = [
        (cx + s, cy - s * 0.4),
        (cx, cy + s * 0.15),
        (cx, cy + s * 1.1),
        (cx + s, cy + s * 0.55),
    ]
    draw.polygon(right_pts, fill=ACCENT)

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

#!/usr/bin/env python3
"""Macraft 图标生成器 — 简约现代风格，浅色背景 + 绿色方块"""
import os
from PIL import Image, ImageDraw

SIZE = 1024
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RESOURCES = os.path.join(ROOT, "Resources")
ICONSET = os.path.join(RESOURCES, "AppIcon.iconset")

def draw_icon(size=SIZE):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 圆角矩形背景 — 极浅灰白 #F8FAFB
    margin = int(size * 0.02)
    radius = int(size * 0.22)
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=radius,
        fill=(248, 250, 251, 255)
    )

    # 细边框
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=radius,
        outline=(229, 231, 235, 255),
        width=max(2, size // 256)
    )

    # 中心绘制一个等距立方体（Minecraft 方块）
    cx, cy = size // 2, size // 2
    s = size * 0.28  # 方块半边长

    # 顶面 — 浅绿 #ECFDF5
    top_pts = [
        (cx, cy - s * 0.9),
        (cx + s, cy - s * 0.35),
        (cx, cy + s * 0.2),
        (cx - s, cy - s * 0.35),
    ]
    draw.polygon(top_pts, fill=(236, 253, 245, 255), outline=(5, 150, 105, 255), width=max(2, size // 200))

    # 左面 — 中绿 #059669 偏浅
    left_pts = [
        (cx - s, cy - s * 0.35),
        (cx, cy + s * 0.2),
        (cx, cy + s * 1.1),
        (cx - s, cy + s * 0.55),
    ]
    draw.polygon(left_pts, fill=(5, 150, 105, 200), outline=(5, 150, 105, 255), width=max(2, size // 200))

    # 右面 — 深绿 #047857
    right_pts = [
        (cx + s, cy - s * 0.35),
        (cx, cy + s * 0.2),
        (cx, cy + s * 1.1),
        (cx + s, cy + s * 0.55),
    ]
    draw.polygon(right_pts, fill=(4, 120, 87, 220), outline=(5, 150, 105, 255), width=max(2, size // 200))

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

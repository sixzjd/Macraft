#!/usr/bin/env python3
"""去除 ImageGen 右下角水印，并生成 macOS .iconset 多尺寸图标。"""
import os
import sys
from PIL import Image

SRC = sys.argv[1]
ICONSET = sys.argv[2]

img = Image.open(SRC).convert("RGBA")
w, h = img.size

# --- 去水印：用左下角干净区域的水平镜像覆盖右下角水印 ---
# 水印位于右下角；取底部一条带，将左半镜像贴到右半
band_top = int(h * 0.86)
left = img.crop((0, band_top, w // 2, h))
left_flipped = left.transpose(Image.FLIP_LEFT_RIGHT)
img.paste(left_flipped, (w // 2, band_top))

# 保存清理后的 1024 母版
master = os.path.join(os.path.dirname(ICONSET), "AppIcon_clean.png")
img.save(master)
print("cleaned master:", master, img.size)

# --- 生成 iconset ---
os.makedirs(ICONSET, exist_ok=True)
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
for name, size in specs:
    resized = img.resize((size, size), Image.LANCZOS)
    resized.save(os.path.join(ICONSET, name))
    print("  wrote", name, size)

print("iconset ready:", ICONSET)

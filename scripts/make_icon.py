# -*- coding: utf-8 -*-
"""生成 1024×1024 的「校园助手」图标：蓝→青渐变 + 淡网格 + 白色「校」+ 底部小字。"""
import os
from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(HERE, "..", "Sources", "Resources", "Assets.xcassets", "AppIcon.appiconset")
OUT_DIR = os.path.abspath(OUT_DIR)

TOP = (58, 132, 246)
BOTTOM = (14, 176, 168)


def pick_font(size):
    for path in (
        r"C:\Windows\Fonts\msyhbd.ttc",
        r"C:\Windows\Fonts\msyh.ttc",
        r"C:\Windows\Fonts\simhei.ttf",
        "/System/Library/Fonts/PingFang.ttc",
    ):
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return ImageFont.load_default()


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def main():
    img = Image.new("RGB", (SIZE, SIZE), TOP)
    draw = ImageDraw.Draw(img)
    for y in range(SIZE):
        draw.line([(0, y), (SIZE, y)], fill=lerp(TOP, BOTTOM, y / (SIZE - 1)))

    # 极淡网格：暗示「课表 / 校园」
    grid = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    g = ImageDraw.Draw(grid)
    step = SIZE // 8
    for i in range(1, 8):
        g.line([(i * step, 0), (i * step, SIZE)], fill=(255, 255, 255, 20), width=3)
        g.line([(0, i * step), (SIZE, i * step)], fill=(255, 255, 255, 20), width=3)
    img = Image.alpha_composite(img.convert("RGBA"), grid).convert("RGB")
    draw = ImageDraw.Draw(img)

    font = pick_font(520)
    text = "校"
    box = draw.textbbox((0, 0), text, font=font)
    tw, th = box[2] - box[0], box[3] - box[1]
    draw.text(((SIZE - tw) / 2 - box[0], SIZE * 0.42 - th / 2 - box[1]), text,
              font=font, fill=(255, 255, 255))

    small = pick_font(86)
    label = "校园助手"
    sbox = draw.textbbox((0, 0), label, font=small)
    draw.text(((SIZE - (sbox[2] - sbox[0])) / 2 - sbox[0], SIZE * 0.855 - sbox[1]),
              label, font=small, fill=(232, 244, 255))

    os.makedirs(OUT_DIR, exist_ok=True)
    png = os.path.join(OUT_DIR, "icon-1024.png")
    img.save(png, "PNG")
    with open(os.path.join(OUT_DIR, "Contents.json"), "w", encoding="utf-8", newline="\n") as f:
        f.write('{\n  "images" : [\n    {\n      "filename" : "icon-1024.png",\n'
                '      "idiom" : "universal",\n      "platform" : "ios",\n'
                '      "size" : "1024x1024"\n    }\n  ],\n'
                '  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}\n')
    print("wrote", png)


if __name__ == "__main__":
    main()

import sys, math
sys.path.insert(0, sys.argv[1])
from PIL import Image, ImageDraw, ImageFilter

OUT = sys.argv[2]
S = 1600  # supersampled canvas, downsized at the end


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


# Background: radial glow from dark navy to deeper navy
bg = Image.new("RGBA", (S, S))
inner, outer = (44, 58, 104), (12, 16, 34)
px = bg.load()
cx, cy = S * 0.5, S * 0.42
maxd = math.hypot(S, S) * 0.62
for y in range(S):
    for x in range(S):
        t = min(1.0, math.hypot(x - cx, y - cy) / maxd)
        px[x, y] = lerp(inner, outer, t ** 0.9) + (255,)
img = bg
d = ImageDraw.Draw(img)

# Thin gold frame
m = 56
d.rounded_rectangle([m, m, S - m, S - m], radius=150, outline=(201, 160, 72, 255), width=14)

# --- Coin stack (bottom left) ---
GOLD_TOP, GOLD_LIGHT, GOLD_SIDE, GOLD_DARK = (246, 200, 88), (255, 228, 140), (196, 140, 40), (140, 94, 22)


def coin(cx, cy, w, h, thick):
    # side band
    d.rectangle([cx - w / 2, cy, cx + w / 2, cy + thick], fill=GOLD_SIDE)
    d.ellipse([cx - w / 2, cy + thick - h / 2, cx + w / 2, cy + thick + h / 2], fill=GOLD_SIDE)
    # ridges on the side
    for i in range(-6, 7):
        x = cx + i * w / 14
        d.line([x, cy + h * 0.1, x, cy + thick + h * 0.35 * (1 - (i / 7) ** 2)], fill=GOLD_DARK, width=6)
    # top face
    d.ellipse([cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2], fill=GOLD_TOP, outline=GOLD_DARK, width=8)
    d.ellipse([cx - w * 0.36, cy - h * 0.36, cx + w * 0.36, cy + h * 0.36], outline=GOLD_SIDE, width=10)
    d.ellipse([cx - w * 0.30, cy - h * 0.40, cx - w * 0.05, cy - h * 0.12], fill=GOLD_LIGHT)


cw, ch, th = 470, 190, 70
base_x, base_y = 560, 1180
for i in range(5):
    coin(base_x + (i % 2) * 14 - 7, base_y - i * 82, cw, ch, th)

# --- Price tag (upper right), drawn on its own layer and rotated ---
tag = Image.new("RGBA", (S, S), (0, 0, 0, 0))
t = ImageDraw.Draw(tag)
PAPER, PAPER_EDGE = (243, 230, 200, 255), (176, 146, 96, 255)
tx0, ty0, tx1, ty1 = 620, 470, 1240, 900
point = 210
poly = [(tx0 + point, ty0), (tx1, ty0), (tx1, ty1), (tx0 + point, ty1), (tx0, (ty0 + ty1) / 2)]
# shadow
shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ImageDraw.Draw(shadow).polygon([(x + 26, y + 34) for x, y in poly], fill=(0, 0, 0, 140))
shadow = shadow.filter(ImageFilter.GaussianBlur(26))
tag = Image.alpha_composite(shadow, tag)
t = ImageDraw.Draw(tag)
t.polygon(poly, fill=PAPER, outline=PAPER_EDGE, width=14)
# punched hole with gold eyelet
hx, hy, hr = tx0 + 150, (ty0 + ty1) / 2, 44
t.ellipse([hx - hr - 16, hy - hr - 16, hx + hr + 16, hy + hr + 16], fill=(201, 160, 72, 255))
t.ellipse([hx - hr, hy - hr, hx + hr, hy + hr], fill=(20, 26, 48, 255))
# green check mark
GREEN = (66, 196, 92, 255)
pts = [(tx0 + 380, (ty0 + ty1) / 2 + 10), (tx0 + 500, ty1 - 110), (tx1 - 90, ty0 + 100)]
t.line(pts, fill=GREEN, width=86, joint="curve")
for x, y in (pts[0], pts[-1]):
    t.ellipse([x - 43, y - 43, x + 43, y + 43], fill=GREEN)

ANG = -12
tag = tag.rotate(ANG, resample=Image.BICUBIC, center=(940, 690), translate=(70, -10))
img = Image.alpha_composite(img, tag)

# string from the hole, curving off the top
d = ImageDraw.Draw(img)
ang = math.radians(ANG)
hcx, hcy = 940 + 70, 690 - 10
rx, ry = hx - 940, hy - 690
hole = (hcx + rx * math.cos(ang) + ry * math.sin(ang), hcy - rx * math.sin(ang) + ry * math.cos(ang))
curve = []
for i in range(41):
    s = i / 40
    x = hole[0] + (-60 * s) + 90 * math.sin(s * math.pi * 0.9)
    y = hole[1] - 480 * s
    curve.append((x, y))
d.line(curve, fill=(201, 160, 72, 255), width=16, joint="curve")

for size in (400, 800):
    img.resize((size, size), Image.LANCZOS).convert("RGB").save(OUT.replace(".png", f"-{size}.png"), optimize=True)
print("ok")

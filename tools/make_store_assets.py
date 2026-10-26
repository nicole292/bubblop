"""Builds the store screenshots and graphics in docs/store/assets/.

Input: raw 1320x2868 game screenshots in app/build/store_raw/, captured with the
phone-frame screenshot driver (see docs/MOBILE_RELEASE_GUIDE.md, "Remaking the
store images"). Needs Pillow: python -m pip install --user pillow

    python tools/make_store_assets.py
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / 'app' / 'build' / 'store_raw'
OUT = ROOT / 'docs' / 'store' / 'assets'
FONT = ROOT / 'app' / 'assets' / 'fonts' / 'Nunito-Variable.ttf'
ICON = ROOT / 'app' / 'ios' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset' / 'Icon-App-1024x1024@1x.png'

# The game's sky (lib/game/palette.dart) and accent colour.
SKY = [(0x5C, 0xC8, 0xFF), (0x7F, 0xA8, 0xFF), (0xA9, 0x8B, 0xFF)]
ACCENT = (0x7B, 0x5C, 0xFF)

# (raw screenshot, caption): only things the game really does.
SHOTS = [
    ('chain_04', 'Huge chain reactions!'),
    ('aim', 'Drag to aim, then drop'),
    ('chain_03', 'Free the balls in bubbles'),
    ('round_mid', 'Plan ahead: new rows rise'),
    ('home', 'Quick rounds, plays offline'),
]


def font(size):
    f = ImageFont.truetype(str(FONT), size)
    f.set_variation_by_axes([900])
    return f


def gradient(w, h):
    img = Image.new('RGB', (1, h))
    for y in range(h):
        t = y / (h - 1)
        a, b, k = (SKY[0], SKY[1], t * 2) if t < 0.5 else (SKY[1], SKY[2], (t - 0.5) * 2)
        img.putpixel((0, y), tuple(round(a[i] + (b[i] - a[i]) * k) for i in range(3)))
    return img.resize((w, h))


def rounded_mask(size, r):
    m = Image.new('L', size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, *size), r, fill=255)
    return m


def compose(shot, caption, w, h, name):
    bg = gradient(w, h).convert('RGBA')
    cap_h = int(h * 0.17)
    f = font(int(w * 0.06))
    d = ImageDraw.Draw(bg)
    lines = ['']
    for word in caption.split():
        t = (lines[-1] + ' ' + word).strip()
        if d.textlength(t, font=f) > w * 0.86:
            lines.append(word)
        else:
            lines[-1] = t
    lh = int(f.size * 1.18)
    y0 = (cap_h - lh * len(lines)) // 2 + int(h * 0.012)
    for i, line in enumerate(lines):
        d.text(((w - d.textlength(line, font=f)) / 2, y0 + i * lh), line, font=f, fill='white',
               stroke_width=max(2, w // 160), stroke_fill=ACCENT)

    im = Image.open(RAW / f'{shot}.png').convert('RGB')
    sh_h = h - cap_h - int(h * 0.035)
    sw = int(im.width * sh_h / im.height)
    if sw > w * 0.86:
        sw = int(w * 0.86)
        sh_h = int(im.height * sw / im.width)
    im = im.resize((sw, sh_h), Image.LANCZOS)
    r, x, y = int(sw * 0.07), (w - sw) // 2, cap_h
    shadow = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    lift = int(w * 0.012)
    ImageDraw.Draw(shadow).rounded_rectangle((x, y + lift, x + sw, y + sh_h + lift), r, fill=(58, 45, 158, 90))
    bg = Image.alpha_composite(bg, shadow.filter(ImageFilter.GaussianBlur(w // 60)))
    bg.paste(im, (x, y), rounded_mask(im.size, r))
    ImageDraw.Draw(bg).rounded_rectangle((x, y, x + sw, y + sh_h), r, outline=(255, 255, 255, 255),
                                         width=max(3, w // 200))
    bg.convert('RGB').save(OUT / f'{name}.png', optimize=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for i, (shot, caption) in enumerate(SHOTS, 1):
        compose(shot, caption, 1320, 2868, f'ios-6.9in-{i}')       # App Store, 6.9" iPhone
        compose(shot, caption, 1080, 1920, f'android-phone-{i}')   # Google Play phone

    # Google Play feature graphic: the home screen's logo, cropped to 1024x500.
    home = Image.open(RAW / 'home.png').convert('RGB')
    c, ch = int(home.height * 0.365), int(home.width * 500 / 1024)
    home.crop((0, c - ch // 2, home.width, c - ch // 2 + ch)).resize((1024, 500), Image.LANCZOS).save(
        OUT / 'play-feature-graphic-1024x500.png', optimize=True)

    # Google Play icon: the app icon at 512x512 (no transparency).
    Image.open(ICON).convert('RGB').resize((512, 512), Image.LANCZOS).save(OUT / 'play-icon-512.png', optimize=True)


if __name__ == '__main__':
    main()

# Turns the raw Blender renders (app/build/pieces_raw, from make_pieces.py)
# into the game's piece layers in app/assets/pieces/, and writes a preview
# sheet of every piece in a few ball colours to app/build/pieces_preview.png.
#
#   python tools/blender/split_layers.py
#
# body:   grey shading with the piece's alpha, brightened so the lit side is
#         white; the game multiplies it by the ball colour.
# gloss:  white with the highlights as alpha, drawn over the tinted body.
# detail: unchanged (parts that keep their own colours).

import glob
import os

from PIL import Image, ImageChops

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "app")
RAW = os.path.join(ROOT, "build", "pieces_raw")
OUT = os.path.join(ROOT, "assets", "pieces")
SIZE = 192


def body_layer(img):
    r, g, b, a = img.split()
    lum = Image.merge("RGB", (r, g, b)).convert("L")
    # Brighten so the lit side reaches white and the shade stays gentle.
    hist = sorted(p for p, al in zip(lum.get_flattened_data(), a.get_flattened_data()) if al > 200)
    top = hist[int(len(hist) * 0.92)] if hist else 255
    lum = lum.point(lambda v: min(255, int(v * 255 / max(top, 1) * 0.9 + 255 * 0.1)))
    return Image.merge("RGBA", (lum, lum, lum, a))


def gloss_layer(img):
    r, g, b, a = img.split()
    lum = Image.merge("RGB", (r, g, b)).convert("L")
    alpha = ImageChops.multiply(lum.point(lambda v: min(255, int(v * 1.6))), a)
    white = Image.new("L", img.size, 255)
    return Image.merge("RGBA", (white, white, white, alpha))


def tint(body, color):
    r, g, b, a = body.split()
    cr, cg, cb = color
    return Image.merge("RGBA", (r.point(lambda v: v * cr // 255), g.point(lambda v: v * cg // 255),
                                b.point(lambda v: v * cb // 255), a))


def main():
    os.makedirs(OUT, exist_ok=True)
    names = sorted({os.path.basename(p).split("_")[0] for p in glob.glob(os.path.join(RAW, "*_body.png"))})
    layers = {}
    for name in names:
        body = body_layer(Image.open(os.path.join(RAW, f"{name}_body.png")).convert("RGBA"))
        gloss = gloss_layer(Image.open(os.path.join(RAW, f"{name}_gloss.png")).convert("RGBA"))
        detail_path = os.path.join(RAW, f"{name}_detail.png")
        detail = Image.open(detail_path).convert("RGBA") if os.path.exists(detail_path) else None
        out = {"body": body, "gloss": gloss, "detail": detail}
        for kind, img in out.items():
            if img is None:
                continue
            img.resize((SIZE, SIZE), Image.LANCZOS).save(os.path.join(OUT, f"{name}_{kind}.png"), optimize=True)
        layers[name] = out
    bomb = os.path.join(RAW, "bomb.png")
    if os.path.exists(bomb):
        Image.open(bomb).convert("RGBA").resize((SIZE, SIZE), Image.LANCZOS).save(os.path.join(OUT, "bomb.png"),
                                                                                optimize=True)

    colors = [(255, 71, 87), (255, 195, 18), (46, 213, 115), (30, 144, 255), (155, 89, 246)]
    cell = 128
    sheet = Image.new("RGBA", (cell * (len(colors) + 1), cell * max(1, len(layers))), (241, 244, 255, 255))
    for row, (name, out) in enumerate(layers.items()):
        for col, color in enumerate(colors):
            piece = tint(out["body"], color)
            piece = Image.alpha_composite(piece, out["gloss"])
            if out["detail"] is not None:
                piece = Image.alpha_composite(piece, out["detail"])
            sheet.alpha_composite(piece.resize((cell, cell), Image.LANCZOS), (col * cell, row * cell))
        if os.path.exists(bomb) and row == 0:
            sheet.alpha_composite(Image.open(bomb).convert("RGBA").resize((cell, cell), Image.LANCZOS),
                                  (len(colors) * cell, 0))
    sheet.save(os.path.join(ROOT, "build", "pieces_preview.png"))
    print(f"{len(layers)} pieces -> {OUT}")


if __name__ == "__main__":
    main()

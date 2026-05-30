"""
Generate ShikkhaAI logo assets — glassy, professional, old-school style with wood texture.

Run: python generate_logo.py
Outputs:
  - logo_1024.png (master, transparent background)
  - logo_512.png  (launcher icon source, opaque background)
  - logo_256.png  (in-app logo asset)
"""

from PIL import Image, ImageDraw, ImageFilter, ImageFont
import os
import math

# ── Vintage palette ──
WOOD_DEEP = (0x5C, 0x2A, 0x12)       # very dark brown
WOOD_BASE = (0xA0, 0x52, 0x2D)       # #A0522D
GOLD = (0xD4, 0xA5, 0x3A)            # vintage gold
GOLD_LIGHT = (0xF0, 0xD8, 0x78)      # bright gold
CREAM = (0xFF, 0xF8, 0xF0)           # near-white cream
WHITE = (0xFF, 0xFF, 0xFF)


def get_font(size):
    candidates = [
        "C:/Windows/Fonts/impact.ttf",
        "C:/Windows/Fonts/arialbd.ttf",
        "C:/Windows/Fonts/segoeuib.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return ImageFont.load_default()


def load_wood_texture(target_size, base_color):
    """Load the project's wood texture, tint it, and resize to target."""
    tex_path = os.path.join(os.path.dirname(__file__), "..", "..", "textures", "wood_texture.png")
    if not os.path.exists(tex_path):
        # Fallback: create a simple procedural wood grain
        tex = Image.new("RGB", target_size, base_color)
        tdraw = ImageDraw.Draw(tex)
        w, h = target_size
        for i in range(80):
            x = int((i / 80) * w + (i % 3) * 3)
            shade = (0x4A, 0x22, 0x0A) if i % 7 == 0 else (0x6B, 0x35, 0x18)
            tdraw.line([(x, 0), (x + (i % 5) - 2, h)], fill=shade, width=1 + (i % 3))
        return tex

    tex = Image.open(tex_path).convert("RGB")
    # Resize using high-quality filter
    tex = tex.resize(target_size, Image.LANCZOS)
    # Tint toward the base warm brown
    tinted = Image.new("RGB", target_size, base_color)
    # Blend texture with base color (40% texture, 60% base)
    tex = Image.blend(tex, tinted, alpha=0.45)
    return tex


def draw_text_with_stroke(draw, pos, text, font, fill, stroke_fill, stroke_width):
    """Draw text with an outline stroke by drawing offset copies first."""
    x, y = pos
    # Draw stroke in all 8 directions + diagonals for smoothness
    for dx in range(-stroke_width, stroke_width + 1):
        for dy in range(-stroke_width, stroke_width + 1):
            if dx == 0 and dy == 0:
                continue
            draw.text((x + dx, y + dy), text, font=font, fill=stroke_fill)
    # Draw main text on top
    draw.text((x, y), text, font=font, fill=fill)


def draw_logo(size, opaque_bg=False, bg_color=WOOD_BASE):
    """Draw the ShikkhaAI logo."""
    img = Image.new("RGBA", (size, size), bg_color if opaque_bg else (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = size // 2, size // 2
    radius = int(size * 0.44)
    inner_r = radius - max(4, radius // 30) - 2

    s = size / 1024.0

    # ── 1. Wood-textured circle background ──
    # Create the wood texture, mask to circle, composite
    wood = load_wood_texture((size, size), WOOD_BASE)
    wood = wood.convert("RGBA")

    # Apply a radial darkening vignette for depth
    vignette = Image.new("L", (size, size), 255)
    vdraw = ImageDraw.Draw(vignette)
    for i in range(inner_r, -1, -1):
        t = i / inner_r if inner_r > 0 else 0
        # Darker at edges
        alpha = int(255 * (0.55 + 0.45 * t))
        vdraw.ellipse([cx - i, cy - i, cx + i, cy + i], fill=alpha)

    # Darken the wood texture using the vignette (keep texture visible)
    r, g, b, a = wood.split()
    # Create a moderately darkened version — center stays warm, edges go darker
    dark = Image.new("RGBA", (size, size), (0x5C, 0x2A, 0x12, 0))
    wood = Image.composite(dark, wood, vignette)

    # Mask to circle
    circle_mask = Image.new("L", (size, size), 0)
    cdraw = ImageDraw.Draw(circle_mask)
    cdraw.ellipse([cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r], fill=255)
    wood.putalpha(circle_mask)
    img.alpha_composite(wood)

    # ── 2. Drop shadow behind the gold ring ──
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    off = max(3, radius // 30)
    sd.ellipse(
        [cx - radius + off, cy - radius + off, cx + radius + off, cy + radius + off],
        fill=(0x1A, 0x0A, 0x04, 120)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=max(5, radius // 20)))
    img.alpha_composite(shadow)

    # ── 3. Gold ring border ──
    ring_thick = max(4, radius // 30)
    draw.ellipse(
        [cx - radius, cy - radius, cx + radius, cy + radius],
        outline=GOLD, width=ring_thick
    )
    # Inner bright gold accent ring
    draw.ellipse(
        [cx - radius + ring_thick + 1, cy - radius + ring_thick + 1,
         cx + radius - ring_thick - 1, cy + radius - ring_thick - 1],
        outline=GOLD_LIGHT, width=max(1, ring_thick // 3)
    )

    # ── 4. Bevel emboss on the inner edge ──
    bevel_r = inner_r - max(2, radius // 60)
    bevel_w = max(2, radius // 45)
    draw.arc(
        [cx - bevel_r, cy - bevel_r, cx + bevel_r, cy + bevel_r],
        start=30, end=210, fill=(0x3A, 0x18, 0x08, 130), width=bevel_w
    )
    draw.arc(
        [cx - bevel_r, cy - bevel_r, cx + bevel_r, cy + bevel_r],
        start=210, end=390, fill=(0xFF, 0xF8, 0xF0, 90), width=bevel_w
    )

    # ── 5. Glassy highlight (soft oval at top) ──
    gloss = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(gloss)
    gw = int(inner_r * 0.55)
    gh = int(inner_r * 0.18)
    gy = cy - int(inner_r * 0.42)
    gd.ellipse([cx - gw, gy - gh, cx + gw, gy + gh], fill=(*WHITE, 40))
    gloss = gloss.filter(ImageFilter.GaussianBlur(radius=max(4, radius // 40)))
    img.alpha_composite(gloss)

    # ── 6. Bold "S" with thick dark outline for maximum visibility ──
    font_size = int(520 * s)
    font = get_font(font_size)
    text = "S"

    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    text_x = cx - text_w // 2
    text_y = cy - text_h // 2 - int(10 * s)

    stroke_w = max(3, int(7 * s))
    draw_text_with_stroke(
        draw, (text_x, text_y), text, font,
        fill=CREAM, stroke_fill=(0x3A, 0x18, 0x08, 200), stroke_width=stroke_w
    )

    # ── 7. Vintage book seal at bottom ──
    book_y = cy + inner_r - int(38 * s)
    book_w = int(40 * s)
    book_h = int(22 * s)
    sh = max(1, int(2 * s))

    # Shadow
    for pts in [
        [(cx + sh, book_y - book_h // 2 + sh),
         (cx - book_w // 2 + sh, book_y + sh),
         (cx + sh, book_y + book_h // 2 + sh)],
        [(cx + sh, book_y - book_h // 2 + sh),
         (cx + book_w // 2 + sh, book_y + sh),
         (cx + sh, book_y + book_h // 2 + sh)],
    ]:
        draw.polygon(pts, fill=(0x3A, 0x18, 0x08, 140))

    # Pages
    draw.polygon([
        (cx, book_y - book_h // 2), (cx - book_w // 2, book_y), (cx, book_y + book_h // 2),
    ], fill=CREAM)
    draw.polygon([
        (cx, book_y - book_h // 2), (cx + book_w // 2, book_y), (cx, book_y + book_h // 2),
    ], fill=CREAM)
    # Spine + page lines
    draw.line([(cx, book_y - book_h // 2), (cx, book_y + book_h // 2)],
              fill=(0x3A, 0x18, 0x08), width=max(1, int(2 * s)))
    draw.line([(cx - book_w // 4, book_y - book_h // 4), (cx - 2, book_y - 2)],
              fill=(0x3A, 0x18, 0x08), width=1)
    draw.line([(cx + book_w // 4, book_y - book_h // 4), (cx + 2, book_y - 2)],
              fill=(0x3A, 0x18, 0x08), width=1)

    return img


def main():
    out_dir = os.path.dirname(os.path.abspath(__file__))

    logo_1024 = draw_logo(1024, opaque_bg=False)
    logo_1024.save(os.path.join(out_dir, "logo_1024.png"))
    print("Created logo_1024.png")

    logo_512 = draw_logo(512, opaque_bg=True)
    logo_512.save(os.path.join(out_dir, "logo_512.png"))
    print("Created logo_512.png")

    logo_256 = draw_logo(256, opaque_bg=True)
    logo_256.save(os.path.join(out_dir, "logo_256.png"))
    print("Created logo_256.png")

    print("All logo assets generated successfully.")


if __name__ == "__main__":
    main()

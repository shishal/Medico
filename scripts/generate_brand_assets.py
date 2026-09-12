#!/usr/bin/env python3
"""
Generate launcher, splash, Play Store, and transparent Docci art.

Outputs (committed source art — regenerate, then re-run the Flutter icon/splash
generators):
  assets/branding/app_icon.png
  assets/branding/app_icon_foreground.png
  assets/branding/app_icon_monochrome.png
  assets/branding/splash_logo.png
  store/play/icon-512.png
  store/play/feature-graphic-1024x500.png
  assets/illustrations/mascot_*.png

If assets/branding/app_icon_source.png exists, the white ECG-M is extracted
from it. Otherwise a programmatic mark is drawn.

Requires Pillow (scripts/.venv).
"""

from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / "assets" / "branding"
ILLUSTRATIONS = ROOT / "assets" / "illustrations"
PLAY = ROOT / "store" / "play"

# AppTheme.splashCanvas — keep in lockstep with lib/core/theme/app_theme.dart
CHARCOAL = (0x12, 0x12, 0x12, 255)
# Source mark (app_icon_source.png) was painted on the old teal field.
SOURCE_FIELD = (0x0D, 0x73, 0x77)
WHITE = (255, 255, 255, 255)
BLACK = (0, 0, 0, 255)
TRANSPARENT = (0, 0, 0, 0)

FONT_CANDIDATES = [
    "/System/Library/Fonts/Supplemental/Arial Black.ttf",
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf",
]


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in FONT_CANDIDATES:
        if Path(path).exists():
            return ImageFont.truetype(path, size=size)
    return ImageFont.load_default()


def _glyph(
    text: str,
    *,
    fill: tuple[int, int, int, int],
    font_size: int,
) -> Image.Image:
    """Render [text] and crop to actual ink (font metrics lie)."""
    font = _font(font_size)
    canvas_w = max(font_size * 4, font_size * (len(text) + 2))
    canvas_h = font_size * 4
    img = Image.new("RGBA", (canvas_w, canvas_h), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    draw.text(
        (canvas_w // 2, canvas_h // 2),
        text,
        font=font,
        fill=fill,
        anchor="mm",
    )
    ink = img.getbbox()
    if ink is None:
        raise RuntimeError(f"font produced no ink for {text!r}")
    return img.crop(ink)


def _dist(a: tuple[int, ...], b: tuple[int, ...]) -> float:
    return (
        (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2
    ) ** 0.5


def _rounded_poly(
    draw: ImageDraw.ImageDraw,
    points: list[tuple[float, float]],
    width: int,
    fill: tuple[int, int, int, int],
) -> None:
    xy = [(round(x), round(y)) for x, y in points]
    draw.line(xy, fill=fill, width=width, joint="curve")
    r = max(1, width // 2)
    for x, y in xy:
        draw.ellipse((x - r, y - r, x + r, y + r), fill=fill)


def _draw_ecg_m(
    size: int,
    *,
    fill: tuple[int, int, int, int],
    background: tuple[int, int, int, int],
) -> Image.Image:
    """Custom M: rounded stems + ECG spike in the valley (not a system font)."""
    img = Image.new("RGBA", (size, size), background)
    draw = ImageDraw.Draw(img)
    stem = max(8, round(size * 0.13))
    # Inner content box — ~18% margin so adaptive icons don't crop the spike.
    left = size * 0.20
    right = size * 0.80
    top = size * 0.20
    bottom = size * 0.80
    stem_x_l = left + stem * 0.15
    stem_x_r = right - stem * 0.15
    _rounded_poly(draw, [(stem_x_l, top), (stem_x_l, bottom)], stem, fill)
    _rounded_poly(draw, [(stem_x_r, top), (stem_x_r, bottom)], stem, fill)

    # ECG runs between the inner edges of the stems, slightly above center.
    y0 = size * 0.58
    x0 = stem_x_l + stem * 0.35
    x1 = stem_x_r - stem * 0.35
    span = x1 - x0
    pulse = [
        (x0, y0),
        (x0 + span * 0.18, y0),
        (x0 + span * 0.28, y0 - size * 0.015),
        (x0 + span * 0.34, y0 + size * 0.02),
        (x0 + span * 0.46, y0 - size * 0.22),  # R peak
        (x0 + span * 0.56, y0 + size * 0.10),  # S dip
        (x0 + span * 0.66, y0 - size * 0.02),
        (x0 + span * 0.78, y0),
        (x1, y0),
    ]
    _rounded_poly(draw, pulse, max(6, round(size * 0.055)), fill)
    return img


def extract_white_mark(source: Image.Image) -> Image.Image:
    """Keep the light glyph; punch the teal field to alpha."""
    src = source.convert("RGBA")
    w, h = src.size
    pix = src.load()
    out = Image.new("RGBA", (w, h), TRANSPARENT)
    dest = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b, _a = pix[x, y]
            teal_d = _dist((r, g, b), SOURCE_FIELD)
            if teal_d < 28:
                continue
            # Residual anti-alias: closer to teal → more transparent.
            alpha = min(255, max(0, int((teal_d - 16) * 5)))
            dest[x, y] = (255, 255, 255, alpha)
    # Tighten halo, then a 1px blur so the mark isn't stair-stepped.
    alpha = out.getchannel("A").filter(ImageFilter.MaxFilter(3))
    alpha = alpha.filter(ImageFilter.GaussianBlur(radius=0.6))
    white = Image.new("RGBA", (w, h), WHITE)
    white.putalpha(alpha)
    return white


def _fit_mark(
    mark: Image.Image,
    size: int,
    *,
    occupy: float,
    fill: tuple[int, int, int, int],
    background: tuple[int, int, int, int],
) -> Image.Image:
    cropped = mark.split()[-1].getbbox()
    if cropped is None:
        raise RuntimeError("mark has no ink")
    glyph = mark.crop(cropped)
    gw, gh = glyph.size
    target = int(size * occupy)
    ratio = target / max(gw, gh)
    glyph = glyph.resize(
        (max(1, round(gw * ratio)), max(1, round(gh * ratio))),
        Image.Resampling.LANCZOS,
    )
    if fill[:3] != (255, 255, 255):
        tinted = Image.new("RGBA", glyph.size, fill)
        tinted.putalpha(glyph.split()[-1])
        glyph = tinted
    out = Image.new("RGBA", (size, size), background)
    x = (size - glyph.size[0]) // 2
    y = (size - glyph.size[1]) // 2
    out.alpha_composite(glyph, (x, y))
    return out


def _save(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG")
    print(f"wrote {path.relative_to(ROOT)}")


def _feature_graphic(mark: Image.Image) -> Image.Image:
    width, height = 1024, 500
    img = Image.new("RGBA", (width, height), CHARCOAL)
    badge = _fit_mark(
        mark, 280, occupy=0.88, fill=WHITE, background=TRANSPARENT
    )
    img.alpha_composite(badge, (48, (height - 280) // 2))

    title = _glyph("Medico", fill=WHITE, font_size=92)
    sub = _glyph("KUHS MBBS exam companion", fill=WHITE, font_size=28)
    text_left = 360
    block_h = title.size[1] + 22 + sub.size[1]
    title_y = (height - block_h) // 2
    img.alpha_composite(title, (text_left, title_y))
    img.alpha_composite(sub, (text_left, title_y + title.size[1] + 22))
    return img


def _is_warm_paper(rgb: tuple[int, ...]) -> bool:
    r, g, b = rgb[:3]
    mx, mn = max(r, g, b), min(r, g, b)
    return mx >= 218 and (mx - mn) <= 42 and b <= r + 8


def knockout_paper_background(src: Image.Image, max_dist: float = 18) -> Image.Image:
    """Flood-fill cream paper from the border. Keeps white coats inside ink."""
    img = src.convert("RGBA")
    w, h = img.size
    pix = img.load()
    seen = [[False] * w for _ in range(h)]
    queue: deque[tuple[int, int, tuple[int, int, int]]] = deque()

    def seed(x: int, y: int) -> None:
        p = pix[x, y]
        if seen[y][x] or not _is_warm_paper(p):
            return
        seen[y][x] = True
        queue.append((x, y, (p[0], p[1], p[2])))

    for x in range(w):
        seed(x, 0)
        seed(x, h - 1)
    for y in range(h):
        seed(0, y)
        seed(w - 1, y)

    background: list[tuple[int, int]] = []
    while queue:
        x, y, sample = queue.popleft()
        background.append((x, y))
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if nx < 0 or ny < 0 or nx >= w or ny >= h or seen[ny][nx]:
                continue
            p = pix[nx, ny]
            # Thick comic ink is a hard wall — never punch through it.
            if p[0] < 72 and p[1] < 72 and p[2] < 72:
                seen[ny][nx] = True
                continue
            if _dist(p, sample) <= max_dist and _is_warm_paper(p):
                seen[ny][nx] = True
                queue.append((nx, ny, sample))

    for x, y in background:
        pix[x, y] = TRANSPARENT

    # Expand the character 1px so cream doesn't fringe, then soften.
    alpha = img.getchannel("A").filter(ImageFilter.MaxFilter(3))
    alpha = alpha.filter(ImageFilter.GaussianBlur(radius=0.7))
    img.putalpha(alpha)
    box = img.getbbox()
    if box is None:
        return img
    pad = max(4, round(min(img.size) * 0.04))
    left = max(0, box[0] - pad)
    top = max(0, box[1] - pad)
    right = min(img.size[0], box[2] + pad)
    bottom = min(img.size[1], box[3] + pad)
    return img.crop((left, top, right, bottom))


def process_mascots() -> None:
    mapping = {
        "mascot_wave.jpg": "mascot_wave.png",
        "mascot_study.jpg": "mascot_study.png",
        "mascot_avatar.jpg": "mascot_avatar.png",
    }
    for src_name, dest_name in mapping.items():
        src = ILLUSTRATIONS / src_name
        if not src.exists():
            print(f"skip {src_name} (missing)")
            continue
        knocked = knockout_paper_background(Image.open(src))
        _save(knocked, ILLUSTRATIONS / dest_name)


def load_mark() -> Image.Image:
    source_path = BRANDING / "app_icon_source.png"
    if source_path.exists():
        print(f"extracting mark from {source_path.relative_to(ROOT)}")
        return extract_white_mark(Image.open(source_path))
    print("no app_icon_source.png — drawing programmatic ECG-M")
    return _draw_ecg_m(1024, fill=WHITE, background=TRANSPARENT)


def main() -> None:
    BRANDING.mkdir(parents=True, exist_ok=True)
    PLAY.mkdir(parents=True, exist_ok=True)

    mark = load_mark()

    icon = _fit_mark(mark, 1024, occupy=0.64, fill=WHITE, background=CHARCOAL)
    _save(icon.convert("RGB"), BRANDING / "app_icon.png")

    foreground = _fit_mark(
        mark, 1024, occupy=0.58, fill=WHITE, background=TRANSPARENT
    )
    _save(foreground, BRANDING / "app_icon_foreground.png")
    _save(foreground, BRANDING / "splash_logo.png")

    monochrome = _fit_mark(
        mark, 1024, occupy=0.58, fill=BLACK, background=TRANSPARENT
    )
    _save(monochrome, BRANDING / "app_icon_monochrome.png")

    _save(
        icon.resize((512, 512), Image.Resampling.LANCZOS).convert("RGB"),
        PLAY / "icon-512.png",
    )
    _save(_feature_graphic(mark).convert("RGB"), PLAY / "feature-graphic-1024x500.png")

    process_mascots()


if __name__ == "__main__":
    main()

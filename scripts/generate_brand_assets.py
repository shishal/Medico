#!/usr/bin/env python3
"""
Phase 9.2 — generate launcher, splash, and Play Store graphics from brand colors.

Outputs (committed source art — regenerate, then re-run the Flutter icon/splash
generators):
  assets/branding/app_icon.png
  assets/branding/app_icon_foreground.png
  assets/branding/app_icon_monochrome.png
  assets/branding/splash_logo.png
  store/play/icon-512.png
  store/play/feature-graphic-1024x500.png

Requires Pillow (scripts/.venv).
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / "assets" / "branding"
PLAY = ROOT / "store" / "play"

# AppTheme.seedColor — keep in lockstep with lib/core/theme/app_theme.dart
TEAL = (0x0D, 0x73, 0x77, 255)
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
    # Wide enough for a wordmark, tall enough for a single glyph.
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


def _letter_image(
    size: int,
    *,
    fill: tuple[int, int, int, int],
    background: tuple[int, int, int, int],
    occupy: float,
) -> Image.Image:
    """Centered 'M' whose larger side fills [occupy] of [size]."""
    glyph = _glyph("M", fill=fill, font_size=size * 4)
    gw, gh = glyph.size
    target = int(size * occupy)
    ratio = target / max(gw, gh)
    glyph = glyph.resize(
        (max(1, round(gw * ratio)), max(1, round(gh * ratio))),
        Image.Resampling.LANCZOS,
    )
    out = Image.new("RGBA", (size, size), background)
    x = (size - glyph.size[0]) // 2
    y = (size - glyph.size[1]) // 2
    out.alpha_composite(glyph, (x, y))
    return out


def _save(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG")
    print(f"wrote {path.relative_to(ROOT)}")


def _paste_centered(base: Image.Image, overlay: Image.Image, xy: tuple[int, int]) -> None:
    x, y = xy
    base.alpha_composite(overlay, (x, y))


def _feature_graphic() -> Image.Image:
    width, height = 1024, 500
    img = Image.new("RGBA", (width, height), TEAL)
    mark = _letter_image(260, fill=WHITE, background=TRANSPARENT, occupy=0.92)
    _paste_centered(img, mark, (56, (height - 260) // 2))

    title = _glyph("Medico", fill=WHITE, font_size=92)
    sub = _glyph("NEET-PG test prep", fill=WHITE, font_size=34)
    text_left = 360
    block_h = title.size[1] + 24 + sub.size[1]
    title_y = (height - block_h) // 2
    img.alpha_composite(title, (text_left, title_y))
    img.alpha_composite(sub, (text_left, title_y + title.size[1] + 24))
    return img


def main() -> None:
    BRANDING.mkdir(parents=True, exist_ok=True)
    PLAY.mkdir(parents=True, exist_ok=True)

    # Full-bleed iOS / legacy Android icon: no alpha, no pre-rounded corners.
    icon = _letter_image(1024, fill=WHITE, background=TEAL, occupy=0.62)
    _save(icon.convert("RGB"), BRANDING / "app_icon.png")

    # Adaptive / splash mark: white M on transparent so the teal background shows.
    foreground = _letter_image(1024, fill=WHITE, background=TRANSPARENT, occupy=0.58)
    _save(foreground, BRANDING / "app_icon_foreground.png")
    _save(foreground, BRANDING / "splash_logo.png")

    monochrome = _letter_image(1024, fill=BLACK, background=TRANSPARENT, occupy=0.58)
    _save(monochrome, BRANDING / "app_icon_monochrome.png")

    _save(icon.resize((512, 512), Image.Resampling.LANCZOS).convert("RGB"), PLAY / "icon-512.png")
    _save(_feature_graphic().convert("RGB"), PLAY / "feature-graphic-1024x500.png")


if __name__ == "__main__":
    main()

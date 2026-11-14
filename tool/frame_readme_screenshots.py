"""Composite raw mobile screenshots into a framed README preview image."""

from __future__ import annotations

import argparse
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


DEFAULT_INPUTS = (
    "01_library.png",
    "02_browse.png",
    "03_series_detail.png",
    "04_news.png",
)


def _load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = (
        Path("assets/fonts/Outfit-SemiBold.ttf"),
        Path("assets/fonts/Outfit-Medium.ttf"),
        Path("assets/fonts/Outfit-Regular.ttf"),
    )
    for path in candidates:
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


def _draw_status_bar(
    screen: Image.Image,
    top_pad: int,
    fg_color: tuple[int, int, int, int] = (240, 240, 244, 240),
) -> None:
    """Draw a minimal Android status bar and centered punch-hole camera."""
    w, _ = screen.size
    overlay = Image.new("RGBA", screen.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Centered punch-hole camera
    cam_r = max(12, int(w * 0.015))
    cam_cx = w // 2
    cam_cy = max(cam_r + 12, int(top_pad * 0.52))
    draw.ellipse(
        (cam_cx - cam_r - 4, cam_cy - cam_r - 4, cam_cx + cam_r + 4, cam_cy + cam_r + 4),
        fill=(12, 12, 14, 255),
    )
    draw.ellipse(
        (cam_cx - cam_r, cam_cy - cam_r, cam_cx + cam_r, cam_cy + cam_r),
        fill=(24, 26, 32, 255),
        outline=(45, 48, 56, 255),
        width=2,
    )

    # Time on the left
    font = _load_font(max(24, int(top_pad * 0.42)))
    text_y = cam_cy - int(font.size * 0.55) if hasattr(font, "size") else int(top_pad * 0.28)
    draw.text((int(w * 0.08), text_y), "09:41", font=font, fill=fg_color)

    # Signal, Wi-Fi bars & battery icon on the right
    right_x = int(w * 0.92)
    cy = cam_cy

    # Battery outline + fill
    bat_w = int(w * 0.046)
    bat_h = int(bat_w * 0.54)
    bat_x1 = right_x
    bat_x0 = bat_x1 - bat_w
    bat_y0 = cy - bat_h // 2
    bat_y1 = bat_y0 + bat_h
    draw.rounded_rectangle(
        (bat_x0, bat_y0, bat_x1, bat_y1),
        radius=4,
        outline=fg_color,
        width=2,
    )
    # Battery tip
    draw.rectangle(
        (bat_x1 + 1, cy - bat_h // 4, bat_x1 + 4, cy + bat_h // 4),
        fill=fg_color,
    )
    # Battery charge fill (85%)
    inner_pad = 4
    fill_w = int((bat_w - inner_pad * 2) * 0.85)
    draw.rounded_rectangle(
        (bat_x0 + inner_pad, bat_y0 + inner_pad, bat_x0 + inner_pad + fill_w, bat_y1 - inner_pad),
        radius=2,
        fill=fg_color,
    )

    # Signal bars to the left of battery
    sig_gap = 4
    bar_w = 5
    sig_right = bat_x0 - 16
    for idx in range(4):
        bh = int(bat_h * (0.35 + 0.2 * idx))
        bx1 = sig_right - (3 - idx) * (bar_w + sig_gap)
        bx0 = bx1 - bar_w
        draw.rounded_rectangle(
            (bx0, bat_y1 - bh, bx1, bat_y1),
            radius=2,
            fill=fg_color,
        )

    screen.alpha_composite(overlay)


def _draw_nav_bar(
    screen: Image.Image,
    bottom_pad: int,
    fg_color: tuple[int, int, int, int] = (225, 225, 230, 220),
) -> None:
    """Draw a clean Android gesture pill in the bottom safe area."""
    w, h = screen.size
    overlay = Image.new("RGBA", screen.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    pill_w = int(w * 0.34)
    pill_h = max(6, int(bottom_pad * 0.16))
    x0 = (w - pill_w) // 2
    y0 = h - int(bottom_pad * 0.45) - pill_h // 2
    draw.rounded_rectangle(
        (x0, y0, x0 + pill_w, y0 + pill_h),
        radius=pill_h // 2,
        fill=fg_color,
    )
    screen.alpha_composite(overlay)


def _frame_phone(raw_path: Path, target_height: int) -> Image.Image:
    """Wrap a raw screen capture in a modern dark phone bezel."""
    raw = Image.open(raw_path).convert("RGBA")
    rw, rh = raw.size

    # Reserve top & bottom safe areas matching the test padding (30dp / 24dp @ 2.5x)
    top_pad = int(rh * (30 / 892))
    bottom_pad = int(rh * (24 / 892))
    _draw_status_bar(raw, top_pad=top_pad)
    _draw_nav_bar(raw, bottom_pad=bottom_pad)

    bezel = 26
    outer_w = rw + bezel * 2
    outer_h = rh + bezel * 2
    button_protrusion = 6

    canvas = Image.new("RGBA", (outer_w + button_protrusion, outer_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    # Side hardware buttons on the right edge (volume + power)
    btn_x0 = outer_w - 2
    btn_x1 = outer_w + button_protrusion
    draw.rounded_rectangle(
        (btn_x0, int(outer_h * 0.22), btn_x1, int(outer_h * 0.31)),
        radius=3,
        fill=(44, 46, 52, 255),
    )
    draw.rounded_rectangle(
        (btn_x0, int(outer_h * 0.35), btn_x1, int(outer_h * 0.41)),
        radius=3,
        fill=(44, 46, 52, 255),
    )

    # Outer metallic rim + dark chassis
    outer_radius = 66
    draw.rounded_rectangle(
        (0, 0, outer_w - 1, outer_h - 1),
        radius=outer_radius,
        fill=(22, 23, 27, 255),
        outline=(68, 70, 78, 255),
        width=4,
    )
    # Inner dark bezel lip
    draw.rounded_rectangle(
        (6, 6, outer_w - 7, outer_h - 7),
        radius=outer_radius - 6,
        fill=(10, 10, 12, 255),
        outline=(34, 36, 42, 255),
        width=2,
    )

    # Rounded mask for the screen
    screen_radius = 44
    mask = Image.new("L", (rw, rh), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle((0, 0, rw - 1, rh - 1), radius=screen_radius, fill=255)

    canvas.paste(raw, (bezel, bezel), mask)

    # Scale cleanly to target_height
    scale = target_height / outer_h
    scaled_w = round((outer_w + button_protrusion) * scale)
    return canvas.resize((scaled_w, target_height), Image.Resampling.LANCZOS)


def build_composite(
    input_dir: Path,
    output_path: Path,
    target_height: int = 2224,
    gap: int = 72,
) -> Path:
    phones = [_frame_phone(input_dir / name, target_height) for name in DEFAULT_INPUTS]
    total_w = sum(p.width for p in phones) + gap * (len(phones) - 1)
    composite = Image.new("RGBA", (total_w, target_height), (0, 0, 0, 0))

    x = 0
    for phone in phones:
        composite.alpha_composite(phone, (x, 0))
        x += phone.width + gap

    output_path.parent.mkdir(parents=True, exist_ok=True)
    composite.save(output_path, format="PNG", optimize=True)
    return output_path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input-dir",
        type=Path,
        default=Path("build/readme-screenshots"),
        help="Directory containing the raw 01..04 PNG screenshots.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(".github/readme-images/screens.png"),
        help="Output path for the composite README image.",
    )
    args = parser.parse_args()
    out = build_composite(args.input_dir, args.output)
    print(f"Wrote {out}")


if __name__ == "__main__":
    main()

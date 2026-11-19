import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/palette/color_math.dart';
import 'package:mangabaka_app/core/theme/palette/mb_palette.dart';

/// The theme tests assert the same numbers.
class PaletteContrast {
  const PaletteContrast._();

  static const double text = 7.0;
  static const double textMuted = 4.5;
  static const double onAccent = 4.5;

  /// WCAG's non-text floor: accents and statuses are icon and label colours.
  static const double ui = 3.0;
}

MbPalette derivePalette({
  required Brightness brightness,
  required Color background,
  required Color accent,
  Color? surface,
  Color? surfaceRaised,
  Color? border,
  Color? text,
  Color? textMuted,
  Color? onAccent,
  Color? star,
  Color? success,
  Color? warning,
  Color? error,
  Color? info,
}) {
  final dark = brightness == Brightness.dark;
  final bg = background.withValues(alpha: 1);

  final ink = ColorMath.ensureContrast(
    text ?? (dark ? const Color(0xFFF5F5F5) : const Color(0xFF141414)),
    bg,
    PaletteContrast.text,
  );

  // Light UIs read as layered: near-white cards, controls sunk toward the ink.
  final s1 =
      surface ??
      (dark
          ? ColorMath.mix(bg, ink, 0.04)
          : ColorMath.mix(bg, const Color(0xFFFFFFFF), 0.7));
  final s2 =
      surfaceRaised ??
      (dark ? ColorMath.mix(bg, ink, 0.08) : ColorMath.mix(bg, ink, 0.06));
  final line =
      border ??
      (dark ? ColorMath.mix(bg, ink, 0.11) : ColorMath.mix(bg, ink, 0.14));

  final darkestSurface = _leastContrasting(ink, [bg, s1, s2]);
  final muted = ColorMath.ensureContrast(
    textMuted ?? ColorMath.mix(ink, bg, 0.42),
    darkestSurface,
    PaletteContrast.textMuted,
  );

  Color ui(Color c) => ColorMath.ensureContrast(
    ColorMath.ensureContrast(c, s1, PaletteContrast.ui),
    bg,
    PaletteContrast.ui,
  );

  final acc = ui(accent);
  var onAcc = onAccent ?? ColorMath.onColor(acc);
  if (ColorMath.contrast(onAcc, acc) < PaletteContrast.onAccent) {
    onAcc = ColorMath.onColor(acc);
  }

  return MbPalette(
    brightness: brightness,
    background: bg,
    surface: s1,
    surfaceRaised: s2,
    border: line,
    accent: acc,
    onAccent: onAcc,
    star: ui(
      star ?? (dark ? const Color(0xFFFBD24B) : const Color(0xFFD69E0B)),
    ),
    success: ui(
      success ?? (dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
    ),
    warning: ui(
      warning ?? (dark ? const Color(0xFFFBD24B) : const Color(0xFFB45309)),
    ),
    error: ui(
      error ?? (dark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
    ),
    info: ui(
      info ?? (dark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)),
    ),
    text: ink,
    textMuted: muted,
    shadow: dark ? const Color(0x66000000) : const Color(0x1F000000),
    scrim: dark ? const Color(0x99000000) : const Color(0x66000000),
  );
}

MbPalette withAccent(MbPalette base, Color accent) {
  final acc = ColorMath.ensureContrast(
    ColorMath.ensureContrast(accent, base.surface, PaletteContrast.ui),
    base.background,
    PaletteContrast.ui,
  );
  return base.copyWith(accent: acc, onAccent: ColorMath.onColor(acc));
}

Color _leastContrasting(Color fg, List<Color> candidates) {
  var worst = candidates.first;
  var worstRatio = double.infinity;
  for (final c in candidates) {
    final r = ColorMath.contrast(fg, c);
    if (r < worstRatio) {
      worstRatio = r;
      worst = c;
    }
  }
  return worst;
}

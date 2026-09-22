import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/palette/color_math.dart';
import 'package:mangabaka_app/core/theme/palette/mb_palette.dart';

/// Contrast floors every derived palette is held to. The theme tests assert
/// the same numbers, so a preset that would read badly cannot ship.
class PaletteContrast {
  const PaletteContrast._();

  static const double text = 7.0;
  static const double textMuted = 4.5;
  static const double onAccent = 4.5;

  /// Accent and status colours are used as icon/indicator/label colours on
  /// surfaces — WCAG's non-text (3:1) floor.
  static const double ui = 3.0;
}

/// Builds complete palettes from a handful of seeds.
///
/// Presets, the accent override and user-made custom themes all go through
/// [derivePalette], so a token added later only needs deriving here to exist
/// in every theme.
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

  // Dark themes step surfaces up toward the ink; light themes lift cards to
  // near-white and sink raised controls slightly toward the ink, which is how
  // light UIs read as layered.
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

  // Muted text must stay legible on the lowest-contrast surface it sits on.
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

/// Re-derives [base] around a different accent, keeping everything else.
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

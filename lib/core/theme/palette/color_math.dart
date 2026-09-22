import 'package:flutter/painting.dart';

/// Colour arithmetic shared by palette derivation, the theme editor and the
/// contrast tests. Pure functions only — nothing here reads the active theme.
class ColorMath {
  const ColorMath._();

  /// WCAG 2.x contrast ratio between two opaque colours, 1.0–21.0.
  static double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Linear blend from [a] toward [b]; `t` 0 is [a], 1 is [b].
  static Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  static bool isDark(Color c) => c.computeLuminance() < 0.18;

  /// Returns [fg], or the nearest lightness-shifted variant of it, that reaches
  /// [minRatio] against [bg]. Hue and saturation are kept, so an accent stays
  /// recognisably itself — it just darkens on light surfaces and lightens on
  /// dark ones.
  static Color ensureContrast(Color fg, Color bg, double minRatio) {
    if (contrast(fg, bg) >= minRatio) return fg;
    final towardLight = isDark(bg);
    final hsl = HSLColor.fromColor(fg);
    var l = hsl.lightness;
    for (var i = 0; i < 50; i++) {
      l = (towardLight ? l + 0.02 : l - 0.02).clamp(0.0, 1.0);
      final candidate = hsl.withLightness(l).toColor().withValues(alpha: 1);
      if (contrast(candidate, bg) >= minRatio) return candidate;
      if (l == 0.0 || l == 1.0) break;
    }
    return towardLight ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  }

  /// The ink to put on a [fill]: a near-black tinted with the fill (as the
  /// original design did for its accent) or white — whichever reads better.
  /// Falls back to pure black/white if the tinted ink misses AA.
  static Color onColor(Color fill) {
    final tintedDark = mix(const Color(0xFF0B0B0B), fill, 0.06);
    const light = Color(0xFFFFFFFF);
    final dark = contrast(tintedDark, fill) >= 4.5
        ? tintedDark
        : const Color(0xFF000000);
    return contrast(dark, fill) >= contrast(light, fill) ? dark : light;
  }

  /// `#RRGGBB` for display and the hex field in the editor.
  static String toHex(Color c) {
    final argb = c.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// Parses `RGB`, `RRGGBB` or `AARRGGBB`, with or without `#`. Returns null
  /// for anything else. Alpha is forced opaque: palette colours are surfaces.
  static Color? parseHex(String input) {
    var s = input.trim().replaceFirst('#', '');
    if (s.length == 3) s = s.split('').map((c) => '$c$c').join();
    if (s.length == 8) s = s.substring(2);
    if (s.length != 6) return null;
    final v = int.tryParse(s, radix: 16);
    if (v == null) return null;
    return Color(0xFF000000 | v);
  }
}

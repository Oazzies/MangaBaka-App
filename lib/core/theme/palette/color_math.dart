import 'package:flutter/painting.dart';

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

  static Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  static bool isDark(Color c) => c.computeLuminance() < 0.18;

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

  static Color onColor(Color fill) {
    final tintedDark = mix(const Color(0xFF0B0B0B), fill, 0.06);
    const light = Color(0xFFFFFFFF);
    final dark = contrast(tintedDark, fill) >= 4.5
        ? tintedDark
        : const Color(0xFF000000);
    return contrast(dark, fill) >= contrast(light, fill) ? dark : light;
  }

  static String toHex(Color c) {
    final argb = c.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// Alpha is forced opaque: palette colours are surfaces.
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

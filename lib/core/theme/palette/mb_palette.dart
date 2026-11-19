import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/palette/color_math.dart';

/// New tokens also go in [copyWith], [lerp], JSON, `palette_derivation.dart`.
@immutable
class MbPalette {
  final Brightness brightness;

  final Color background;

  final Color surface;

  final Color surfaceRaised;

  final Color border;

  final Color accent;

  final Color onAccent;

  final Color star;

  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  final Color text;
  final Color textMuted;

  /// Already carries its alpha.
  final Color shadow;

  /// Already carries its alpha.
  final Color scrim;

  const MbPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.accent,
    required this.onAccent,
    required this.star,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.text,
    required this.textMuted,
    required this.shadow,
    required this.scrim,
  });

  bool get isDark => brightness == Brightness.dark;

  List<BoxShadow> get softShadow => [
    BoxShadow(color: shadow, blurRadius: 32, offset: const Offset(0, 8)),
  ];

  Color on(Color fill) => ColorMath.onColor(fill);

  Color hoverOf(Color c, [double amount = 0.15]) =>
      Color.lerp(c, text, amount)!;

  /// Softer on light themes, where the same black reads as a smudge.
  Color shadowAt(double alpha) =>
      const Color(0xFF000000).withValues(alpha: isDark ? alpha : alpha * 0.35);

  Color get backgroundDeep => isDark
      ? Color.lerp(background, const Color(0xFF000000), 0.3)!
      : Color.lerp(background, text, 0.035)!;

  Color legibleOnSurface(Color c) => ColorMath.ensureContrast(c, surface, 3.0);

  Color forState(String state) {
    switch (state) {
      case 'reading':
      case 'rereading':
        return success;
      case 'completed':
        return info;
      case 'paused':
        return warning;
      case 'dropped':
        return error;
      case 'considering':
        return legibleOnSurface(const Color(0xFF9B7BFF));
      default:
        return textMuted;
    }
  }

  Color onForState(String state) => ColorMath.onColor(forState(state));

  Color forSeriesStatus(String status) {
    switch (status.toLowerCase()) {
      case 'releasing':
      case 'ongoing':
        return success;
      case 'completed':
        return info;
      case 'hiatus':
        return warning;
      case 'cancelled':
      case 'canceled':
        return error;
      case 'upcoming':
        return legibleOnSurface(const Color(0xFF9B7BFF));
      default:
        return textMuted;
    }
  }

  Color forSeriesType(String type) {
    switch (type.toLowerCase()) {
      case 'manga':
        return legibleOnSurface(const Color(0xFF4C8DFF));
      case 'manhwa':
        return legibleOnSurface(const Color(0xFF9B7BFF));
      case 'manhua':
        return legibleOnSurface(const Color(0xFFFF9A3D));
      case 'oel':
        return legibleOnSurface(const Color(0xFFFF5C6C));
      case 'novel':
        return legibleOnSurface(const Color(0xFF5CCBFF));
      default:
        return textMuted;
    }
  }

  MbPalette copyWith({
    Brightness? brightness,
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? border,
    Color? accent,
    Color? onAccent,
    Color? star,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? text,
    Color? textMuted,
    Color? shadow,
    Color? scrim,
  }) {
    return MbPalette(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      star: star ?? this.star,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
    );
  }

  static MbPalette lerp(MbPalette a, MbPalette b, double t) {
    Color l(Color x, Color y) => Color.lerp(x, y, t)!;
    return MbPalette(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      background: l(a.background, b.background),
      surface: l(a.surface, b.surface),
      surfaceRaised: l(a.surfaceRaised, b.surfaceRaised),
      border: l(a.border, b.border),
      accent: l(a.accent, b.accent),
      onAccent: l(a.onAccent, b.onAccent),
      star: l(a.star, b.star),
      success: l(a.success, b.success),
      warning: l(a.warning, b.warning),
      error: l(a.error, b.error),
      info: l(a.info, b.info),
      text: l(a.text, b.text),
      textMuted: l(a.textMuted, b.textMuted),
      shadow: l(a.shadow, b.shadow),
      scrim: l(a.scrim, b.scrim),
    );
  }

  Map<String, Color> get tokens => {
    'background': background,
    'surface': surface,
    'surfaceRaised': surfaceRaised,
    'border': border,
    'accent': accent,
    'onAccent': onAccent,
    'star': star,
    'success': success,
    'warning': warning,
    'error': error,
    'info': info,
    'text': text,
    'textMuted': textMuted,
    'shadow': shadow,
    'scrim': scrim,
  };

  Map<String, Object> toJson() => {
    'brightness': brightness.name,
    for (final e in tokens.entries) e.key: e.value.toARGB32(),
  };

  static MbPalette? fromJson(Map<String, Object?> json) {
    Color? c(String k) {
      final v = json[k];
      return v is int ? Color(v) : null;
    }

    final b = json['brightness'] == 'light'
        ? Brightness.light
        : Brightness.dark;
    final values = [
      for (final k in const [
        'background', 'surface', 'surfaceRaised', 'border', 'accent', //
        'onAccent', 'star', 'success', 'warning', 'error', 'info', 'text',
        'textMuted', 'shadow', 'scrim',
      ])
        c(k),
    ];
    if (values.any((v) => v == null)) return null;
    return MbPalette(
      brightness: b,
      background: values[0]!,
      surface: values[1]!,
      surfaceRaised: values[2]!,
      border: values[3]!,
      accent: values[4]!,
      onAccent: values[5]!,
      star: values[6]!,
      success: values[7]!,
      warning: values[8]!,
      error: values[9]!,
      info: values[10]!,
      text: values[11]!,
      textMuted: values[12]!,
      shadow: values[13]!,
      scrim: values[14]!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MbPalette &&
      other.brightness == brightness &&
      _mapEquals(other.tokens, tokens);

  @override
  int get hashCode => Object.hash(brightness, Object.hashAll(tokens.values));

  static bool _mapEquals(Map<String, Color> a, Map<String, Color> b) =>
      a.keys.every((k) => a[k] == b[k]);
}

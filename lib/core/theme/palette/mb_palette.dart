import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/palette/color_math.dart';

/// Every colour the app paints with, as semantic tokens.
///
/// One instance per theme. Widgets read the active one through
/// `context.colors` (see `theme_context.dart`); widgets that preview a theme
/// other than the active one (theme cards, the editor) take an [MbPalette]
/// parameter instead.
///
/// Adding a token: add the field here (constructor, [copyWith], [lerp],
/// [toJson]/[fromJson]), derive it in `palette_derivation.dart`, and the
/// contrast tests cover it across every preset.
@immutable
class MbPalette {
  final Brightness brightness;

  /// Page canvas.
  final Color background;

  /// Cards, sheets, dialogs, menus — one step above [background].
  final Color surface;

  /// Inputs, chips, tracks, pressed rows — one step above [surface].
  final Color surfaceRaised;

  /// Hairlines and outlines.
  final Color border;

  /// The one accent: the "on" state of every control and the primary action.
  final Color accent;

  /// Ink on [accent] fills.
  final Color onAccent;

  /// Rating stars.
  final Color star;

  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  final Color text;
  final Color textMuted;

  /// Drop-shadow colour (already carries its alpha).
  final Color shadow;

  /// Modal barrier / dimming over content (already carries its alpha).
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

  /// The soft elevation shadow used by floating panels and hovered cards.
  List<BoxShadow> get softShadow => [
    BoxShadow(color: shadow, blurRadius: 32, offset: const Offset(0, 8)),
  ];

  /// Legible ink for any [fill] (a status colour, a brand colour, …).
  Color on(Color fill) => ColorMath.onColor(fill);

  /// [c] nudged toward the ink — the hover/pressed step for a filled control.
  /// Lightens on dark themes and darkens on light ones.
  Color hoverOf(Color c, [double amount = 0.15]) => Color.lerp(c, text, amount)!;

  /// A drop-shadow colour at [alpha] as tuned for the dark themes; light
  /// themes get a much softer shadow, since the same black on a pale canvas
  /// reads as a smudge rather than depth.
  Color shadowAt(double alpha) => const Color(0xFF000000)
      .withValues(alpha: isDark ? alpha : alpha * 0.35);

  /// A canvas one step *below* [background], for chrome that should recede
  /// behind the page (the desktop sidebar).
  Color get backgroundDeep => isDark
      ? Color.lerp(background, const Color(0xFF000000), 0.3)!
      : Color.lerp(background, text, 0.035)!;

  /// [c] adjusted until it reads as UI on [surface] — for categorical colours
  /// (content types, publication status) chosen outside the palette.
  Color legibleOnSurface(Color c) =>
      ColorMath.ensureContrast(c, surface, 3.0);

  /// Colour for a library state key (`reading`, `completed`, …).
  Color forState(String state) {
    switch (state) {
      case 'reading':
      case 'rereading':
        return success;
      case 'completed':
        return text;
      case 'paused':
        return warning;
      case 'dropped':
        return error;
      case 'plan_to_read':
        return info;
      case 'considering':
        return accent;
      default:
        return textMuted;
    }
  }

  /// Ink for a [forState] fill.
  Color onForState(String state) {
    if (state == 'considering') return onAccent;
    return ColorMath.onColor(forState(state));
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

  /// Named-token map, used by the contrast tests and debug tooling.
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

  /// Returns null when a token is missing or malformed.
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

  static bool _mapEquals(Map<String, Color> a, Map<String, Color> b) {
    for (final k in a.keys) {
      if (a[k] != b[k]) return false;
    }
    return true;
  }
}

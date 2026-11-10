import 'package:flutter/material.dart';

/// MangaBaka type system — "Ink & Amber".
///   • Bakbak One — heavy squarish display caps for titles, headers and labels
///   • Outfit     — geometric sans for UI & body text
///
/// The reference design sets every header in uppercase display caps and every
/// body string in a geometric sans; there is no third (serif or mono) voice.
///
/// Both faces are bundled as assets rather than fetched at runtime: the whole
/// design language rests on the display face, and a network-fetched font falls
/// back to a generic grotesque on first launch (or on any offline start),
/// which visibly breaks the design.
class AppTypography {
  const AppTypography._();

  static const String displayFamily = 'BakbakOne';
  static const String sansFamily = 'Outfit';

  static bool _testMode = false;

  /// Enable in tests to skip font resolution.
  @visibleForTesting
  static void setTestMode(bool value) => _testMode = value;

  /// Heavy display caps (Bakbak One). Used for screen headers, section rails
  /// and series titles. Callers pass already-uppercased text.
  static TextStyle display({
    Color? color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) {
    // Bakbak One ships a single weight; tracking opens up slightly at display
    // sizes and tightens at label sizes so caps stay readable either way.
    final tracking =
        letterSpacing ??
        (fontSize != null ? (fontSize >= 20 ? 0.5 : fontSize * 0.06) : null);
    return TextStyle(
      fontFamily: _testMode ? null : displayFamily,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: tracking,
      height: height,
      shadows: shadows,
    );
  }

  /// UI / body sans (Outfit), bundled as static 400/500/600/700 instances so
  /// [fontWeight] resolves natively — including through `copyWith` on styles
  /// that came from the [TextTheme].
  static TextStyle sans({
    Color? color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: _testMode ? null : sansFamily,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Uppercase, letter-spaced display label — the signature section/metadata
  /// label of the design system (e.g. "ALL BOOKS", "MY LIST").
  static TextStyle monoLabel({
    Color? color,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return display(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: fontSize * 0.1,
      height: 1.2,
    );
  }

  /// Builds the global [TextTheme]: Outfit everywhere, with Bakbak One
  /// promoted onto the display / headline / title roles.
  static TextTheme textTheme(TextTheme base) {
    if (_testMode) return base;

    TextStyle? toDisplay(TextStyle? s) {
      if (s == null) return null;
      final size = s.fontSize ?? 16;
      return s.copyWith(
        fontFamily: displayFamily,
        fontWeight: FontWeight.w400,
        letterSpacing: size >= 20 ? 0.5 : size * 0.06,
      );
    }

    return base
        .apply(fontFamily: sansFamily)
        .copyWith(
          displayLarge: toDisplay(base.displayLarge),
          displayMedium: toDisplay(base.displayMedium),
          displaySmall: toDisplay(base.displaySmall),
          headlineLarge: toDisplay(base.headlineLarge),
          headlineMedium: toDisplay(base.headlineMedium),
          headlineSmall: toDisplay(base.headlineSmall),
          titleLarge: toDisplay(base.titleLarge),
        );
  }
}

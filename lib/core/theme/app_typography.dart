import 'package:flutter/material.dart';

/// Bundled, not fetched: a fetched font falls back on first or offline launch.
class AppTypography {
  const AppTypography._();

  static const String displayFamily = 'BakbakOne';
  static const String sansFamily = 'Outfit';

  static bool _testMode = false;

  @visibleForTesting
  static void setTestMode(bool value) => _testMode = value;

  /// Callers pass already-uppercased text.
  static TextStyle display({
    Color? color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) {
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

  /// Outfit ships as static 400/500/600/700 so [fontWeight] resolves natively.
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

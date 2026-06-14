import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MangaBaka type system (Claude Design handoff):
///   • Newsreader      — warm display serif for titles / headlines
///   • Hanken Grotesk  — UI & body text
///   • Spline Sans Mono — metadata / section labels ("database" feel)
class AppTypography {
  const AppTypography._();

  static bool _testMode = false;

  /// Enable in tests to skip Google Fonts network fetching.
  @visibleForTesting
  static void setTestMode(bool value) => _testMode = value;

  /// Warm display serif (Newsreader). Used for series titles and headlines.
  static TextStyle serif({
    Color? color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w500,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
    FontStyle? fontStyle,
  }) {
    if (_testMode) {
      return TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing ?? (fontSize != null ? -0.018 * fontSize : null),
        height: height,
        shadows: shadows,
        fontStyle: fontStyle,
      );
    }
    return GoogleFonts.newsreader(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing ??
          (fontSize != null ? -0.018 * fontSize : null),
      height: height,
      shadows: shadows,
      fontStyle: fontStyle,
    );
  }

  /// UI / body sans (Hanken Grotesk).
  static TextStyle sans({
    Color? color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    double? height,
  }) {
    if (_testMode) {
      return TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
    return GoogleFonts.hankenGrotesk(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Monospace (Spline Sans Mono).
  static TextStyle mono({
    Color? color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w500,
    double? letterSpacing,
    double? height,
  }) {
    if (_testMode) {
      return TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        fontFamily: 'monospace',
      );
    }
    return GoogleFonts.splineSansMono(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Uppercase, letter-spaced mono label — the signature metadata/section
  /// label of the design system (e.g. "GENRES & TAGS", "MY LIST").
  static TextStyle monoLabel({
    Color? color,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    if (_testMode) {
      return TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: fontSize * 0.14,
        height: 1.2,
        fontFamily: 'monospace',
      );
    }
    return GoogleFonts.splineSansMono(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: fontSize * 0.14,
      height: 1.2,
    );
  }

  /// Builds the global [TextTheme]: Hanken Grotesk everywhere, with Newsreader
  /// serif promoted onto the large display / headline / title roles.
  static TextTheme textTheme(TextTheme base) {
    if (_testMode) return base;

    final body = GoogleFonts.hankenGroteskTextTheme(base);

    TextStyle? toSerif(TextStyle? s) {
      if (s == null) return null;
      return GoogleFonts.newsreader(textStyle: s).copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: -0.018 * (s.fontSize ?? 16),
      );
    }

    return body.copyWith(
      displayLarge: toSerif(body.displayLarge),
      displayMedium: toSerif(body.displayMedium),
      displaySmall: toSerif(body.displaySmall),
      headlineLarge: toSerif(body.headlineLarge),
      headlineMedium: toSerif(body.headlineMedium),
      headlineSmall: toSerif(body.headlineSmall),
      titleLarge: toSerif(body.titleLarge),
    );
  }
}

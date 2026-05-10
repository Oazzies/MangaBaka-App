import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/theme/theme_palette_data.dart';

enum AppTheme {
  defaultTheme,
  catppuccin,
  greenApple,
  lavender,
  midnightDusk,
  nord,
  strawberryDaiquiri,
  tako,
  tealTurquoise,
  tidalWave,
  yinYang,
  yotsuba,
  monochrome,
}

class ThemePalette {
  final Color primaryBackground;
  final Color secondaryBackground;
  final Color tertiaryBackground;
  final Color border;
  final Color accent;
  final Color primaryAccent;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color text;
  final Color textMuted;

  ThemePalette({
    required this.primaryBackground,
    required this.secondaryBackground,
    required this.tertiaryBackground,
    required this.border,
    required this.accent,
    required this.primaryAccent,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.text,
    required this.textMuted,
  });
}

class AppThemeColors {
  static ThemePalette getPalette(AppTheme theme, bool isDark) {
    return ThemePaletteData.getThemePalette(theme, isDark);
  }

  static void applyTheme(AppTheme theme, bool isDark) {
    final palette = getPalette(theme, isDark);

    AppConstants.primaryBackground = palette.primaryBackground;
    AppConstants.secondaryBackground = palette.secondaryBackground;
    AppConstants.tertiaryBackground = palette.tertiaryBackground;
    AppConstants.accentColor = palette.accent;
    AppConstants.primaryAccent = palette.primaryAccent;
    AppConstants.borderColor = palette.border;
    AppConstants.successColor = palette.success;
    AppConstants.warningColor = palette.warning;
    AppConstants.errorColor = palette.error;
    AppConstants.infoColor = palette.info;
    AppConstants.textColor = palette.text;
    AppConstants.textMutedColor = palette.textMuted;
  }
}

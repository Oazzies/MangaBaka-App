import 'package:flutter/material.dart';
import 'app_theme_colors.dart';

class ThemePaletteData {
  static ThemePalette getThemePalette(AppTheme theme, bool isDark) {
    switch (theme) {
      case AppTheme.defaultTheme:
        return _getDefault(isDark);
      case AppTheme.monochrome:
        return _getMonochrome(isDark);
      case AppTheme.catppuccin:
        return _getCatppuccin(isDark);
      case AppTheme.greenApple:
        return _getGreenApple(isDark);
      case AppTheme.lavender:
        return _getLavender(isDark);
      case AppTheme.midnightDusk:
        return _getMidnightDusk(isDark);
      case AppTheme.nord:
        return _getNord(isDark);
      case AppTheme.strawberryDaiquiri:
        return _getStrawberryDaiquiri(isDark);
      case AppTheme.tako:
        return _getTako(isDark);
      case AppTheme.tealTurquoise:
        return _getTealTurquoise(isDark);
      case AppTheme.tidalWave:
        return _getTidalWave(isDark);
      case AppTheme.yinYang:
        return _getYinYang(isDark);
      case AppTheme.yotsuba:
        return _getYotsuba(isDark);
    }
  }

  static ThemePalette _createPalette({
    required bool isDark,
    required Color primary,
    required Color secondary,
    required Color tertiary,
    required Color border,
    required Color accent,
    required Color primaryAccent,
    Color? text,
    Color? textMuted,
  }) {
    return ThemePalette(
      primaryBackground: primary,
      secondaryBackground: secondary,
      tertiaryBackground: tertiary,
      border: border,
      accent: accent,
      primaryAccent: primaryAccent,
      success: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
      warning: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
      error: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
      info: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
      text: text ?? (isDark ? const Color(0xFFFAFAFA) : const Color(0xFF09090B)),
      textMuted: textMuted ?? (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A)),
    );
  }

  static ThemePalette _getDefault(bool isDark) {
    return _createPalette(
      isDark: isDark,
      primary: isDark ? const Color(0xFF09090B) : const Color(0xFFF4F4F5),
      secondary: isDark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF),
      tertiary: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
      border: isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8),
      accent: const Color(0xFF10B981),
      primaryAccent: const Color(0xFF047857),
    );
  }

  static ThemePalette _getMonochrome(bool isDark) {
    return _createPalette(
      isDark: isDark,
      primary: isDark ? const Color(0xFF000000) : const Color(0xFFF5F5F5),
      secondary: isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF),
      tertiary: isDark ? const Color(0xFF242424) : const Color(0xFFE5E5E5),
      border: isDark ? const Color(0xFF404040) : const Color(0xFFD4D4D4),
      accent: isDark ? const Color(0xFFE5E5E5) : const Color(0xFF171717),
      primaryAccent: const Color(0xFF737373),
    );
  }

  static ThemePalette _getCatppuccin(bool isDark) {
    return _createPalette(
      isDark: isDark,
      primary: isDark ? const Color(0xFF11111B) : const Color(0xFFE6E9EF),
      secondary: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
      tertiary: isDark ? const Color(0xFF313244) : const Color(0xFFCCD0DA),
      border: isDark ? const Color(0xFF45475A) : const Color(0xFFBCC0CC),
      accent: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF),
      primaryAccent: isDark ? const Color(0xFF89B4FA) : const Color(0xFF1E66F5),
      text: isDark ? const Color(0xFFCDD6F4) : const Color(0xFF4C4F69),
      textMuted: isDark ? const Color(0xFFBAC2DE) : const Color(0xFF6C6F85),
    );
  }

  static ThemePalette _getGreenApple(bool isDark) {
    return _createPalette(
      isDark: isDark,
      primary: isDark ? const Color(0xFF020617) : const Color(0xFFF1F5F9),
      secondary: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
      tertiary: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      border: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
      accent: isDark ? const Color(0xFF84CC16) : const Color(0xFF65A30D),
      primaryAccent: isDark ? const Color(0xFF4D7C0F) : const Color(0xFF3F6212),
      text: isDark ? null : const Color(0xFF020617),
      textMuted: isDark ? null : const Color(0xFF64748B),
    );
  }

  static ThemePalette _getLavender(bool isDark) {
    return _createPalette(
      isDark: isDark,
      primary: isDark ? const Color(0xFF171026) : const Color(0xFFF5F3FF),
      secondary: isDark ? const Color(0xFF211736) : const Color(0xFFFFFFFF),
      tertiary: isDark ? const Color(0xFF322352) : const Color(0xFFEDE9FE),
      border: isDark ? const Color(0xFF4A347A) : const Color(0xFFDDD6FE),
      accent: isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6),
      primaryAccent: isDark ? const Color(0xFF7C3AED) : const Color(0xFF6D28D9),
      text: isDark ? null : const Color(0xFF2E1065),
      textMuted: isDark ? null : const Color(0xFF7C3AED),
    );
  }

  static ThemePalette _getMidnightDusk(bool isDark) {
    return _createPalette(
      isDark: isDark,
      primary: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF3F4F6),
      secondary: isDark ? const Color(0xFF111827) : const Color(0xFFFFFFFF),
      tertiary: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
      border: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
      accent: isDark ? const Color(0xFFF43F5E) : const Color(0xFFE11D48),
      primaryAccent: isDark ? const Color(0xFFBE123C) : const Color(0xFF9F1239),
      text: isDark ? null : const Color(0xFF030712),
      textMuted: isDark ? null : const Color(0xFF6B7280),
    );
  }

  static ThemePalette _getNord(bool isDark) {
    return _createPalette(
      isDark: isDark,
      primary: isDark ? const Color(0xFF242933) : const Color(0xFFE5E9F0),
      secondary: isDark ? const Color(0xFF2E3440) : const Color(0xFFECEFF4),
      tertiary: isDark ? const Color(0xFF3B4252) : const Color(0xFFD8DEE9),
      border: isDark ? const Color(0xFF4C566A) : const Color(0xFFBCC6D6),
      accent: isDark ? const Color(0xFF88C0D0) : const Color(0xFF5E81AC),
      primaryAccent: isDark ? const Color(0xFF5E81AC) : const Color(0xFF81A1C1),
      text: isDark ? const Color(0xFFECEFF4) : const Color(0xFF2E3440),
      textMuted: isDark ? const Color(0xFFD8DEE9) : const Color(0xFF4C566A),
    );
  }

  static ThemePalette _getStrawberryDaiquiri(bool isDark) {
    return _createPalette(
      isDark: isDark,
      primary: isDark ? const Color(0xFF2A0813) : const Color(0xFFFFF1F2),
      secondary: isDark ? const Color(0xFF3F0B1C) : const Color(0xFFFFFFFF),
      tertiary: isDark ? const Color(0xFF61112B) : const Color(0xFFFFE4E6),
      border: isDark ? const Color(0xFF8B183E) : const Color(0xFFFECDD3),
      accent: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48),
      primaryAccent: isDark ? const Color(0xFFE11D48) : const Color(0xFFBE123C),
      text: isDark ? null : const Color(0xFF4C0519),
      textMuted: isDark ? null : const Color(0xFFBE123C),
    );
  }

  static ThemePalette _getTako(bool isDark) {
    return _createPalette(
      isDark: isDark,
      primary: isDark ? const Color(0xFF141016) : const Color(0xFFFAF5FF),
      secondary: isDark ? const Color(0xFF221A26) : const Color(0xFFFFFFFF),
      tertiary: isDark ? const Color(0xFF35293A) : const Color(0xFFF3E8FF),
      border: isDark ? const Color(0xFF4D3B54) : const Color(0xFFE9D5FF),
      accent: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
      primaryAccent: isDark ? const Color(0xFFD97706) : const Color(0xFFB45309),
      text: isDark ? null : const Color(0xFF3B0764),
      textMuted: isDark ? null : const Color(0xFF7E22CE),
    );
  }

  static ThemePalette _getTealTurquoise(bool isDark) {
    return _createPalette(
      isDark: isDark,
      primary: isDark ? const Color(0xFF042F2E) : const Color(0xFFF0FDFA),
      secondary: isDark ? const Color(0xFF134E4A) : const Color(0xFFFFFFFF),
      tertiary: isDark ? const Color(0xFF115E59) : const Color(0xFFCCFBF1),
      border: isDark ? const Color(0xFF0F766E) : const Color(0xFF99F6E4),
      accent: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
      primaryAccent: isDark ? const Color(0xFF0D9488) : const Color(0xFF0F766E),
      text: isDark ? null : const Color(0xFF042F2E),
      textMuted: isDark ? null : const Color(0xFF0F766E),
    );
  }

  static ThemePalette _getTidalWave(bool isDark) {
    return _createPalette(
      isDark: isDark,
      primary: isDark ? const Color(0xFF082F49) : const Color(0xFFF0F9FF),
      secondary: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFFFFFFF),
      tertiary: isDark ? const Color(0xFF075985) : const Color(0xFFE0F2FE),
      border: isDark ? const Color(0xFF0369A1) : const Color(0xFFBAE6FD),
      accent: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
      primaryAccent: isDark ? const Color(0xFF0284C7) : const Color(0xFF0369A1),
      text: isDark ? null : const Color(0xFF082F49),
      textMuted: isDark ? null : const Color(0xFF0369A1),
    );
  }

  static ThemePalette _getYinYang(bool isDark) {
    return _createPalette(
      isDark: isDark,
      primary: isDark ? const Color(0xFF000000) : const Color(0xFFF5F5F5),
      secondary: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFFFFFF),
      tertiary: isDark ? const Color(0xFF171717) : const Color(0xFFE5E5E5),
      border: isDark ? const Color(0xFF262626) : const Color(0xFFD4D4D4),
      accent: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
      primaryAccent: isDark ? const Color(0xFFE5E5E5) : const Color(0xFF171717),
      text: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
      textMuted: isDark ? null : const Color(0xFF525252),
    );
  }

  static ThemePalette _getYotsuba(bool isDark) {
    return _createPalette(
      isDark: isDark,
      primary: isDark ? const Color(0xFF431407) : const Color(0xFFFFF7ED),
      secondary: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFFFFF),
      tertiary: isDark ? const Color(0xFF9A3412) : const Color(0xFFFFEDD5),
      border: isDark ? const Color(0xFFC2410C) : const Color(0xFFFED7AA),
      accent: isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C),
      primaryAccent: isDark ? const Color(0xFFEA580C) : const Color(0xFFC2410C),
      text: isDark ? null : const Color(0xFF431407),
      textMuted: isDark ? null : const Color(0xFFC2410C),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

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
    // Default fallback values (Dark Mode)
    Color basePrimary = const Color(0xFF09090B);
    Color baseSecondary = const Color(0xFF18181B);
    Color baseTertiary = const Color(0xFF27272A);
    Color baseBorder = const Color(0xFF3F3F46);
    Color baseAccent = const Color(0xFF10B981);
    Color basePrimaryAccent = const Color(0xFF047857);
    Color baseSuccess = isDark ? const Color(0xFF34D399) : const Color(0xFF059669); 
    Color baseWarning = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706); 
    Color baseError = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626); 
    Color baseInfo = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB); 
    Color baseText = const Color(0xFFFAFAFA);
    Color baseTextMuted = const Color(0xFFA1A1AA);

    switch (theme) {
      case AppTheme.defaultTheme:
        if (isDark) {
          basePrimary = const Color(0xFF09090B);
          baseSecondary = const Color(0xFF18181B);
          baseTertiary = const Color(0xFF27272A);
          baseBorder = const Color(0xFF3F3F46);
          baseAccent = const Color(0xFF10B981);
          basePrimaryAccent = const Color(0xFF047857);
        } else {
          basePrimary = const Color(0xFFF4F4F5);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFE4E4E7);
          baseBorder = const Color(0xFFD4D4D8);
          baseAccent = const Color(0xFF10B981);
          basePrimaryAccent = const Color(0xFF047857);
          baseText = const Color(0xFF09090B);
          baseTextMuted = const Color(0xFF71717A);
        }
        break;
      case AppTheme.monochrome:
        if (isDark) {
          basePrimary = const Color(0xFF000000);
          baseSecondary = const Color(0xFF121212);
          baseTertiary = const Color(0xFF242424);
          baseBorder = const Color(0xFF404040);
          baseAccent = const Color(0xFFE5E5E5);
          basePrimaryAccent = const Color(0xFF737373);
        } else {
          basePrimary = const Color(0xFFF5F5F5);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFE5E5E5);
          baseBorder = const Color(0xFFD4D4D4);
          baseAccent = const Color(0xFF171717);
          basePrimaryAccent = const Color(0xFF737373);
          baseText = const Color(0xFF0A0A0A);
          baseTextMuted = const Color(0xFF737373);
        }
        break;
      case AppTheme.catppuccin:
        if (isDark) {
          basePrimary = const Color(0xFF11111B);
          baseSecondary = const Color(0xFF1E1E2E);
          baseTertiary = const Color(0xFF313244);
          baseBorder = const Color(0xFF45475A);
          baseAccent = const Color(0xFFCBA6F7);
          basePrimaryAccent = const Color(0xFF89B4FA);
          baseText = const Color(0xFFCDD6F4);
          baseTextMuted = const Color(0xFFBAC2DE);
        } else {
          basePrimary = const Color(0xFFE6E9EF);
          baseSecondary = const Color(0xFFEFF1F5);
          baseTertiary = const Color(0xFFCCD0DA);
          baseBorder = const Color(0xFFBCC0CC);
          baseAccent = const Color(0xFF8839EF);
          basePrimaryAccent = const Color(0xFF1E66F5);
          baseText = const Color(0xFF4C4F69);
          baseTextMuted = const Color(0xFF6C6F85);
        }
        break;
      case AppTheme.greenApple:
        if (isDark) {
          basePrimary = const Color(0xFF020617);
          baseSecondary = const Color(0xFF0F172A);
          baseTertiary = const Color(0xFF1E293B);
          baseBorder = const Color(0xFF334155);
          baseAccent = const Color(0xFF84CC16);
          basePrimaryAccent = const Color(0xFF4D7C0F);
        } else {
          basePrimary = const Color(0xFFF1F5F9);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFE2E8F0);
          baseBorder = const Color(0xFFCBD5E1);
          baseAccent = const Color(0xFF65A30D);
          basePrimaryAccent = const Color(0xFF3F6212);
          baseText = const Color(0xFF020617);
          baseTextMuted = const Color(0xFF64748B);
        }
        break;
      case AppTheme.lavender:
        if (isDark) {
          basePrimary = const Color(0xFF171026);
          baseSecondary = const Color(0xFF211736);
          baseTertiary = const Color(0xFF322352);
          baseBorder = const Color(0xFF4A347A);
          baseAccent = const Color(0xFFA78BFA);
          basePrimaryAccent = const Color(0xFF7C3AED);
        } else {
          basePrimary = const Color(0xFFF5F3FF);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFEDE9FE);
          baseBorder = const Color(0xFFDDD6FE);
          baseAccent = const Color(0xFF8B5CF6);
          basePrimaryAccent = const Color(0xFF6D28D9);
          baseText = const Color(0xFF2E1065);
          baseTextMuted = const Color(0xFF7C3AED);
        }
        break;
      case AppTheme.midnightDusk:
        if (isDark) {
          basePrimary = const Color(0xFF0B0F19);
          baseSecondary = const Color(0xFF111827);
          baseTertiary = const Color(0xFF1F2937);
          baseBorder = const Color(0xFF374151);
          baseAccent = const Color(0xFFF43F5E);
          basePrimaryAccent = const Color(0xFFBE123C);
        } else {
          basePrimary = const Color(0xFFF3F4F6);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFE5E7EB);
          baseBorder = const Color(0xFFD1D5DB);
          baseAccent = const Color(0xFFE11D48);
          basePrimaryAccent = const Color(0xFF9F1239);
          baseText = const Color(0xFF030712);
          baseTextMuted = const Color(0xFF6B7280);
        }
        break;
      case AppTheme.nord:
        if (isDark) {
          basePrimary = const Color(0xFF242933);
          baseSecondary = const Color(0xFF2E3440);
          baseTertiary = const Color(0xFF3B4252);
          baseBorder = const Color(0xFF4C566A);
          baseAccent = const Color(0xFF88C0D0);
          basePrimaryAccent = const Color(0xFF5E81AC);
          baseText = const Color(0xFFECEFF4);
          baseTextMuted = const Color(0xFFD8DEE9);
        } else {
          basePrimary = const Color(0xFFE5E9F0);
          baseSecondary = const Color(0xFFECEFF4);
          baseTertiary = const Color(0xFFD8DEE9);
          baseBorder = const Color(0xFFBCC6D6);
          baseAccent = const Color(0xFF5E81AC);
          basePrimaryAccent = const Color(0xFF81A1C1);
          baseText = const Color(0xFF2E3440);
          baseTextMuted = const Color(0xFF4C566A);
        }
        break;
      case AppTheme.strawberryDaiquiri:
        if (isDark) {
          basePrimary = const Color(0xFF2A0813);
          baseSecondary = const Color(0xFF3F0B1C);
          baseTertiary = const Color(0xFF61112B);
          baseBorder = const Color(0xFF8B183E);
          baseAccent = const Color(0xFFFB7185);
          basePrimaryAccent = const Color(0xFFE11D48);
        } else {
          basePrimary = const Color(0xFFFFF1F2);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFFFE4E6);
          baseBorder = const Color(0xFFFECDD3);
          baseAccent = const Color(0xFFE11D48);
          basePrimaryAccent = const Color(0xFFBE123C);
          baseText = const Color(0xFF4C0519);
          baseTextMuted = const Color(0xFFBE123C);
        }
        break;
      case AppTheme.tako:
        if (isDark) {
          basePrimary = const Color(0xFF141016);
          baseSecondary = const Color(0xFF221A26);
          baseTertiary = const Color(0xFF35293A);
          baseBorder = const Color(0xFF4D3B54);
          baseAccent = const Color(0xFFFBBF24);
          basePrimaryAccent = const Color(0xFFD97706);
        } else {
          basePrimary = const Color(0xFFFAF5FF);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFF3E8FF);
          baseBorder = const Color(0xFFE9D5FF);
          baseAccent = const Color(0xFFD97706);
          basePrimaryAccent = const Color(0xFFB45309);
          baseText = const Color(0xFF3B0764);
          baseTextMuted = const Color(0xFF7E22CE);
        }
        break;
      case AppTheme.tealTurquoise:
        if (isDark) {
          basePrimary = const Color(0xFF042F2E);
          baseSecondary = const Color(0xFF134E4A);
          baseTertiary = const Color(0xFF115E59);
          baseBorder = const Color(0xFF0F766E);
          baseAccent = const Color(0xFF2DD4BF);
          basePrimaryAccent = const Color(0xFF0D9488);
        } else {
          basePrimary = const Color(0xFFF0FDFA);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFCCFBF1);
          baseBorder = const Color(0xFF99F6E4);
          baseAccent = const Color(0xFF0D9488);
          basePrimaryAccent = const Color(0xFF0F766E);
          baseText = const Color(0xFF042F2E);
          baseTextMuted = const Color(0xFF0F766E);
        }
        break;
      case AppTheme.tidalWave:
        if (isDark) {
          basePrimary = const Color(0xFF082F49);
          baseSecondary = const Color(0xFF0C4A6E);
          baseTertiary = const Color(0xFF075985);
          baseBorder = const Color(0xFF0369A1);
          baseAccent = const Color(0xFF38BDF8);
          basePrimaryAccent = const Color(0xFF0284C7);
        } else {
          basePrimary = const Color(0xFFF0F9FF);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFE0F2FE);
          baseBorder = const Color(0xFFBAE6FD);
          baseAccent = const Color(0xFF0284C7);
          basePrimaryAccent = const Color(0xFF0369A1);
          baseText = const Color(0xFF082F49);
          baseTextMuted = const Color(0xFF0369A1);
        }
        break;
      case AppTheme.yinYang:
        if (isDark) {
          basePrimary = const Color(0xFF000000);
          baseSecondary = const Color(0xFF0A0A0A);
          baseTertiary = const Color(0xFF171717);
          baseBorder = const Color(0xFF262626);
          baseAccent = const Color(0xFFFFFFFF);
          basePrimaryAccent = const Color(0xFFE5E5E5);
          baseText = const Color(0xFFFFFFFF);
        } else {
          basePrimary = const Color(0xFFF5F5F5);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFE5E5E5);
          baseBorder = const Color(0xFFD4D4D4);
          baseAccent = const Color(0xFF000000);
          basePrimaryAccent = const Color(0xFF171717);
          baseText = const Color(0xFF000000);
          baseTextMuted = const Color(0xFF525252);
        }
        break;
      case AppTheme.yotsuba:
        if (isDark) {
          basePrimary = const Color(0xFF431407);
          baseSecondary = const Color(0xFF7C2D12);
          baseTertiary = const Color(0xFF9A3412);
          baseBorder = const Color(0xFFC2410C);
          baseAccent = const Color(0xFFFB923C);
          basePrimaryAccent = const Color(0xFFEA580C);
        } else {
          basePrimary = const Color(0xFFFFF7ED);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFFFEDD5);
          baseBorder = const Color(0xFFFED7AA);
          baseAccent = const Color(0xFFEA580C);
          basePrimaryAccent = const Color(0xFFC2410C);
          baseText = const Color(0xFF431407);
          baseTextMuted = const Color(0xFFC2410C);
        }
        break;
    }

    return ThemePalette(
      primaryBackground: basePrimary,
      secondaryBackground: baseSecondary,
      tertiaryBackground: baseTertiary,
      border: baseBorder,
      accent: baseAccent,
      primaryAccent: basePrimaryAccent,
      success: baseSuccess,
      warning: baseWarning,
      error: baseError,
      info: baseInfo,
      text: baseText,
      textMuted: baseTextMuted,
    );
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

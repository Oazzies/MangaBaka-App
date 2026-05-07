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

class AppThemeColors {
  static void applyTheme(AppTheme theme, bool isDark) {
    // Default fallback values (Dark Mode)
    Color basePrimary = const Color(0xFF09090B);
    Color baseSecondary = const Color(0xFF18181B);
    Color baseTertiary = const Color(0xFF27272A);
    Color baseBorder = const Color(0xFF3F3F46);
    Color baseAccent = const Color(0xFF10B981);
    Color basePrimaryAccent = const Color(0xFF047857);
    Color baseSuccess = const Color(0xFF34D399);
    Color baseWarning = const Color(0xFFFBBF24);
    Color baseError = const Color(0xFFF87171);
    Color baseInfo = const Color(0xFF60A5FA);
    Color baseText = const Color(0xFFFAFAFA);
    Color baseTextMuted = const Color(0xFFA1A1AA);

    switch (theme) {
      case AppTheme.defaultTheme:
        if (isDark) {
          basePrimary = const Color(0xFF09090B); // Zinc 950
          baseSecondary = const Color(0xFF18181B); // Zinc 900
          baseTertiary = const Color(0xFF27272A); // Zinc 800
          baseBorder = const Color(0xFF3F3F46); // Zinc 700
          baseAccent = const Color(0xFF10B981); // Emerald 500
          basePrimaryAccent = const Color(0xFF047857); // Emerald 700
        } else {
          basePrimary = const Color(0xFFF4F4F5); // Zinc 100
          baseSecondary = const Color(0xFFFFFFFF); // White
          baseTertiary = const Color(0xFFE4E4E7); // Zinc 200
          baseBorder = const Color(0xFFD4D4D8); // Zinc 300
          baseAccent = const Color(0xFF10B981); // Emerald 500
          basePrimaryAccent = const Color(0xFF047857); // Emerald 700
          baseText = const Color(0xFF09090B); // Zinc 950
          baseTextMuted = const Color(0xFF71717A); // Zinc 500
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
          basePrimary = const Color(0xFF11111B); // Crust
          baseSecondary = const Color(0xFF1E1E2E); // Base
          baseTertiary = const Color(0xFF313244); // Surface0
          baseBorder = const Color(0xFF45475A); // Surface1
          baseAccent = const Color(0xFFCBA6F7); // Mauve
          basePrimaryAccent = const Color(0xFF89B4FA); // Blue
          baseText = const Color(0xFFCDD6F4); // Text
          baseTextMuted = const Color(0xFFBAC2DE); // Subtext1
        } else {
          basePrimary = const Color(0xFFE6E9EF); // Mantle
          baseSecondary = const Color(0xFFEFF1F5); // Base
          baseTertiary = const Color(0xFFCCD0DA); // Surface0
          baseBorder = const Color(0xFFBCC0CC); // Surface1
          baseAccent = const Color(0xFF8839EF); // Mauve
          basePrimaryAccent = const Color(0xFF1E66F5); // Blue
          baseText = const Color(0xFF4C4F69); // Text
          baseTextMuted = const Color(0xFF6C6F85); // Subtext1
        }
        break;
      case AppTheme.greenApple:
        if (isDark) {
          basePrimary = const Color(0xFF020617); // Slate 950
          baseSecondary = const Color(0xFF0F172A); // Slate 900
          baseTertiary = const Color(0xFF1E293B); // Slate 800
          baseBorder = const Color(0xFF334155); // Slate 700
          baseAccent = const Color(0xFF84CC16); // Lime 500
          basePrimaryAccent = const Color(0xFF4D7C0F); // Lime 700
        } else {
          basePrimary = const Color(0xFFF1F5F9); // Slate 100
          baseSecondary = const Color(0xFFFFFFFF); // White
          baseTertiary = const Color(0xFFE2E8F0); // Slate 200
          baseBorder = const Color(0xFFCBD5E1); // Slate 300
          baseAccent = const Color(0xFF65A30D); // Lime 600
          basePrimaryAccent = const Color(0xFF3F6212); // Lime 800
          baseText = const Color(0xFF020617); // Slate 950
          baseTextMuted = const Color(0xFF64748B); // Slate 500
        }
        break;
      case AppTheme.lavender:
        if (isDark) {
          basePrimary = const Color(0xFF171026); // Custom Deep Violet
          baseSecondary = const Color(0xFF211736); 
          baseTertiary = const Color(0xFF322352);
          baseBorder = const Color(0xFF4A347A);
          baseAccent = const Color(0xFFA78BFA); // Violet 400
          basePrimaryAccent = const Color(0xFF7C3AED); // Violet 600
        } else {
          basePrimary = const Color(0xFFF5F3FF); // Violet 50
          baseSecondary = const Color(0xFFFFFFFF); // White
          baseTertiary = const Color(0xFFEDE9FE); // Violet 100
          baseBorder = const Color(0xFFDDD6FE); // Violet 200
          baseAccent = const Color(0xFF8B5CF6); // Violet 500
          basePrimaryAccent = const Color(0xFF6D28D9); // Violet 700
          baseText = const Color(0xFF2E1065); // Violet 950
          baseTextMuted = const Color(0xFF7C3AED); // Violet 600
        }
        break;
      case AppTheme.midnightDusk:
        if (isDark) {
          basePrimary = const Color(0xFF0B0F19); // Custom Night Blue
          baseSecondary = const Color(0xFF111827); // Gray 900
          baseTertiary = const Color(0xFF1F2937); // Gray 800
          baseBorder = const Color(0xFF374151); // Gray 700
          baseAccent = const Color(0xFFF43F5E); // Rose 500
          basePrimaryAccent = const Color(0xFFBE123C); // Rose 700
        } else {
          basePrimary = const Color(0xFFF3F4F6); // Gray 100
          baseSecondary = const Color(0xFFFFFFFF); // White
          baseTertiary = const Color(0xFFE5E7EB); // Gray 200
          baseBorder = const Color(0xFFD1D5DB); // Gray 300
          baseAccent = const Color(0xFFE11D48); // Rose 600
          basePrimaryAccent = const Color(0xFF9F1239); // Rose 800
          baseText = const Color(0xFF030712); // Gray 950
          baseTextMuted = const Color(0xFF6B7280); // Gray 500
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
          basePrimary = const Color(0xFF2A0813); // Custom Dark Ruby
          baseSecondary = const Color(0xFF3F0B1C); 
          baseTertiary = const Color(0xFF61112B);
          baseBorder = const Color(0xFF8B183E);
          baseAccent = const Color(0xFFFB7185); // Rose 400
          basePrimaryAccent = const Color(0xFFE11D48); // Rose 600
        } else {
          basePrimary = const Color(0xFFFFF1F2); // Rose 50
          baseSecondary = const Color(0xFFFFFFFF); // White
          baseTertiary = const Color(0xFFFFE4E6); // Rose 100
          baseBorder = const Color(0xFFFECDD3); // Rose 200
          baseAccent = const Color(0xFFE11D48); // Rose 600
          basePrimaryAccent = const Color(0xFFBE123C); // Rose 700
          baseText = const Color(0xFF4C0519); // Rose 950
          baseTextMuted = const Color(0xFFBE123C); // Rose 700
        }
        break;
      case AppTheme.tako:
        if (isDark) {
          basePrimary = const Color(0xFF141016);
          baseSecondary = const Color(0xFF221A26);
          baseTertiary = const Color(0xFF35293A);
          baseBorder = const Color(0xFF4D3B54);
          baseAccent = const Color(0xFFFBBF24); // Amber 400
          basePrimaryAccent = const Color(0xFFD97706); // Amber 600
        } else {
          basePrimary = const Color(0xFFFAF5FF); // Purple 50
          baseSecondary = const Color(0xFFFFFFFF); // White
          baseTertiary = const Color(0xFFF3E8FF); // Purple 100
          baseBorder = const Color(0xFFE9D5FF); // Purple 200
          baseAccent = const Color(0xFFD97706); // Amber 600
          basePrimaryAccent = const Color(0xFFB45309); // Amber 700
          baseText = const Color(0xFF3B0764); // Purple 950
          baseTextMuted = const Color(0xFF7E22CE); // Purple 700
        }
        break;
      case AppTheme.tealTurquoise:
        if (isDark) {
          basePrimary = const Color(0xFF042F2E); // Teal 950
          baseSecondary = const Color(0xFF134E4A); // Teal 900
          baseTertiary = const Color(0xFF115E59); // Teal 800
          baseBorder = const Color(0xFF0F766E); // Teal 700
          baseAccent = const Color(0xFF2DD4BF); // Teal 400
          basePrimaryAccent = const Color(0xFF0D9488); // Teal 600
        } else {
          basePrimary = const Color(0xFFF0FDFA); // Teal 50
          baseSecondary = const Color(0xFFFFFFFF); // White
          baseTertiary = const Color(0xFFCCFBF1); // Teal 100
          baseBorder = const Color(0xFF99F6E4); // Teal 200
          baseAccent = const Color(0xFF0D9488); // Teal 600
          basePrimaryAccent = const Color(0xFF0F766E); // Teal 700
          baseText = const Color(0xFF042F2E); // Teal 950
          baseTextMuted = const Color(0xFF0F766E); // Teal 700
        }
        break;
      case AppTheme.tidalWave:
        if (isDark) {
          basePrimary = const Color(0xFF082F49); // Sky 950
          baseSecondary = const Color(0xFF0C4A6E); // Sky 900
          baseTertiary = const Color(0xFF075985); // Sky 800
          baseBorder = const Color(0xFF0369A1); // Sky 700
          baseAccent = const Color(0xFF38BDF8); // Sky 400
          basePrimaryAccent = const Color(0xFF0284C7); // Sky 600
        } else {
          basePrimary = const Color(0xFFF0F9FF); // Sky 50
          baseSecondary = const Color(0xFFFFFFFF); // White
          baseTertiary = const Color(0xFFE0F2FE); // Sky 100
          baseBorder = const Color(0xFFBAE6FD); // Sky 200
          baseAccent = const Color(0xFF0284C7); // Sky 600
          basePrimaryAccent = const Color(0xFF0369A1); // Sky 700
          baseText = const Color(0xFF082F49); // Sky 950
          baseTextMuted = const Color(0xFF0369A1); // Sky 700
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
          basePrimary = const Color(0xFF431407); // Orange 950
          baseSecondary = const Color(0xFF7C2D12); // Orange 900
          baseTertiary = const Color(0xFF9A3412); // Orange 800
          baseBorder = const Color(0xFFC2410C); // Orange 700
          baseAccent = const Color(0xFFFB923C); // Orange 400
          basePrimaryAccent = const Color(0xFFEA580C); // Orange 600
        } else {
          basePrimary = const Color(0xFFFFF7ED); // Orange 50
          baseSecondary = const Color(0xFFFFFFFF); // White
          baseTertiary = const Color(0xFFFFEDD5); // Orange 100
          baseBorder = const Color(0xFFFED7AA); // Orange 200
          baseAccent = const Color(0xFFEA580C); // Orange 600
          basePrimaryAccent = const Color(0xFFC2410C); // Orange 700
          baseText = const Color(0xFF431407); // Orange 950
          baseTextMuted = const Color(0xFFC2410C); // Orange 700
        }
        break;
    }

    AppConstants.primaryBackground = basePrimary;
    AppConstants.secondaryBackground = baseSecondary;
    AppConstants.tertiaryBackground = baseTertiary;
    AppConstants.accentColor = baseAccent;
    AppConstants.primaryAccent = basePrimaryAccent;
    AppConstants.borderColor = baseBorder;
    AppConstants.successColor = baseSuccess;
    AppConstants.warningColor = baseWarning;
    AppConstants.errorColor = baseError;
    AppConstants.infoColor = baseInfo;
    AppConstants.textColor = baseText;
    AppConstants.textMutedColor = baseTextMuted;
  }
}

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
    // Default fallback values
    Color basePrimary = isDark ? const Color(0xFF050505) : const Color(0xFFF2F2F5);
    Color baseSecondary = isDark ? const Color(0xFF161618) : const Color(0xFFFFFFFF);
    Color baseTertiary = isDark ? const Color(0xFF28282C) : const Color(0xFFE2E2E8);
    Color baseAccent = isDark ? const Color(0xFF1b9f70) : const Color(0xFF10b981);
    Color basePrimaryAccent = isDark ? const Color(0xFF00301d) : const Color(0xFF047857);
    Color baseBorder = isDark ? const Color(0xFF404045) : const Color(0xFFC8C8D0);
    Color baseSuccess = isDark ? const Color(0xFF81e6ca) : const Color(0xFF34d399);
    Color baseWarning = isDark ? const Color(0xFFffc83e) : const Color(0xFFfbbf24);
    Color baseError = isDark ? const Color(0xFFef4444) : const Color(0xFFdc2626);
    Color baseInfo = isDark ? const Color(0xFF3b82f6) : const Color(0xFF2563eb);
    Color baseText = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF09090B);
    Color baseTextMuted = isDark ? const Color(0x8AFFFFFF) : const Color(0xFF71717A);

    switch (theme) {
      case AppTheme.defaultTheme:
        if (isDark) {
          basePrimary = const Color(0xFF050505);
          baseSecondary = const Color(0xFF161618);
          baseTertiary = const Color(0xFF28282C);
          baseBorder = const Color(0xFF404045);
        } else {
          basePrimary = const Color(0xFFF2F2F5);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFE2E2E8);
          baseBorder = const Color(0xFFC8C8D0);
        }
        break;
      case AppTheme.monochrome:
        if (isDark) {
          basePrimary = const Color(0xFF000000);
          baseSecondary = const Color(0xFF141414);
          baseTertiary = const Color(0xFF282828);
          baseBorder = const Color(0xFF444444);
          baseAccent = const Color(0xFFE5E5E5);
          basePrimaryAccent = const Color(0xFF737373);
        } else {
          basePrimary = const Color(0xFFF0F0F0);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFE0E0E0);
          baseBorder = const Color(0xFFBDBDBD);
          baseAccent = const Color(0xFF171717);
          basePrimaryAccent = const Color(0xFF737373);
          baseText = const Color(0xFF000000);
          baseTextMuted = const Color(0x8A000000);
        }
        break;
      case AppTheme.catppuccin:
        if (isDark) {
          basePrimary = const Color(0xFF11111B); // Crust
          baseSecondary = const Color(0xFF1E1E2E); // Base
          baseTertiary = const Color(0xFF313244); // Surface0
          baseBorder = const Color(0xFF45475A); // Surface1
          baseAccent = const Color(0xFFCBA6F7);
          basePrimaryAccent = const Color(0xFFB4BEFE);
          baseText = const Color(0xFFCDD6F4);
          baseTextMuted = const Color(0xFFBAC2DE);
        } else {
          basePrimary = const Color(0xFFE6E9EF); // Mantle
          baseSecondary = const Color(0xFFEFF1F5); // Base (lightest)
          baseTertiary = const Color(0xFFCCD0DA); // Surface0
          baseBorder = const Color(0xFFBCC0CC); // Surface1
          baseAccent = const Color(0xFF8839EF);
          basePrimaryAccent = const Color(0xFF7287FD);
          baseText = const Color(0xFF4C4F69);
          baseTextMuted = const Color(0xFF6C6F85);
        }
        break;
      case AppTheme.greenApple:
        if (isDark) {
          basePrimary = const Color(0xFF070B14);
          baseSecondary = const Color(0xFF121B2B);
          baseTertiary = const Color(0xFF22324A);
          baseBorder = const Color(0xFF3B4E6B);
          baseAccent = const Color(0xFF84CC16);
          basePrimaryAccent = const Color(0xFF65A30D);
        } else {
          basePrimary = const Color(0xFFEEF2F6);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFDFE6F0);
          baseBorder = const Color(0xFFC0CDDF);
          baseAccent = const Color(0xFF65A30D);
          basePrimaryAccent = const Color(0xFF4D7C0F);
        }
        break;
      case AppTheme.lavender:
        if (isDark) {
          basePrimary = const Color(0xFF0E0D14);
          baseSecondary = const Color(0xFF1A1724);
          baseTertiary = const Color(0xFF2A2538);
          baseBorder = const Color(0xFF423A54);
          baseAccent = const Color(0xFFB4A1E5);
          basePrimaryAccent = const Color(0xFF9074D6);
        } else {
          basePrimary = const Color(0xFFEBE7F2);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFDBD4E8);
          baseBorder = const Color(0xFFBDB2D4);
          baseAccent = const Color(0xFF8E75D3);
          basePrimaryAccent = const Color(0xFF6E51B8);
        }
        break;
      case AppTheme.midnightDusk:
        if (isDark) {
          basePrimary = const Color(0xFF0A0A0C);
          baseSecondary = const Color(0xFF14141B);
          baseTertiary = const Color(0xFF242430);
          baseBorder = const Color(0xFF383848);
          baseAccent = const Color(0xFFF03A47);
          basePrimaryAccent = const Color(0xFFC02C36);
        } else {
          basePrimary = const Color(0xFFEBEBEF);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFDADAE0);
          baseBorder = const Color(0xFFBEBECA);
          baseAccent = const Color(0xFFD81E2B);
          basePrimaryAccent = const Color(0xFFA51420);
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
          basePrimary = const Color(0xFF100709);
          baseSecondary = const Color(0xFF1C0D13);
          baseTertiary = const Color(0xFF301620);
          baseBorder = const Color(0xFF4D2434);
          baseAccent = const Color(0xFFE0315B);
          basePrimaryAccent = const Color(0xFFB82548);
        } else {
          basePrimary = const Color(0xFFFFDFE6);
          baseSecondary = const Color(0xFFFFF0F3);
          baseTertiary = const Color(0xFFFFC7D2);
          baseBorder = const Color(0xFFFFA3B4);
          baseAccent = const Color(0xFFC92A52);
          basePrimaryAccent = const Color(0xFFA12040);
        }
        break;
      case AppTheme.tako:
        if (isDark) {
          basePrimary = const Color(0xFF141016);
          baseSecondary = const Color(0xFF221A26);
          baseTertiary = const Color(0xFF35293A);
          baseBorder = const Color(0xFF4D3B54);
          baseAccent = const Color(0xFFF3B61F);
          basePrimaryAccent = const Color(0xFFC59215);
        } else {
          basePrimary = const Color(0xFFE5D5ED);
          baseSecondary = const Color(0xFFF6F0F8);
          baseTertiary = const Color(0xFFD6C0E1);
          baseBorder = const Color(0xFFBBA0CA);
          baseAccent = const Color(0xFFD49A00);
          basePrimaryAccent = const Color(0xFFA37700);
        }
        break;
      case AppTheme.tealTurquoise:
        if (isDark) {
          basePrimary = const Color(0xFF070B0C);
          baseSecondary = const Color(0xFF10191B);
          baseTertiary = const Color(0xFF1B2C30);
          baseBorder = const Color(0xFF2A4449);
          baseAccent = const Color(0xFF20C997);
          basePrimaryAccent = const Color(0xFF12B886);
        } else {
          basePrimary = const Color(0xFFD6EBEF);
          baseSecondary = const Color(0xFFECF6F8);
          baseTertiary = const Color(0xFFC0DEE4);
          baseBorder = const Color(0xFFA2CCD5);
          baseAccent = const Color(0xFF0CA678);
          basePrimaryAccent = const Color(0xFF099268);
        }
        break;
      case AppTheme.tidalWave:
        if (isDark) {
          basePrimary = const Color(0xFF050A10);
          baseSecondary = const Color(0xFF0D1724);
          baseTertiary = const Color(0xFF18293F);
          baseBorder = const Color(0xFF264060);
          baseAccent = const Color(0xFF0EA5E9);
          basePrimaryAccent = const Color(0xFF0284C7);
        } else {
          basePrimary = const Color(0xFFDBEAF3);
          baseSecondary = const Color(0xFFF0F6FA);
          baseTertiary = const Color(0xFFC8DFEE);
          baseBorder = const Color(0xFFA5CBE2);
          baseAccent = const Color(0xFF0284C7);
          basePrimaryAccent = const Color(0xFF0369A1);
        }
        break;
      case AppTheme.yinYang:
        if (isDark) {
          basePrimary = const Color(0xFF000000);
          baseSecondary = const Color(0xFF141414);
          baseTertiary = const Color(0xFF282828);
          baseBorder = const Color(0xFF444444);
          baseAccent = const Color(0xFFFFFFFF);
          basePrimaryAccent = const Color(0xFFE0E0E0);
          baseText = const Color(0xFFFFFFFF);
        } else {
          basePrimary = const Color(0xFFF0F0F0);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFE0E0E0);
          baseBorder = const Color(0xFFBDBDBD);
          baseAccent = const Color(0xFF000000);
          basePrimaryAccent = const Color(0xFF222222);
          baseText = const Color(0xFF000000);
        }
        break;
      case AppTheme.yotsuba:
        if (isDark) {
          basePrimary = const Color(0xFF120E0D);
          baseSecondary = const Color(0xFF201918);
          baseTertiary = const Color(0xFF332725);
          baseBorder = const Color(0xFF4D3B38);
          baseAccent = const Color(0xFFF97316);
          basePrimaryAccent = const Color(0xFFEA580C);
        } else {
          basePrimary = const Color(0xFFF8E3D8);
          baseSecondary = const Color(0xFFFEF9F6);
          baseTertiary = const Color(0xFFF2D1BF);
          baseBorder = const Color(0xFFE6B49D);
          baseAccent = const Color(0xFFEA580C);
          basePrimaryAccent = const Color(0xFFC2410C);
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

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
    // Defaults to help avoid uninitialized colors
    Color basePrimary = isDark ? const Color(0xFF0a0a0a) : const Color(0xFFFAFAFA);
    Color baseSecondary = isDark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF);
    Color baseTertiary = isDark ? const Color(0xFF23232a) : const Color(0xFFF4F4F5);
    Color baseAccent = isDark ? const Color(0xFF1b9f70) : const Color(0xFF10b981);
    Color basePrimaryAccent = isDark ? const Color(0xFF00301d) : const Color(0xFF047857);
    Color baseBorder = isDark ? const Color(0xFF3f3f46) : const Color(0xFFE4E4E7);
    Color baseSuccess = isDark ? const Color(0xFF81e6ca) : const Color(0xFF34d399);
    Color baseWarning = isDark ? const Color(0xFFffc83e) : const Color(0xFFfbbf24);
    Color baseError = isDark ? const Color(0xFFef4444) : const Color(0xFFdc2626);
    Color baseInfo = isDark ? const Color(0xFF3b82f6) : const Color(0xFF2563eb);
    Color baseText = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF09090B);
    Color baseTextMuted = isDark ? const Color(0x8AFFFFFF) : const Color(0xFF71717A);

    switch (theme) {
      case AppTheme.defaultTheme:
        break;
      case AppTheme.monochrome:
        if (isDark) {
          basePrimary = const Color(0xFF000000);
          baseSecondary = const Color(0xFF111111);
          baseTertiary = const Color(0xFF222222);
          baseAccent = const Color(0xFFE5E5E5);
          basePrimaryAccent = const Color(0xFF404040);
          baseBorder = const Color(0xFF333333);
        } else {
          basePrimary = const Color(0xFFFFFFFF);
          baseSecondary = const Color(0xFFF5F5F5);
          baseTertiary = const Color(0xFFE5E5E5);
          baseAccent = const Color(0xFF171717);
          basePrimaryAccent = const Color(0xFFD4D4D4);
          baseBorder = const Color(0xFFE5E5E5);
          baseText = const Color(0xFF000000);
          baseTextMuted = const Color(0x8A000000);
        }
        break;
      case AppTheme.catppuccin:
        if (isDark) {
          basePrimary = const Color(0xFF1e1e2e);
          baseSecondary = const Color(0xFF181825);
          baseTertiary = const Color(0xFF11111b);
          baseAccent = const Color(0xFFcba6f7);
          basePrimaryAccent = const Color(0xFFb4befe);
          baseBorder = const Color(0xFF313244);
          baseText = const Color(0xFFcdd6f4);
          baseTextMuted = const Color(0xFFbac2de);
        } else {
          basePrimary = const Color(0xFFeff1f5);
          baseSecondary = const Color(0xFFe6e9ef);
          baseTertiary = const Color(0xFFdce0e8);
          baseAccent = const Color(0xFF8839ef);
          basePrimaryAccent = const Color(0xFF7287fd);
          baseBorder = const Color(0xFFbcc0cc);
          baseText = const Color(0xFF4c4f69);
          baseTextMuted = const Color(0xFF6c6f85);
        }
        break;
      case AppTheme.greenApple:
        if (isDark) {
          basePrimary = const Color(0xFF0F172A);
          baseSecondary = const Color(0xFF1E293B);
          baseTertiary = const Color(0xFF334155);
          baseAccent = const Color(0xFF84CC16);
          basePrimaryAccent = const Color(0xFF65A30D);
          baseBorder = const Color(0xFF475569);
        } else {
          basePrimary = const Color(0xFFF8FAFC);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFF1F5F9);
          baseAccent = const Color(0xFF65A30D);
          basePrimaryAccent = const Color(0xFF4D7C0F);
          baseBorder = const Color(0xFFE2E8F0);
        }
        break;
      case AppTheme.lavender:
        if (isDark) {
          basePrimary = const Color(0xFF171520);
          baseSecondary = const Color(0xFF1F1D2B);
          baseTertiary = const Color(0xFF2A273A);
          baseAccent = const Color(0xFFB4A1E5);
          basePrimaryAccent = const Color(0xFF9074D6);
          baseBorder = const Color(0xFF3B3754);
        } else {
          basePrimary = const Color(0xFFF8F7FA);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFF0EDF6);
          baseAccent = const Color(0xFF8E75D3);
          basePrimaryAccent = const Color(0xFF6E51B8);
          baseBorder = const Color(0xFFE5DFEF);
        }
        break;
      case AppTheme.midnightDusk:
        if (isDark) {
          basePrimary = const Color(0xFF121217);
          baseSecondary = const Color(0xFF1A1A24);
          baseTertiary = const Color(0xFF252533);
          baseAccent = const Color(0xFFF03A47);
          basePrimaryAccent = const Color(0xFFC02C36);
          baseBorder = const Color(0xFF343447);
        } else {
          basePrimary = const Color(0xFFF5F5F7);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFEAEAF0);
          baseAccent = const Color(0xFFD81E2B);
          basePrimaryAccent = const Color(0xFFA51420);
          baseBorder = const Color(0xFFDADBDF);
        }
        break;
      case AppTheme.nord:
        if (isDark) {
          basePrimary = const Color(0xFF2E3440);
          baseSecondary = const Color(0xFF3B4252);
          baseTertiary = const Color(0xFF434C5E);
          baseAccent = const Color(0xFF88C0D0);
          basePrimaryAccent = const Color(0xFF5E81AC);
          baseBorder = const Color(0xFF4C566A);
          baseText = const Color(0xFFECEFF4);
          baseTextMuted = const Color(0xFFD8DEE9);
        } else {
          basePrimary = const Color(0xFFECEFF4);
          baseSecondary = const Color(0xFFE5E9F0);
          baseTertiary = const Color(0xFFD8DEE9);
          baseAccent = const Color(0xFF5E81AC);
          basePrimaryAccent = const Color(0xFF81A1C1);
          baseBorder = const Color(0xFFD8DEE9);
          baseText = const Color(0xFF2E3440);
          baseTextMuted = const Color(0xFF4C566A);
        }
        break;
      case AppTheme.strawberryDaiquiri:
        if (isDark) {
          basePrimary = const Color(0xFF1A0B10);
          baseSecondary = const Color(0xFF241017);
          baseTertiary = const Color(0xFF331621);
          baseAccent = const Color(0xFFE0315B);
          basePrimaryAccent = const Color(0xFFB82548);
          baseBorder = const Color(0xFF4A2030);
        } else {
          basePrimary = const Color(0xFFFFF1F4);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFFFE3E8);
          baseAccent = const Color(0xFFC92A52);
          basePrimaryAccent = const Color(0xFFA12040);
          baseBorder = const Color(0xFFFFCCD5);
        }
        break;
      case AppTheme.tako:
        if (isDark) {
          basePrimary = const Color(0xFF201A23);
          baseSecondary = const Color(0xFF2B222F);
          baseTertiary = const Color(0xFF392C3E);
          baseAccent = const Color(0xFFF3B61F);
          basePrimaryAccent = const Color(0xFFC59215);
          baseBorder = const Color(0xFF4D3B54);
        } else {
          basePrimary = const Color(0xFFF4EDF6);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFEADDF0);
          baseAccent = const Color(0xFFD49A00);
          basePrimaryAccent = const Color(0xFFA37700);
          baseBorder = const Color(0xFFDFCCEA);
        }
        break;
      case AppTheme.tealTurquoise:
        if (isDark) {
          basePrimary = const Color(0xFF0E1719);
          baseSecondary = const Color(0xFF142225);
          baseTertiary = const Color(0xFF1B2E32);
          baseAccent = const Color(0xFF20C997);
          basePrimaryAccent = const Color(0xFF12B886);
          baseBorder = const Color(0xFF254045);
        } else {
          basePrimary = const Color(0xFFE6F3F5);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFD6EBEF);
          baseAccent = const Color(0xFF0CA678);
          basePrimaryAccent = const Color(0xFF099268);
          baseBorder = const Color(0xFFBCE0E6);
        }
        break;
      case AppTheme.tidalWave:
        if (isDark) {
          basePrimary = const Color(0xFF0B131E);
          baseSecondary = const Color(0xFF111D2D);
          baseTertiary = const Color(0xFF19293E);
          baseAccent = const Color(0xFF0EA5E9);
          basePrimaryAccent = const Color(0xFF0284C7);
          baseBorder = const Color(0xFF233956);
        } else {
          basePrimary = const Color(0xFFF0F6FA);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFE0EEF6);
          baseAccent = const Color(0xFF0284C7);
          basePrimaryAccent = const Color(0xFF0369A1);
          baseBorder = const Color(0xFFCDE3F0);
        }
        break;
      case AppTheme.yinYang:
        if (isDark) {
          basePrimary = const Color(0xFF121212);
          baseSecondary = const Color(0xFF1E1E1E);
          baseTertiary = const Color(0xFF2C2C2C);
          baseAccent = const Color(0xFFFFFFFF);
          basePrimaryAccent = const Color(0xFFE0E0E0);
          baseBorder = const Color(0xFF3D3D3D);
          baseText = const Color(0xFFFFFFFF);
        } else {
          basePrimary = const Color(0xFFFFFFFF);
          baseSecondary = const Color(0xFFF5F5F5);
          baseTertiary = const Color(0xFFEBEBEB);
          baseAccent = const Color(0xFF000000);
          basePrimaryAccent = const Color(0xFF222222);
          baseBorder = const Color(0xFFE0E0E0);
          baseText = const Color(0xFF000000);
        }
        break;
      case AppTheme.yotsuba:
        if (isDark) {
          basePrimary = const Color(0xFF1E1B1A);
          baseSecondary = const Color(0xFF2B2523);
          baseTertiary = const Color(0xFF38302D);
          baseAccent = const Color(0xFFF97316);
          basePrimaryAccent = const Color(0xFFEA580C);
          baseBorder = const Color(0xFF4C413D);
        } else {
          basePrimary = const Color(0xFFFEF9F6);
          baseSecondary = const Color(0xFFFFFFFF);
          baseTertiary = const Color(0xFFFBECE4);
          baseAccent = const Color(0xFFEA580C);
          basePrimaryAccent = const Color(0xFFC2410C);
          baseBorder = const Color(0xFFF5D6C6);
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

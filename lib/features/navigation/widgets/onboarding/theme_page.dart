import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  String _getThemeModeName(ThemeMode mode, LocalizationService localization) {
    switch (mode) {
      case ThemeMode.light: return localization.translate('theme_mode_light');
      case ThemeMode.dark: return localization.translate('theme_mode_dark');
      case ThemeMode.system: return localization.translate('theme_mode_system');
    }
  }

  Color _getThemeAccentColor(AppTheme theme, bool isDark) {
    switch (theme) {
      case AppTheme.defaultTheme: return isDark ? const Color(0xFF1b9f70) : const Color(0xFF10b981);
      case AppTheme.monochrome: return isDark ? const Color(0xFFE5E5E5) : const Color(0xFF171717);
      case AppTheme.catppuccin: return isDark ? const Color(0xFFcba6f7) : const Color(0xFF8839ef);
      case AppTheme.greenApple: return isDark ? const Color(0xFF84CC16) : const Color(0xFF65A30D);
      case AppTheme.lavender: return isDark ? const Color(0xFFB4A1E5) : const Color(0xFF8E75D3);
      case AppTheme.midnightDusk: return isDark ? const Color(0xFFF03A47) : const Color(0xFFD81E2B);
      case AppTheme.nord: return isDark ? const Color(0xFF88C0D0) : const Color(0xFF5E81AC);
      case AppTheme.strawberryDaiquiri: return isDark ? const Color(0xFFE0315B) : const Color(0xFFC92A52);
      case AppTheme.tako: return isDark ? const Color(0xFFF3B61F) : const Color(0xFFD49A00);
      case AppTheme.tealTurquoise: return isDark ? const Color(0xFF20C997) : const Color(0xFF0CA678);
      case AppTheme.tidalWave: return isDark ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7);
      case AppTheme.yinYang: return isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
      case AppTheme.yotsuba: return isDark ? const Color(0xFFF97316) : const Color(0xFFEA580C);
    }
  }

  String _getThemeName(AppTheme theme, LocalizationService localization) {
    switch (theme) {
      case AppTheme.defaultTheme: return localization.translate('theme_default');
      case AppTheme.catppuccin: return localization.translate('theme_catppuccin');
      case AppTheme.greenApple: return localization.translate('theme_green_apple');
      case AppTheme.lavender: return localization.translate('theme_lavender');
      case AppTheme.midnightDusk: return localization.translate('theme_midnight_dusk');
      case AppTheme.nord: return localization.translate('theme_nord');
      case AppTheme.strawberryDaiquiri: return localization.translate('theme_strawberry_daiquiri');
      case AppTheme.tako: return localization.translate('theme_tako');
      case AppTheme.tealTurquoise: return localization.translate('theme_teal_turquoise');
      case AppTheme.tidalWave: return localization.translate('theme_tidal_wave');
      case AppTheme.yinYang: return localization.translate('theme_yin_yang');
      case AppTheme.yotsuba: return localization.translate('theme_yotsuba');
      case AppTheme.monochrome: return localization.translate('theme_monochrome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeManager(), LocalizationService()]),
      builder: (context, _) {
        final localization = LocalizationService();
        final currentMode = ThemeManager().currentThemeMode;
        final currentTheme = ThemeManager().currentTheme;
        
        bool isActuallyDark = false;
        if (currentMode == ThemeMode.system) {
          isActuallyDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
        } else {
          isActuallyDark = currentMode == ThemeMode.dark;
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                localization.translate('onboarding_theme_title'),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localization.translate('onboarding_theme_subtitle'),
                style: TextStyle(
                  fontSize: 16,
                  color: AppConstants.textMutedColor,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppConstants.secondaryBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppConstants.borderColor.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: ThemeMode.values.map((mode) {
                            final isSelected = mode == currentMode;
                            return Expanded(
                              child: InkWell(
                                onTap: () => ThemeManager().setThemeMode(mode),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppConstants.accentColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getThemeModeName(mode, localization),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected ? AppConstants.primaryBackground : AppConstants.textColor,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Column(
                        children: AppTheme.values.map((theme) {
                          final isSelected = theme == currentTheme;
                          final accent = _getThemeAccentColor(theme, isActuallyDark);
                          final themeName = _getThemeName(theme, localization);
                      
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => ThemeManager().setTheme(theme),
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? AppConstants.accentColor.withValues(alpha: 0.15) 
                                      : AppConstants.secondaryBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected 
                                        ? AppConstants.accentColor 
                                        : AppConstants.borderColor.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: accent,
                                        shape: BoxShape.circle,
                                        border: isSelected 
                                            ? Border.all(color: AppConstants.textColor.withValues(alpha: 0.5), width: 2)
                                            : null,
                                      ),
                                      child: isSelected 
                                          ? Icon(Icons.check, color: AppConstants.primaryBackground, size: 20)
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        themeName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? AppConstants.textColor : AppConstants.textColor.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.radio_button_checked, color: AppConstants.accentColor, size: 20)
                                    else
                                      Icon(Icons.radio_button_off, color: AppConstants.textMutedColor, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

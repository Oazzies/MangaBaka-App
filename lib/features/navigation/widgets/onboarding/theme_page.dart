import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/features/profile/widgets/theme_preview_item.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  String _getThemeModeName(ThemeMode mode, LocalizationService localization) {
    switch (mode) {
      case ThemeMode.light: return localization.translate('theme_mode_light');
      case ThemeMode.dark: return localization.translate('theme_mode_dark');
      case ThemeMode.system: return localization.translate('theme_mode_system');
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
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

              // Theme Mode Selector
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
              // Big Horizontal Theme List
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: AppTheme.values.length,
                  itemBuilder: (context, index) {
                    final theme = AppTheme.values[index];
                    final isSelected = theme == currentTheme;
                    final themeName = _getThemeName(theme, localization);
                
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 0 : 0,
                        right: 32,
                      ),
                      child: Center(
                        child: ThemePreviewItem(
                          theme: theme,
                          isDark: isActuallyDark,
                          isSelected: isSelected,
                          onTap: () => ThemeManager().setTheme(theme),
                          label: themeName,
                          scale: 2.1,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

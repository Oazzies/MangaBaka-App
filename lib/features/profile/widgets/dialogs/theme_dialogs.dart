import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';


import 'package:mangabaka_app/features/profile/widgets/theme_preview_item.dart';
import 'selection_bottom_sheet.dart';

class ThemeDialogs {
  static String getThemeModeName(ThemeMode mode) {
    final l10n = LocalizationService();
    switch (mode) {
      case ThemeMode.light:
        return l10n.translate('theme_mode_light');
      case ThemeMode.dark:
        return l10n.translate('theme_mode_dark');
      case ThemeMode.system:
        return l10n.translate('theme_mode_system');
    }
  }
  static String getThemeName(AppTheme theme) {
    final l10n = LocalizationService();
    switch (theme) {
      case AppTheme.defaultTheme: return l10n.translate('theme_default');
      case AppTheme.catppuccin: return l10n.translate('theme_catppuccin');
      case AppTheme.greenApple: return l10n.translate('theme_green_apple');
      case AppTheme.lavender: return l10n.translate('theme_lavender');
      case AppTheme.midnightDusk: return l10n.translate('theme_midnight_dusk');
      case AppTheme.nord: return l10n.translate('theme_nord');
      case AppTheme.strawberryDaiquiri: return l10n.translate('theme_strawberry_daiquiri');
      case AppTheme.tako: return l10n.translate('theme_tako');
      case AppTheme.tealTurquoise: return l10n.translate('theme_teal_turquoise');
      case AppTheme.tidalWave: return l10n.translate('theme_tidal_wave');
      case AppTheme.yinYang: return l10n.translate('theme_yin_yang');
      case AppTheme.yotsuba: return l10n.translate('theme_yotsuba');
      case AppTheme.monochrome: return l10n.translate('theme_monochrome');
    }
  }
  static void showThemeModeSelectionDialog(BuildContext context) {
    final l10n = LocalizationService();
    SelectionBottomSheet.showSelectionBottomSheet<ThemeMode>(
      context: context,
      title: l10n.translate('theme_mode'),
      subtitle: l10n.translate('theme_mode_subtitle'),
      options: ThemeMode.values,
      currentValue: ThemeManager().currentThemeMode,
      getLabel: getThemeModeName,
      onSelected: (mode) {
        Future.delayed(const Duration(milliseconds: 250), () {
          ThemeManager().setThemeMode(mode);
        });
      },
    );
  }
  static void showThemeSelectionDialog(BuildContext context) {
    final l10n = LocalizationService();
    final themeManager = ThemeManager();
    final isDark = themeManager.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext dialogContext) {
        return ListenableBuilder(
          listenable: themeManager,
          builder: (context, _) {
            final currentTheme = themeManager.currentTheme;

            return Container(
              decoration: BoxDecoration(
                color: AppConstants.secondaryBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppConstants.borderColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      l10n.translate('app_theme'),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      l10n.translate('app_theme_subtitle'),
                      style: TextStyle(
                        color: AppConstants.textMutedColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemCount: AppTheme.values.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final theme = AppTheme.values[index];
                        final isSelected = currentTheme == theme;

                        return ThemePreviewItem(
                          theme: theme,
                          isDark: isDark,
                          isSelected: isSelected,
                          label: getThemeName(theme),
                          onTap: () {
                            themeManager.setTheme(theme);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';

class SettingsDialogs {
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

  static void _showSelectionBottomSheet<T>({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<T> options,
    required T currentValue,
    required String Function(T) getLabel,
    required void Function(T) onSelected,
    bool isScrollable = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollable,
      builder: (BuildContext dialogContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: AppConstants.secondaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 60),
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
              Text(
                title,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppConstants.textMutedColor,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              if (isScrollable)
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) => _buildOptionRow(
                      options[index],
                      currentValue,
                      getLabel,
                      onSelected,
                      dialogContext,
                    ),
                  ),
                )
              else
                ...options.map((option) => _buildOptionRow(
                      option,
                      currentValue,
                      getLabel,
                      onSelected,
                      dialogContext,
                    )),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildOptionRow<T>(
    T option,
    T currentValue,
    String Function(T) getLabel,
    void Function(T) onSelected,
    BuildContext context,
  ) {
    final isSelected = option == currentValue;
    return GestureDetector(
      onTap: () {
        onSelected(option);
        Navigator.pop(context);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppConstants.borderColor.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              getLabel(option),
              style: TextStyle(
                color: isSelected ? AppConstants.textColor : AppConstants.textMutedColor,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Icon(
                      Icons.check_circle,
                      key: const ValueKey('checked'),
                      color: AppConstants.accentColor,
                      size: 24,
                    )
                  : Icon(
                      Icons.circle_outlined,
                      key: const ValueKey('unchecked'),
                      color: AppConstants.borderColor.withValues(alpha: 0.3),
                      size: 24,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static void showThemeModeSelectionDialog(BuildContext context) {
    final l10n = LocalizationService();
    _showSelectionBottomSheet<ThemeMode>(
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
    _showSelectionBottomSheet<AppTheme>(
      context: context,
      title: l10n.translate('app_theme'),
      subtitle: l10n.translate('app_theme_subtitle'),
      options: AppTheme.values,
      currentValue: ThemeManager().currentTheme,
      getLabel: getThemeName,
      isScrollable: true,
      onSelected: (theme) {
        Future.delayed(const Duration(milliseconds: 250), () {
          ThemeManager().setTheme(theme);
        });
      },
    );
  }

  static String getListStyleName(AppListStyle style) {
    final l10n = LocalizationService();
    switch (style) {
      case AppListStyle.comfortable:
        return l10n.translate('list_style_comfortable');
      case AppListStyle.compact:
        return l10n.translate('list_style_compact');
      case AppListStyle.minimalList:
        return l10n.translate('list_style_minimal_list');
      case AppListStyle.grid:
        return l10n.translate('list_style_grid');
      case AppListStyle.coverOnlyGrid:
        return l10n.translate('list_style_cover_only_grid');
    }
  }

  static void showListStyleSelectionDialog(BuildContext context) {
    final l10n = LocalizationService();
    _showSelectionBottomSheet<AppListStyle>(
      context: context,
      title: l10n.translate('list_style'),
      subtitle: l10n.translate('list_style_subtitle'),
      options: AppListStyle.values,
      currentValue: SettingsManager().currentListStyle,
      getLabel: getListStyleName,
      onSelected: (style) => SettingsManager().setListStyle(style),
    );
  }

  static String getContentPreferencesText(List<String> prefs) {
    final l10n = LocalizationService();
    if (prefs.isEmpty) return l10n.translate('no_results');
    if (prefs.length == 4) return l10n.translate('all_ratings_hint'); // I might need a key for this
    return prefs.map((s) => l10n.translate(s)).join(', ');
  }

  static void showContentPreferencesDialog(BuildContext context) {
    final l10n = LocalizationService();
    final options = ['safe', 'suggestive', 'erotica', 'hentai'];
    final labels = {
      'safe': l10n.translate('safe'),
      'suggestive': l10n.translate('suggestive'),
      'erotica': l10n.translate('erotica'),
      'hentai': l10n.translate('hentai'),
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return ListenableBuilder(
          listenable: SettingsManager(),
          builder: (context, _) {
            final currentPrefs = SettingsManager().contentPreferences;

            return Container(
              decoration: BoxDecoration(
                color: AppConstants.secondaryBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 60),
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
                  Text(
                    l10n.translate('content_preferences'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.translate('content_preferences_subtitle'),
                    style: TextStyle(
                      color: AppConstants.textMutedColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...options.map((option) {
                    final isSelected = currentPrefs.contains(option);
                    final label = labels[option]!;

                    return GestureDetector(
                      onTap: () {
                        final newPrefs = List<String>.from(currentPrefs);
                        if (isSelected) {
                          newPrefs.remove(option);
                        } else {
                          newPrefs.add(option);
                        }
                        SettingsManager().setContentPreferences(newPrefs);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppConstants.borderColor.withValues(alpha: 0.05),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: isSelected
                                    ? AppConstants.textColor
                                    : AppConstants.textMutedColor,
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      key: const ValueKey('checked'),
                                      color: AppConstants.accentColor,
                                      size: 24,
                                    )
                                  : Icon(
                                      Icons.circle_outlined,
                                      key: const ValueKey('unchecked'),
                                      color: AppConstants.borderColor.withValues(alpha: 0.3),
                                      size: 24,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String getAppStartPageName(AppStartPage page) {
    final l10n = LocalizationService();
    switch (page) {
      case AppStartPage.home: return l10n.translate('start_page_home');
      case AppStartPage.library: return l10n.translate('start_page_library');
      case AppStartPage.browse: return l10n.translate('start_page_browse');
      case AppStartPage.news: return l10n.translate('start_page_news');
      case AppStartPage.profile: return l10n.translate('start_page_profile');
    }
  }

  static void showAppStartPageSelectionDialog(BuildContext context) {
    final l10n = LocalizationService();
    _showSelectionBottomSheet<AppStartPage>(
      context: context,
      title: l10n.translate('start_page'),
      subtitle: l10n.translate('start_page_subtitle'),
      options: AppStartPage.values,
      currentValue: SettingsManager().defaultStartPage,
      getLabel: getAppStartPageName,
      onSelected: (page) => SettingsManager().setDefaultStartPage(page),
    );
  }

  static String getRatingSliderStepName(RatingSliderStep step) {
    switch (step) {
      case RatingSliderStep.step1: return '1';
      case RatingSliderStep.step5: return '5';
      case RatingSliderStep.step10: return '10';
      case RatingSliderStep.step20: return '20';
      case RatingSliderStep.step25: return '25';
    }
  }

  static void showRatingSliderStepSelectionDialog(BuildContext context) {
    final l10n = LocalizationService();
    _showSelectionBottomSheet<RatingSliderStep>(
      context: context,
      title: l10n.translate('rating_step'),
      subtitle: l10n.translate('rating_step_subtitle'),
      options: RatingSliderStep.values,
      currentValue: SettingsManager().ratingSliderStep,
      getLabel: getRatingSliderStepName,
      onSelected: (step) => SettingsManager().setRatingSliderStep(step),
    );
  }

  static String getLibraryTabName(String tabKey) {
    return LocalizationService().translate(tabKey);
  }

  static void showAddLibraryDefaultTabSelectionDialog(BuildContext context) {
    final l10n = LocalizationService();
    _showSelectionBottomSheet<String>(
      context: context,
      title: l10n.translate('library_default'),
      subtitle: l10n.translate('library_default_subtitle'),
      options: const ['reading', 'paused', 'completed', 'plan_to_read', 'dropped', 'rereading', 'considering'],
      currentValue: SettingsManager().addLibraryDefaultTab,
      getLabel: getLibraryTabName,
      isScrollable: true,
      onSelected: (tab) => SettingsManager().setAddLibraryDefaultTab(tab),
    );
  }

  static String getTitleLanguageName(TitleLanguage lang) {
    final l10n = LocalizationService();
    switch (lang) {
      case TitleLanguage.defaultLang: return l10n.translate('title_language_default');
      case TitleLanguage.native: return l10n.translate('title_language_native');
      case TitleLanguage.romanized: return l10n.translate('title_language_romanized');
    }
  }

  static void showTitleLanguageSelectionDialog(BuildContext context) {
    final l10n = LocalizationService();
    _showSelectionBottomSheet<TitleLanguage>(
      context: context,
      title: l10n.translate('title_language'),
      subtitle: l10n.translate('title_language_subtitle'),
      options: TitleLanguage.values,
      currentValue: SettingsManager().defaultTitleLanguage,
      getLabel: getTitleLanguageName,
      onSelected: (lang) => SettingsManager().setDefaultTitleLanguage(lang),
    );
  }

  static void showLibraryListStyleSelectionDialog(BuildContext context) {
    final l10n = LocalizationService();
    _showSelectionBottomSheet<AppListStyle>(
      context: context,
      title: l10n.translate('library_list_style'),
      subtitle: l10n.translate('library_list_style_subtitle'),
      options: AppListStyle.values,
      currentValue: SettingsManager().libraryListStyle,
      getLabel: getListStyleName,
      onSelected: (style) => SettingsManager().setLibraryListStyle(style),
    );
  }

  static String getLanguageName(String code) {
    final languages = LocalizationService().getLanguages();
    final lang = languages.firstWhere((l) => l['code'] == code, orElse: () => {'name': code});
    return lang['name'] as String;
  }

  static void showLanguageSelectionDialog(BuildContext context) {
    final l10n = LocalizationService();
    final languages = LocalizationService().getLanguages();
    _showSelectionBottomSheet<String>(
      context: context,
      title: l10n.translate('language'),
      subtitle: l10n.translate('language_subtitle'), // I should add this key
      options: languages.map((l) => l['code'] as String).toList(),
      currentValue: LocalizationService().currentLanguage,
      getLabel: (code) => languages.firstWhere((l) => l['code'] == code)['name'] as String,
      onSelected: (code) {
        LocalizationService().setLanguage(code);
      },
    );
  }

  static void showBrowseListStyleSelectionDialog(BuildContext context) {
    final l10n = LocalizationService();
    _showSelectionBottomSheet<AppListStyle>(
      context: context,
      title: l10n.translate('browse_list_style'),
      subtitle: l10n.translate('browse_list_style_subtitle'),
      options: AppListStyle.values,
      currentValue: SettingsManager().browseListStyle,
      getLabel: getListStyleName,
      onSelected: (style) => SettingsManager().setBrowseListStyle(style),
    );
  }
}

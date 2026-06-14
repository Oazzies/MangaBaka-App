import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';


import 'selection_bottom_sheet.dart';

class GeneralSettingsDialogs {
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
    SelectionBottomSheet.showSelectionBottomSheet<AppStartPage>(
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
    SelectionBottomSheet.showSelectionBottomSheet<RatingSliderStep>(
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
    SelectionBottomSheet.showSelectionBottomSheet<String>(
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
    SelectionBottomSheet.showSelectionBottomSheet<TitleLanguage>(
      context: context,
      title: l10n.translate('title_language'),
      subtitle: l10n.translate('title_language_subtitle'),
      options: TitleLanguage.values,
      currentValue: SettingsManager().defaultTitleLanguage,
      getLabel: getTitleLanguageName,
      onSelected: (lang) => SettingsManager().setDefaultTitleLanguage(lang),
    );
  }
  static String getLanguageName(String code) {
    final languages = LocalizationService().getLanguages();
    final lang = languages.firstWhere((l) => l['code'] == code, orElse: () => {'native_name': code});
    return lang['native_name'] as String;
  }
  static void showLanguageSelectionDialog(BuildContext context) {
    final l10n = LocalizationService();
    final languages = l10n.getLanguages();
    SelectionBottomSheet.showSelectionBottomSheet<String>(
      context: context,
      title: l10n.translate('language'),
      subtitle: l10n.translate('language_subtitle'),
      options: languages.map((l) => l['code'] as String).toList(),
      currentValue: l10n.currentLanguage,
      getLabel: (code) => languages.firstWhere((l) => l['code'] == code)['native_name'] as String,
      onSelected: (code) {
        l10n.setLanguage(code);
      },
    );
  }

  static String getLibraryProgressTypeName(LibraryProgressType type) {
    final l10n = LocalizationService();
    switch (type) {
      case LibraryProgressType.chapters:
        return l10n.translate('library_progress_type_chapters');
      case LibraryProgressType.volumes:
        return l10n.translate('library_progress_type_volumes');
    }
  }

  static void showLibraryProgressTypeSelectionDialog(BuildContext context) {
    final l10n = LocalizationService();
    SelectionBottomSheet.showSelectionBottomSheet<LibraryProgressType>(
      context: context,
      title: l10n.translate('library_progress_type'),
      subtitle: l10n.translate('library_progress_type_subtitle'),
      options: LibraryProgressType.values,
      currentValue: SettingsManager().libraryProgressType,
      getLabel: getLibraryProgressTypeName,
      onSelected: (type) => SettingsManager().setLibraryProgressType(type),
    );
  }

  static String getLandscapeAppBarPositionName(LandscapeAppBarPosition position) {
    final l10n = LocalizationService();
    switch (position) {
      case LandscapeAppBarPosition.top:
        return l10n.translate('landscape_appbar_top');
      case LandscapeAppBarPosition.bottom:
        return l10n.translate('landscape_appbar_bottom');
      case LandscapeAppBarPosition.left:
        return l10n.translate('landscape_appbar_left');
      case LandscapeAppBarPosition.right:
        return l10n.translate('landscape_appbar_right');
    }
  }

  static void showLandscapeAppBarPositionDialog(BuildContext context) {
    final l10n = LocalizationService();
    SelectionBottomSheet.showSelectionBottomSheet<LandscapeAppBarPosition>(
      context: context,
      title: l10n.translate('landscape_appbar_position'),
      subtitle: l10n.translate('landscape_appbar_position_subtitle'),
      options: LandscapeAppBarPosition.values,
      currentValue: SettingsManager().landscapeAppBarPosition,
      getLabel: getLandscapeAppBarPositionName,
      onSelected: (position) => SettingsManager().setLandscapeAppBarPosition(position),
    );
  }
}

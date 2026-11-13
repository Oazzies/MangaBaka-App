import 'dart:io';

import 'package:mangabaka_app/core/settings/setting_value.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_keys.dart';

/// Holds every declared [SettingValue] instance for [SettingsManager].
class SettingsRegistry {
  final currentListStyle = EnumSetting(
    SettingsKeys.listStylePref,
    AppListStyle.compactGrid,
    AppListStyle.values,
  );
  final libraryListStyle = EnumSetting(
    SettingsKeys.libraryListStyle,
    AppListStyle.compactGrid,
    AppListStyle.values,
  );
  final browseListStyle = EnumSetting(
    SettingsKeys.browseListStyle,
    AppListStyle.compactGrid,
    AppListStyle.values,
  );
  final stacksListStyle = EnumSetting(
    SettingsKeys.stacksListStyle,
    AppListStyle.compactGrid,
    AppListStyle.values,
  );
  final publisherStatsStyle = EnumSetting(
    SettingsKeys.publisherStatsStyle,
    PublisherStatsStyle.charts,
    PublisherStatsStyle.values,
  );
  final worksListStyle = EnumSetting(
    SettingsKeys.worksListStyle,
    AppListStyle.comfortable,
    AppListStyle.values,
  );
  final similarListStyle = EnumSetting(
    SettingsKeys.similarListStyle,
    AppListStyle.compactGrid,
    AppListStyle.values,
  );
  final defaultStartPage = EnumSetting(
    SettingsKeys.defaultStartPage,
    AppStartPage.browse,
    AppStartPage.values,
  );
  final ratingSliderStep = EnumSetting(
    SettingsKeys.ratingSliderStep,
    RatingSliderStep.step1,
    RatingSliderStep.values,
  );
  final defaultTitleLanguage = EnumSetting(
    SettingsKeys.defaultTitleLanguage,
    TitleLanguage.defaultLang,
    TitleLanguage.values,
  );
  final libraryProgressType = EnumSetting(
    SettingsKeys.libraryProgressType,
    LibraryProgressType.chapters,
    LibraryProgressType.values,
  );
  final landscapeAppBarPosition = EnumSetting(
    SettingsKeys.landscapeAppBarPosition,
    LandscapeAppBarPosition.left,
    LandscapeAppBarPosition.values,
  );

  final themeMode = EnumSetting(
    SettingsKeys.themeMode,
    AppThemeMode.dark,
    AppThemeMode.values,
  );
  final darkThemeId = StringSetting(SettingsKeys.darkThemeId, 'default');
  final lightThemeId = StringSetting(SettingsKeys.lightThemeId, 'default');
  final accentOverride = IntSetting(SettingsKeys.accentOverride, 0);
  final customThemes = StringListSetting(SettingsKeys.customThemes, const []);

  final separateListStyles = BoolSetting(
    SettingsKeys.separateListStyles,
    false,
  );
  final separateGridColumnCounts = BoolSetting(
    SettingsKeys.separateGridColumnCounts,
    false,
  );
  final hideLibrarySeriesInBrowse = BoolSetting(
    SettingsKeys.hideLibrarySeriesInBrowse,
    false,
  );
  final hasCompletedOnboarding = BoolSetting(
    SettingsKeys.onboardingCompleted,
    false,
  );
  final pushNotifications = BoolSetting(SettingsKeys.pushNotifications, false);
  final autoSuggestBrowse = BoolSetting(SettingsKeys.autoSuggestBrowse, true);
  final developerMode = BoolSetting(SettingsKeys.developerMode, false);
  final autoFocusBrowseSearch = BoolSetting(
    SettingsKeys.autoFocusBrowseSearch,
    false,
  );
  final autoSuggestLibrary = BoolSetting(
    SettingsKeys.autoSuggestLibrary,
    false,
  );
  final showTooltips = BoolSetting(SettingsKeys.showTooltips, true);
  final showQuickProgress = BoolSetting(SettingsKeys.showQuickProgress, true);
  final showLibraryProgress = BoolSetting(
    SettingsKeys.showLibraryProgress,
    true,
  );
  final showRemainingProgress = BoolSetting(
    SettingsKeys.showRemainingProgress,
    false,
  );
  final showLibraryTabCounts = BoolSetting(
    SettingsKeys.showLibraryTabCounts,
    true,
  );
  final autoCompleteChapterProgress = EnumSetting(
    SettingsKeys.autoCompleteChapterProgress,
    AutoCompleteProgressMode.prompt,
    AutoCompleteProgressMode.values,
  );
  final autoCompleteSeriesStatus = EnumSetting(
    SettingsKeys.autoCompleteSeriesStatus,
    AutoCompleteProgressMode.prompt,
    AutoCompleteProgressMode.values,
  );
  final progressOverflow = EnumSetting(
    SettingsKeys.progressOverflow,
    ProgressOverflowMode.promptCompletedOnly,
    ProgressOverflowMode.values,
  );
  final openLinksInApp = BoolSetting(
    SettingsKeys.openLinksInApp,
    Platform.isAndroid,
  );

  final gridColumnCount = IntSetting(SettingsKeys.gridColumnCount, 0);
  final libraryGridColumnCount = IntSetting(
    SettingsKeys.libraryGridColumnCount,
    0,
  );
  final browseGridColumnCount = IntSetting(
    SettingsKeys.browseGridColumnCount,
    0,
  );
  final stacksGridColumnCount = IntSetting(
    SettingsKeys.stacksGridColumnCount,
    0,
  );
  final collectionsListColumns = IntSetting(
    SettingsKeys.collectionsGridColumns,
    0,
  );
  final newsListColumns = IntSetting(SettingsKeys.newsListColumns, 1);
  final compactGridTitleRows = IntSetting(
    SettingsKeys.compactGridTitleRows,
    1,
    min: 1,
    max: 99,
  );

  final addLibraryDefaultTab = StringSetting(
    SettingsKeys.addLibraryDefaultTab,
    'plan_to_read',
  );
  final dismissedRecommendations = StringListSetting(
    SettingsKeys.dismissedRecommendations,
    const [],
  );
  final contentPreferences = StringListSetting(
    SettingsKeys.contentPreferences,
    const ['safe', 'suggestive'],
  );
  final blurredContentRatings = StringListSetting(
    SettingsKeys.blurredContentRatings,
    const [],
  );

  late final List<SettingValue<Object?>> all = [
    currentListStyle,
    libraryListStyle,
    browseListStyle,
    stacksListStyle,
    worksListStyle,
    publisherStatsStyle,
    similarListStyle,
    defaultStartPage,
    ratingSliderStep,
    defaultTitleLanguage,
    libraryProgressType,
    landscapeAppBarPosition,
    themeMode,
    darkThemeId,
    lightThemeId,
    accentOverride,
    customThemes,
    separateListStyles,
    separateGridColumnCounts,
    hideLibrarySeriesInBrowse,
    hasCompletedOnboarding,
    pushNotifications,
    autoSuggestBrowse,
    developerMode,
    autoFocusBrowseSearch,
    autoSuggestLibrary,
    showTooltips,
    showQuickProgress,
    showLibraryProgress,
    showRemainingProgress,
    showLibraryTabCounts,
    gridColumnCount,
    libraryGridColumnCount,
    browseGridColumnCount,
    stacksGridColumnCount,
    collectionsListColumns,
    newsListColumns,
    compactGridTitleRows,
    addLibraryDefaultTab,
    contentPreferences,
    blurredContentRatings,
    dismissedRecommendations,
    openLinksInApp,
    autoCompleteChapterProgress,
    autoCompleteSeriesStatus,
    progressOverflow,
  ];
}

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/setting_value.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_keys.dart';
import 'package:mangabaka_app/core/settings/settings_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Process-wide user preferences store and [ChangeNotifier].
class SettingsManager extends ChangeNotifier {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();

  final SettingsRegistry _s = SettingsRegistry();
  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> init() async {
    final prefs = await _getPrefs();
    for (final setting in _s.all) {
      setting.load(prefs);
    }
    if (!prefs.containsKey(SettingsKeys.stacksListStyle)) {
      _s.stacksListStyle.set(_s.browseListStyle.value);
    }
    if (!prefs.containsKey(SettingsKeys.stacksGridColumnCount)) {
      _s.stacksGridColumnCount.set(_s.browseGridColumnCount.value);
    }
    final legacyAutoComplete = prefs.get(
      SettingsKeys.autoCompleteChapterProgress,
    );
    if (legacyAutoComplete is bool) {
      _s.autoCompleteChapterProgress.set(
        legacyAutoComplete
            ? AutoCompleteProgressMode.always
            : AutoCompleteProgressMode.never,
      );
      await _s.autoCompleteChapterProgress.persist(prefs);
    }
    notifyListeners();
  }

  @visibleForTesting
  static void resetForTesting() {
    _instance._prefs = null;
    for (final setting in _instance._s.all) {
      setting.reset();
    }
  }

  Future<void> _apply<T>(SettingValue<T> setting, T value) async {
    if (!setting.set(value)) return;
    notifyListeners();
    try {
      final prefs = await _getPrefs();
      await setting.persist(prefs);
    } on Exception catch (e, st) {
      LoggingService.logger.warning('Failed to persist setting', e, st);
    }
  }

  // ─── List styles ─────────────────────────────────────────────────────────

  AppListStyle get currentListStyle => _s.currentListStyle.value;
  Future<void> setListStyle(AppListStyle style) =>
      _apply(_s.currentListStyle, style);

  AppListStyle get libraryListStyle => _s.libraryListStyle.value;
  Future<void> setLibraryListStyle(AppListStyle style) =>
      _apply(_s.libraryListStyle, style);

  AppListStyle get browseListStyle => _s.browseListStyle.value;
  Future<void> setBrowseListStyle(AppListStyle style) =>
      _apply(_s.browseListStyle, style);

  AppListStyle get stacksListStyle => _s.stacksListStyle.value;
  Future<void> setStacksListStyle(AppListStyle style) =>
      _apply(_s.stacksListStyle, style);

  PublisherStatsStyle get publisherStatsStyle => _s.publisherStatsStyle.value;
  Future<void> setPublisherStatsStyle(PublisherStatsStyle style) =>
      _apply(_s.publisherStatsStyle, style);

  AppListStyle get worksListStyle => _s.worksListStyle.value;
  Future<void> setWorksListStyle(AppListStyle style) =>
      _apply(_s.worksListStyle, style);

  AppListStyle get similarListStyle => _s.similarListStyle.value;
  Future<void> setSimilarListStyle(AppListStyle style) =>
      _apply(_s.similarListStyle, style);

  bool get separateListStyles => _s.separateListStyles.value;
  Future<void> setSeparateListStyles(bool value) =>
      _apply(_s.separateListStyles, value);

  AppListStyle get resolvedLibraryListStyle =>
      separateListStyles ? libraryListStyle : currentListStyle;

  AppListStyle get resolvedBrowseListStyle =>
      separateListStyles ? browseListStyle : currentListStyle;

  AppListStyle get resolvedStacksListStyle =>
      separateListStyles ? stacksListStyle : currentListStyle;

  // ─── Grid columns ────────────────────────────────────────────────────────

  bool get separateGridColumnCounts => _s.separateGridColumnCounts.value;
  Future<void> setSeparateGridColumnCounts(bool value) =>
      _apply(_s.separateGridColumnCounts, value);

  int get gridColumnCount => _s.gridColumnCount.value;
  Future<void> setGridColumnCount(int value) =>
      _apply(_s.gridColumnCount, value);

  int get libraryGridColumnCount => _s.libraryGridColumnCount.value;
  Future<void> setLibraryGridColumnCount(int value) =>
      _apply(_s.libraryGridColumnCount, value);

  int get browseGridColumnCount => _s.browseGridColumnCount.value;
  Future<void> setBrowseGridColumnCount(int value) =>
      _apply(_s.browseGridColumnCount, value);

  int get stacksGridColumnCount => _s.stacksGridColumnCount.value;
  Future<void> setStacksGridColumnCount(int value) =>
      _apply(_s.stacksGridColumnCount, value);

  int get resolvedStacksGridColumnCount =>
      separateGridColumnCounts ? stacksGridColumnCount : gridColumnCount;

  int get resolvedLibraryGridColumnCount =>
      separateGridColumnCounts ? libraryGridColumnCount : gridColumnCount;

  int get resolvedBrowseGridColumnCount =>
      separateGridColumnCounts ? browseGridColumnCount : gridColumnCount;

  int get collectionsListColumns => _s.collectionsListColumns.value;
  Future<void> setCollectionsListColumns(int value) =>
      _apply(_s.collectionsListColumns, value);

  int get newsListColumns => _s.newsListColumns.value;
  Future<void> setNewsListColumns(int columns) =>
      _apply(_s.newsListColumns, columns);

  int get compactGridTitleRows => _s.compactGridTitleRows.value;
  Future<void> setCompactGridTitleRows(int value) =>
      _apply(_s.compactGridTitleRows, value);

  // ─── Content ─────────────────────────────────────────────────────────────

  List<String> get contentPreferences => _s.contentPreferences.value;
  Future<void> setContentPreferences(List<String> prefsList) =>
      _apply(_s.contentPreferences, prefsList);

  List<String> get blurredContentRatings => _s.blurredContentRatings.value;
  Future<void> setBlurredContentRatings(List<String> ratings) =>
      _apply(_s.blurredContentRatings, ratings);

  bool get hideLibrarySeriesInBrowse => _s.hideLibrarySeriesInBrowse.value;
  Future<void> setHideLibrarySeriesInBrowse(bool value) =>
      _apply(_s.hideLibrarySeriesInBrowse, value);

  // ─── Progress ────────────────────────────────────────────────────────────

  bool get showQuickProgress => _s.showQuickProgress.value;
  Future<void> setShowQuickProgress(bool value) =>
      _apply(_s.showQuickProgress, value);

  bool get showLibraryProgress => _s.showLibraryProgress.value;
  Future<void> setShowLibraryProgress(bool value) =>
      _apply(_s.showLibraryProgress, value);

  LibraryProgressType get libraryProgressType => _s.libraryProgressType.value;
  Future<void> setLibraryProgressType(LibraryProgressType type) =>
      _apply(_s.libraryProgressType, type);

  bool get showRemainingProgress => _s.showRemainingProgress.value;
  Future<void> setShowRemainingProgress(bool value) =>
      _apply(_s.showRemainingProgress, value);

  bool get showLibraryTabCounts => _s.showLibraryTabCounts.value;
  Future<void> setShowLibraryTabCounts(bool value) =>
      _apply(_s.showLibraryTabCounts, value);

  RatingSliderStep get ratingSliderStep => _s.ratingSliderStep.value;
  Future<void> setRatingSliderStep(RatingSliderStep step) =>
      _apply(_s.ratingSliderStep, step);

  String get addLibraryDefaultTab => _s.addLibraryDefaultTab.value;
  Future<void> setAddLibraryDefaultTab(String tabKey) =>
      _apply(_s.addLibraryDefaultTab, tabKey);

  AutoCompleteProgressMode get autoCompleteChapterProgress =>
      _s.autoCompleteChapterProgress.value;
  Future<void> setAutoCompleteChapterProgress(AutoCompleteProgressMode mode) =>
      _apply(_s.autoCompleteChapterProgress, mode);

  AutoCompleteProgressMode get autoCompleteSeriesStatus =>
      _s.autoCompleteSeriesStatus.value;
  Future<void> setAutoCompleteSeriesStatus(AutoCompleteProgressMode mode) =>
      _apply(_s.autoCompleteSeriesStatus, mode);

  ProgressOverflowMode get progressOverflow => _s.progressOverflow.value;
  Future<void> setProgressOverflow(ProgressOverflowMode mode) =>
      _apply(_s.progressOverflow, mode);

  // ─── Recommendations ─────────────────────────────────────────────────────

  List<String> get dismissedRecommendations =>
      _s.dismissedRecommendations.value;

  Future<void> dismissRecommendation(String seriesId) {
    final current = _s.dismissedRecommendations.value;
    if (current.contains(seriesId)) return Future.value();
    return _apply(_s.dismissedRecommendations, [...current, seriesId]);
  }

  Future<void> restoreRecommendations() =>
      _apply(_s.dismissedRecommendations, const []);

  // ─── App ─────────────────────────────────────────────────────────────────

  bool get hasCompletedOnboarding => _s.hasCompletedOnboarding.value;
  Future<void> setHasCompletedOnboarding(bool value) =>
      _apply(_s.hasCompletedOnboarding, value);

  AppStartPage get defaultStartPage => _s.defaultStartPage.value;
  Future<void> setDefaultStartPage(AppStartPage page) =>
      _apply(_s.defaultStartPage, page);

  TitleLanguage get defaultTitleLanguage => _s.defaultTitleLanguage.value;
  Future<void> setDefaultTitleLanguage(TitleLanguage lang) =>
      _apply(_s.defaultTitleLanguage, lang);

  LandscapeAppBarPosition get landscapeAppBarPosition =>
      _s.landscapeAppBarPosition.value;
  Future<void> setLandscapeAppBarPosition(LandscapeAppBarPosition position) =>
      _apply(_s.landscapeAppBarPosition, position);

  bool get pushNotifications => _s.pushNotifications.value;
  Future<void> setPushNotifications(bool value) =>
      _apply(_s.pushNotifications, value);

  bool get openLinksInApp => _s.openLinksInApp.value;
  Future<void> setOpenLinksInApp(bool value) =>
      _apply(_s.openLinksInApp, value);

  bool get developerMode => _s.developerMode.value;
  Future<void> setDeveloperMode(bool value) =>
      _apply(_s.developerMode, value);

  bool get autoSuggestBrowse => _s.autoSuggestBrowse.value;
  Future<void> setAutoSuggestBrowse(bool value) =>
      _apply(_s.autoSuggestBrowse, value);

  bool get autoFocusBrowseSearch => _s.autoFocusBrowseSearch.value;
  Future<void> setAutoFocusBrowseSearch(bool value) =>
      _apply(_s.autoFocusBrowseSearch, value);

  bool get autoSuggestLibrary => _s.autoSuggestLibrary.value;
  Future<void> setAutoSuggestLibrary(bool value) =>
      _apply(_s.autoSuggestLibrary, value);

  bool get showTooltips => _s.showTooltips.value;
  Future<void> setShowTooltips(bool value) => _apply(_s.showTooltips, value);

  // ─── Appearance ──────────────────────────────────────────────────────────

  AppThemeMode get themeMode => _s.themeMode.value;
  Future<void> setThemeMode(AppThemeMode mode) => _apply(_s.themeMode, mode);

  String get darkThemeId => _s.darkThemeId.value;
  Future<void> setDarkThemeId(String id) => _apply(_s.darkThemeId, id);

  String get lightThemeId => _s.lightThemeId.value;
  Future<void> setLightThemeId(String id) => _apply(_s.lightThemeId, id);

  int get accentOverride => _s.accentOverride.value;
  Future<void> setAccentOverride(int argb) => _apply(_s.accentOverride, argb);

  List<String> get customThemes => _s.customThemes.value;
  Future<void> setCustomThemes(List<String> encoded) =>
      _apply(_s.customThemes, encoded);
}

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/settings/setting_value.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every user preference, and the only place they are persisted.
///
/// A process-wide singleton and a [ChangeNotifier]: widgets listen to it
/// directly rather than threading settings through constructors.
///
/// Each setting is declared once as a [SettingValue] — key, default and
/// storage type together — from which loading, saving and the test reset are
/// all derived. The public surface is unchanged: a getter and a
/// `set…` per preference.
class SettingsManager extends ChangeNotifier {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();

  SharedPreferences? _prefs;
  Future<SharedPreferences> _getPrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ─── Declarations ────────────────────────────────────────────────────────

  final _currentListStyle = EnumSetting(
    SettingsKeys.listStylePref,
    AppListStyle.compactGrid,
    AppListStyle.values,
  );
  final _libraryListStyle = EnumSetting(
    SettingsKeys.libraryListStyle,
    AppListStyle.compactGrid,
    AppListStyle.values,
  );
  final _browseListStyle = EnumSetting(
    SettingsKeys.browseListStyle,
    AppListStyle.compactGrid,
    AppListStyle.values,
  );
  final _worksListStyle = EnumSetting(
    SettingsKeys.worksListStyle,
    AppListStyle.comfortable,
    AppListStyle.values,
  );
  final _similarListStyle = EnumSetting(
    SettingsKeys.similarListStyle,
    AppListStyle.compactGrid,
    AppListStyle.values,
  );
  final _defaultStartPage = EnumSetting(
    SettingsKeys.defaultStartPage,
    AppStartPage.browse,
    AppStartPage.values,
  );
  final _ratingSliderStep = EnumSetting(
    SettingsKeys.ratingSliderStep,
    RatingSliderStep.step1,
    RatingSliderStep.values,
  );
  final _defaultTitleLanguage = EnumSetting(
    SettingsKeys.defaultTitleLanguage,
    TitleLanguage.defaultLang,
    TitleLanguage.values,
  );
  final _libraryProgressType = EnumSetting(
    SettingsKeys.libraryProgressType,
    LibraryProgressType.chapters,
    LibraryProgressType.values,
  );
  final _landscapeAppBarPosition = EnumSetting(
    SettingsKeys.landscapeAppBarPosition,
    LandscapeAppBarPosition.left,
    LandscapeAppBarPosition.values,
  );

  // Existing users were on the single dark theme, so dark stays the default
  // rather than "system" — nobody's app changes colour on update.
  final _themeMode = EnumSetting(
    SettingsKeys.themeMode,
    AppThemeMode.dark,
    AppThemeMode.values,
  );
  final _darkThemeId = StringSetting(SettingsKeys.darkThemeId, 'default');
  final _lightThemeId = StringSetting(SettingsKeys.lightThemeId, 'default');

  /// ARGB of the accent override; 0 means "use the theme's own accent".
  final _accentOverride = IntSetting(SettingsKeys.accentOverride, 0);

  /// JSON-encoded `MbThemeSpec`s.
  final _customThemes = StringListSetting(SettingsKeys.customThemes, const []);

  final _separateListStyles = BoolSetting(SettingsKeys.separateListStyles, false);
  final _separateGridColumnCounts =
      BoolSetting(SettingsKeys.separateGridColumnCounts, false);
  final _hideLibrarySeriesInBrowse =
      BoolSetting(SettingsKeys.hideLibrarySeriesInBrowse, false);
  final _hasCompletedOnboarding =
      BoolSetting(SettingsKeys.onboardingCompleted, false);
  final _pushNotifications = BoolSetting(SettingsKeys.pushNotifications, false);
  final _autoSuggestBrowse = BoolSetting(SettingsKeys.autoSuggestBrowse, true);
  final _autoSuggestLibrary = BoolSetting(SettingsKeys.autoSuggestLibrary, false);
  final _showTooltips = BoolSetting(SettingsKeys.showTooltips, true);
  final _showQuickProgress = BoolSetting(SettingsKeys.showQuickProgress, true);
  final _showLibraryProgress =
      BoolSetting(SettingsKeys.showLibraryProgress, true);
  final _showRemainingProgress =
      BoolSetting(SettingsKeys.showRemainingProgress, false);
  final _showLibraryTabCounts =
      BoolSetting(SettingsKeys.showLibraryTabCounts, true);

  /// 0 means "auto": fit as many columns as the available width allows.
  final _gridColumnCount = IntSetting(SettingsKeys.gridColumnCount, 0);
  final _libraryGridColumnCount =
      IntSetting(SettingsKeys.libraryGridColumnCount, 0);
  final _browseGridColumnCount =
      IntSetting(SettingsKeys.browseGridColumnCount, 0);
  final _collectionsListColumns =
      IntSetting(SettingsKeys.collectionsGridColumns, 0);
  final _newsListColumns = IntSetting(SettingsKeys.newsListColumns, 1);
  final _compactGridTitleRows =
      IntSetting(SettingsKeys.compactGridTitleRows, 1, min: 1, max: 99);

  final _addLibraryDefaultTab =
      StringSetting(SettingsKeys.addLibraryDefaultTab, 'plan_to_read');

  /// Series the user marked "not interested" in the Discovery Queue; filtered
  /// out of future recommendation fetches.
  final _dismissedRecommendations = StringListSetting(
    SettingsKeys.dismissedRecommendations,
    const [],
  );

  final _contentPreferences = StringListSetting(
    SettingsKeys.contentPreferences,
    const ['safe', 'suggestive'],
  );
  final _blurredContentRatings =
      StringListSetting(SettingsKeys.blurredContentRatings, const []);

  /// Every declared setting, in no particular order — the list `init` and
  /// `resetForTesting` walk. Adding a setting above and here is all it takes.
  late final List<SettingValue<Object?>> _all = [
    _currentListStyle,
    _libraryListStyle,
    _browseListStyle,
    _worksListStyle,
    _similarListStyle,
    _defaultStartPage,
    _ratingSliderStep,
    _defaultTitleLanguage,
    _libraryProgressType,
    _landscapeAppBarPosition,
    _themeMode,
    _darkThemeId,
    _lightThemeId,
    _accentOverride,
    _customThemes,
    _separateListStyles,
    _separateGridColumnCounts,
    _hideLibrarySeriesInBrowse,
    _hasCompletedOnboarding,
    _pushNotifications,
    _autoSuggestBrowse,
    _autoSuggestLibrary,
    _showTooltips,
    _showQuickProgress,
    _showLibraryProgress,
    _showRemainingProgress,
    _showLibraryTabCounts,
    _gridColumnCount,
    _libraryGridColumnCount,
    _browseGridColumnCount,
    _collectionsListColumns,
    _newsListColumns,
    _compactGridTitleRows,
    _addLibraryDefaultTab,
    _contentPreferences,
    _blurredContentRatings,
    _dismissedRecommendations,
  ];

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await _getPrefs();
    for (final setting in _all) {
      setting.load(prefs);
    }
    notifyListeners();
  }

  @visibleForTesting
  static void resetForTesting() {
    _instance._prefs = null;
    for (final setting in _instance._all) {
      setting.reset();
    }
  }

  /// Applies [value], notifies the UI immediately, and persists in the background.
  Future<void> _apply<T>(SettingValue<T> setting, T value) async {
    if (!setting.set(value)) return;
    notifyListeners();
    try {
      final prefs = await _getPrefs();
      await setting.persist(prefs);
    } catch (_) {
      // In-memory update succeeded; ignore disk persistence errors in background
    }
  }

  // ─── List styles ─────────────────────────────────────────────────────────

  AppListStyle get currentListStyle => _currentListStyle.value;
  Future<void> setListStyle(AppListStyle style) =>
      _apply(_currentListStyle, style);

  AppListStyle get libraryListStyle => _libraryListStyle.value;
  Future<void> setLibraryListStyle(AppListStyle style) =>
      _apply(_libraryListStyle, style);

  AppListStyle get browseListStyle => _browseListStyle.value;
  Future<void> setBrowseListStyle(AppListStyle style) =>
      _apply(_browseListStyle, style);

  AppListStyle get worksListStyle => _worksListStyle.value;
  Future<void> setWorksListStyle(AppListStyle style) =>
      _apply(_worksListStyle, style);

  AppListStyle get similarListStyle => _similarListStyle.value;
  Future<void> setSimilarListStyle(AppListStyle style) =>
      _apply(_similarListStyle, style);

  bool get separateListStyles => _separateListStyles.value;
  Future<void> setSeparateListStyles(bool value) =>
      _apply(_separateListStyles, value);

  /// The style the Library list actually uses, resolving the shared-versus-
  /// separate switch so callers do not each re-derive it.
  AppListStyle get resolvedLibraryListStyle =>
      separateListStyles ? libraryListStyle : currentListStyle;

  /// The style the Browse list actually uses.
  AppListStyle get resolvedBrowseListStyle =>
      separateListStyles ? browseListStyle : currentListStyle;

  // ─── Grid columns ────────────────────────────────────────────────────────

  bool get separateGridColumnCounts => _separateGridColumnCounts.value;
  Future<void> setSeparateGridColumnCounts(bool value) =>
      _apply(_separateGridColumnCounts, value);

  int get gridColumnCount => _gridColumnCount.value;
  Future<void> setGridColumnCount(int value) => _apply(_gridColumnCount, value);

  int get libraryGridColumnCount => _libraryGridColumnCount.value;
  Future<void> setLibraryGridColumnCount(int value) =>
      _apply(_libraryGridColumnCount, value);

  int get browseGridColumnCount => _browseGridColumnCount.value;
  Future<void> setBrowseGridColumnCount(int value) =>
      _apply(_browseGridColumnCount, value);

  /// The column count the Library grid actually uses.
  int get resolvedLibraryGridColumnCount =>
      separateGridColumnCounts ? libraryGridColumnCount : gridColumnCount;

  /// The column count the Browse grid actually uses.
  int get resolvedBrowseGridColumnCount =>
      separateGridColumnCounts ? browseGridColumnCount : gridColumnCount;

  int get collectionsListColumns => _collectionsListColumns.value;
  Future<void> setCollectionsListColumns(int value) =>
      _apply(_collectionsListColumns, value);

  int get newsListColumns => _newsListColumns.value;
  Future<void> setNewsListColumns(int columns) =>
      _apply(_newsListColumns, columns);

  int get compactGridTitleRows => _compactGridTitleRows.value;
  Future<void> setCompactGridTitleRows(int value) =>
      _apply(_compactGridTitleRows, value);

  // ─── Content ─────────────────────────────────────────────────────────────

  List<String> get contentPreferences => _contentPreferences.value;
  Future<void> setContentPreferences(List<String> prefsList) =>
      _apply(_contentPreferences, prefsList);

  List<String> get blurredContentRatings => _blurredContentRatings.value;
  Future<void> setBlurredContentRatings(List<String> ratings) =>
      _apply(_blurredContentRatings, ratings);

  bool get hideLibrarySeriesInBrowse => _hideLibrarySeriesInBrowse.value;
  Future<void> setHideLibrarySeriesInBrowse(bool value) =>
      _apply(_hideLibrarySeriesInBrowse, value);

  // ─── Progress ────────────────────────────────────────────────────────────

  bool get showQuickProgress => _showQuickProgress.value;
  Future<void> setShowQuickProgress(bool value) =>
      _apply(_showQuickProgress, value);

  bool get showLibraryProgress => _showLibraryProgress.value;
  Future<void> setShowLibraryProgress(bool value) =>
      _apply(_showLibraryProgress, value);

  LibraryProgressType get libraryProgressType => _libraryProgressType.value;
  Future<void> setLibraryProgressType(LibraryProgressType type) =>
      _apply(_libraryProgressType, type);

  bool get showRemainingProgress => _showRemainingProgress.value;
  Future<void> setShowRemainingProgress(bool value) =>
      _apply(_showRemainingProgress, value);

  bool get showLibraryTabCounts => _showLibraryTabCounts.value;
  Future<void> setShowLibraryTabCounts(bool value) =>
      _apply(_showLibraryTabCounts, value);

  RatingSliderStep get ratingSliderStep => _ratingSliderStep.value;
  Future<void> setRatingSliderStep(RatingSliderStep step) =>
      _apply(_ratingSliderStep, step);

  String get addLibraryDefaultTab => _addLibraryDefaultTab.value;
  Future<void> setAddLibraryDefaultTab(String tabKey) =>
      _apply(_addLibraryDefaultTab, tabKey);

  // ─── Recommendations ─────────────────────────────────────────────────────

  List<String> get dismissedRecommendations =>
      _dismissedRecommendations.value;

  Future<void> dismissRecommendation(String seriesId) {
    final current = _dismissedRecommendations.value;
    if (current.contains(seriesId)) return Future.value();
    return _apply(_dismissedRecommendations, [...current, seriesId]);
  }

  Future<void> restoreRecommendations() =>
      _apply(_dismissedRecommendations, const []);

  // ─── App ─────────────────────────────────────────────────────────────────

  bool get hasCompletedOnboarding => _hasCompletedOnboarding.value;
  Future<void> setHasCompletedOnboarding(bool value) =>
      _apply(_hasCompletedOnboarding, value);

  AppStartPage get defaultStartPage => _defaultStartPage.value;
  Future<void> setDefaultStartPage(AppStartPage page) =>
      _apply(_defaultStartPage, page);

  TitleLanguage get defaultTitleLanguage => _defaultTitleLanguage.value;
  Future<void> setDefaultTitleLanguage(TitleLanguage lang) =>
      _apply(_defaultTitleLanguage, lang);

  LandscapeAppBarPosition get landscapeAppBarPosition =>
      _landscapeAppBarPosition.value;
  Future<void> setLandscapeAppBarPosition(LandscapeAppBarPosition position) =>
      _apply(_landscapeAppBarPosition, position);

  bool get pushNotifications => _pushNotifications.value;
  Future<void> setPushNotifications(bool value) =>
      _apply(_pushNotifications, value);

  bool get autoSuggestBrowse => _autoSuggestBrowse.value;
  Future<void> setAutoSuggestBrowse(bool value) =>
      _apply(_autoSuggestBrowse, value);

  bool get autoSuggestLibrary => _autoSuggestLibrary.value;
  Future<void> setAutoSuggestLibrary(bool value) =>
      _apply(_autoSuggestLibrary, value);

  bool get showTooltips => _showTooltips.value;
  Future<void> setShowTooltips(bool value) => _apply(_showTooltips, value);

  // ─── Appearance ──────────────────────────────────────────────────────────
  // Raw storage only; `ThemeController` resolves these into palettes.

  AppThemeMode get themeMode => _themeMode.value;
  Future<void> setThemeMode(AppThemeMode mode) => _apply(_themeMode, mode);

  String get darkThemeId => _darkThemeId.value;
  Future<void> setDarkThemeId(String id) => _apply(_darkThemeId, id);

  String get lightThemeId => _lightThemeId.value;
  Future<void> setLightThemeId(String id) => _apply(_lightThemeId, id);

  int get accentOverride => _accentOverride.value;
  Future<void> setAccentOverride(int argb) => _apply(_accentOverride, argb);

  List<String> get customThemes => _customThemes.value;
  Future<void> setCustomThemes(List<String> encoded) =>
      _apply(_customThemes, encoded);
}

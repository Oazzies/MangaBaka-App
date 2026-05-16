import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/utils/settings/settings_enums.dart';
import 'package:mangabaka_app/utils/settings/settings_keys.dart';

class SettingsManager extends ChangeNotifier {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();
  
  @visibleForTesting
  static void resetForTesting() {
    _instance._currentListStyle = AppListStyle.compactGrid;
    _instance._hideLibrarySeriesInBrowse = false;
    _instance._contentPreferences = ['safe', 'suggestive'];
    _instance._hasCompletedOnboarding = false;
    _instance._defaultStartPage = AppStartPage.browse;
    _instance._ratingSliderStep = RatingSliderStep.step1;
    _instance._addLibraryDefaultTab = 'plan_to_read';
    _instance._defaultTitleLanguage = TitleLanguage.defaultLang;
    _instance._separateListStyles = false;
    _instance._libraryListStyle = AppListStyle.compactGrid;
    _instance._browseListStyle = AppListStyle.compactGrid;
    _instance._pushNotifications = false;
    _instance._autoSuggestBrowse = false;
    _instance._newsListColumns = 1;
    _instance._showTooltips = true;
    _instance._blurredContentRatings = [];
    _instance._separateGridColumnCounts = false;
    _instance._gridColumnCount = 0;
    _instance._libraryGridColumnCount = 0;
    _instance._browseGridColumnCount = 0;
  }

  AppListStyle _currentListStyle = AppListStyle.compactGrid;
  AppListStyle get currentListStyle => _currentListStyle;

  bool _hideLibrarySeriesInBrowse = false;
  bool get hideLibrarySeriesInBrowse => _hideLibrarySeriesInBrowse;

  List<String> _contentPreferences = ['safe', 'suggestive'];
  List<String> get contentPreferences => _contentPreferences;

  bool _hasCompletedOnboarding = false;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  AppStartPage _defaultStartPage = AppStartPage.browse;
  AppStartPage get defaultStartPage => _defaultStartPage;

  RatingSliderStep _ratingSliderStep = RatingSliderStep.step1;
  RatingSliderStep get ratingSliderStep => _ratingSliderStep;

  String _addLibraryDefaultTab = 'plan_to_read';
  String get addLibraryDefaultTab => _addLibraryDefaultTab;

  TitleLanguage _defaultTitleLanguage = TitleLanguage.defaultLang;
  TitleLanguage get defaultTitleLanguage => _defaultTitleLanguage;

  bool _separateListStyles = false;
  bool get separateListStyles => _separateListStyles;

  AppListStyle _libraryListStyle = AppListStyle.compactGrid;
  AppListStyle get libraryListStyle => _libraryListStyle;

  AppListStyle _browseListStyle = AppListStyle.compactGrid;
  AppListStyle get browseListStyle => _browseListStyle;

  bool _pushNotifications = false;
  bool get pushNotifications => _pushNotifications;

  bool _autoSuggestBrowse = false;
  bool get autoSuggestBrowse => _autoSuggestBrowse;

  int _newsListColumns = 1;
  int get newsListColumns => _newsListColumns;



  bool _showTooltips = true;
  bool get showTooltips => _showTooltips;

  List<String> _blurredContentRatings = [];
  List<String> get blurredContentRatings => _blurredContentRatings;

  bool _separateGridColumnCounts = false;
  bool get separateGridColumnCounts => _separateGridColumnCounts;

  int _gridColumnCount = 0;
  int get gridColumnCount => _gridColumnCount;

  int _libraryGridColumnCount = 0;
  int get libraryGridColumnCount => _libraryGridColumnCount;

  int _browseGridColumnCount = 0;
  int get browseGridColumnCount => _browseGridColumnCount;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load preferences

    final listStyleIndex = prefs.getInt(SettingsKeys.listStylePref);
    if (listStyleIndex != null && listStyleIndex >= 0 && listStyleIndex < AppListStyle.values.length) {
      _currentListStyle = AppListStyle.values[listStyleIndex];
    }
    
    _hideLibrarySeriesInBrowse = prefs.getBool(SettingsKeys.hideLibrarySeriesInBrowse) ?? false;
    
    final savedContentPrefs = prefs.getStringList(SettingsKeys.contentPreferences);
    if (savedContentPrefs != null && savedContentPrefs.isNotEmpty) {
      _contentPreferences = savedContentPrefs;
    }

    _hasCompletedOnboarding = prefs.getBool(SettingsKeys.onboardingCompleted) ?? false;
    
    final startPageIndex = prefs.getInt(SettingsKeys.defaultStartPage);
    if (startPageIndex != null && startPageIndex >= 0 && startPageIndex < AppStartPage.values.length) {
      _defaultStartPage = AppStartPage.values[startPageIndex];
    }

    final ratingStepIndex = prefs.getInt(SettingsKeys.ratingSliderStep);
    if (ratingStepIndex != null && ratingStepIndex >= 0 && ratingStepIndex < RatingSliderStep.values.length) {
      _ratingSliderStep = RatingSliderStep.values[ratingStepIndex];
    }

    _addLibraryDefaultTab = prefs.getString(SettingsKeys.addLibraryDefaultTab) ?? 'plan_to_read';

    final titleLangIndex = prefs.getInt(SettingsKeys.defaultTitleLanguage);
    if (titleLangIndex != null && titleLangIndex >= 0 && titleLangIndex < TitleLanguage.values.length) {
      _defaultTitleLanguage = TitleLanguage.values[titleLangIndex];
    }

    _separateListStyles = prefs.getBool(SettingsKeys.separateListStyles) ?? false;

    final libStyleIndex = prefs.getInt(SettingsKeys.libraryListStyle);
    if (libStyleIndex != null && libStyleIndex >= 0 && libStyleIndex < AppListStyle.values.length) {
      _libraryListStyle = AppListStyle.values[libStyleIndex];
    }

    final browseStyleIndex = prefs.getInt(SettingsKeys.browseListStyle);
    if (browseStyleIndex != null && browseStyleIndex >= 0 && browseStyleIndex < AppListStyle.values.length) {
      _browseListStyle = AppListStyle.values[browseStyleIndex];
    }

    _pushNotifications = prefs.getBool(SettingsKeys.pushNotifications) ?? false;
    _autoSuggestBrowse = prefs.getBool(SettingsKeys.autoSuggestBrowse) ?? false;
    _newsListColumns = prefs.getInt(SettingsKeys.newsListColumns) ?? 1;

    _showTooltips = prefs.getBool(SettingsKeys.showTooltips) ?? true;
    _blurredContentRatings = prefs.getStringList(SettingsKeys.blurredContentRatings) ?? [];

    _separateGridColumnCounts = prefs.getBool(SettingsKeys.separateGridColumnCounts) ?? false;
    _gridColumnCount = prefs.getInt(SettingsKeys.gridColumnCount) ?? 0;
    _libraryGridColumnCount = prefs.getInt(SettingsKeys.libraryGridColumnCount) ?? 0;
    _browseGridColumnCount = prefs.getInt(SettingsKeys.browseGridColumnCount) ?? 0;

    notifyListeners();
  }

  Future<void> setListStyle(AppListStyle style) async {
    if (_currentListStyle == style) return;
    _currentListStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.listStylePref, style.index);
    notifyListeners();
  }

  Future<void> setHideLibrarySeriesInBrowse(bool value) async {
    if (_hideLibrarySeriesInBrowse == value) return;
    _hideLibrarySeriesInBrowse = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.hideLibrarySeriesInBrowse, value);
    notifyListeners();
  }

  Future<void> setContentPreferences(List<String> prefsList) async {
    _contentPreferences = prefsList;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(SettingsKeys.contentPreferences, prefsList);
    notifyListeners();
  }

  Future<void> setHasCompletedOnboarding(bool value) async {
    if (_hasCompletedOnboarding == value) return;
    _hasCompletedOnboarding = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.onboardingCompleted, value);
    notifyListeners();
  }

  Future<void> setDefaultStartPage(AppStartPage page) async {
    if (_defaultStartPage == page) return;
    _defaultStartPage = page;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.defaultStartPage, page.index);
    notifyListeners();
  }

  Future<void> setRatingSliderStep(RatingSliderStep step) async {
    if (_ratingSliderStep == step) return;
    _ratingSliderStep = step;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.ratingSliderStep, step.index);
    notifyListeners();
  }

  Future<void> setAddLibraryDefaultTab(String tabKey) async {
    if (_addLibraryDefaultTab == tabKey) return;
    _addLibraryDefaultTab = tabKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SettingsKeys.addLibraryDefaultTab, tabKey);
    notifyListeners();
  }

  Future<void> setDefaultTitleLanguage(TitleLanguage lang) async {
    if (_defaultTitleLanguage == lang) return;
    _defaultTitleLanguage = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.defaultTitleLanguage, lang.index);
    notifyListeners();
  }

  Future<void> setSeparateListStyles(bool value) async {
    if (_separateListStyles == value) return;
    _separateListStyles = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.separateListStyles, value);
    notifyListeners();
  }

  Future<void> setLibraryListStyle(AppListStyle style) async {
    if (_libraryListStyle == style) return;
    _libraryListStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.libraryListStyle, style.index);
    notifyListeners();
  }

  Future<void> setBrowseListStyle(AppListStyle style) async {
    if (_browseListStyle == style) return;
    _browseListStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.browseListStyle, style.index);
    notifyListeners();
  }

  Future<void> setPushNotifications(bool value) async {
    if (_pushNotifications == value) return;
    _pushNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.pushNotifications, value);
    notifyListeners();
  }

  Future<void> setAutoSuggestBrowse(bool value) async {
    if (_autoSuggestBrowse == value) return;
    _autoSuggestBrowse = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.autoSuggestBrowse, value);
    notifyListeners();
  }

  Future<void> setNewsListColumns(int columns) async {
    if (_newsListColumns == columns) return;
    _newsListColumns = columns;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.newsListColumns, columns);
    notifyListeners();
  }



  Future<void> setShowTooltips(bool value) async {
    if (_showTooltips == value) return;
    _showTooltips = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.showTooltips, value);
    notifyListeners();
  }

  Future<void> setBlurredContentRatings(List<String> ratings) async {
    _blurredContentRatings = ratings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(SettingsKeys.blurredContentRatings, ratings);
    notifyListeners();
  }

  Future<void> setSeparateGridColumnCounts(bool value) async {
    if (_separateGridColumnCounts == value) return;
    _separateGridColumnCounts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.separateGridColumnCounts, value);
    notifyListeners();
  }

  Future<void> setGridColumnCount(int value) async {
    if (_gridColumnCount == value) return;
    _gridColumnCount = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.gridColumnCount, value);
    notifyListeners();
  }

  Future<void> setLibraryGridColumnCount(int value) async {
    if (_libraryGridColumnCount == value) return;
    _libraryGridColumnCount = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.libraryGridColumnCount, value);
    notifyListeners();
  }

  Future<void> setBrowseGridColumnCount(int value) async {
    if (_browseGridColumnCount == value) return;
    _browseGridColumnCount = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.browseGridColumnCount, value);
    notifyListeners();
  }
}

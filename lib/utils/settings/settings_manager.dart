import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

import 'package:bakahyou/utils/settings/settings_enums.dart';


const String _hideLibrarySeriesInBrowseKey = '${AppConstants.prefixStorageKey}hide_library_series';
const String _contentPreferencesKey = '${AppConstants.prefixStorageKey}content_prefs';
const String _onboardingCompletedKey = '${AppConstants.prefixStorageKey}onboarding_completed';
const String _defaultStartPageKey = '${AppConstants.prefixStorageKey}default_start_page';
const String _ratingSliderStepKey = '${AppConstants.prefixStorageKey}rating_slider_step';
const String _addLibraryDefaultTabKey = '${AppConstants.prefixStorageKey}add_library_default_tab';
const String _defaultTitleLanguageKey = '${AppConstants.prefixStorageKey}default_title_language';
const String _separateListStylesKey = '${AppConstants.prefixStorageKey}separate_list_styles';
const String _libraryListStyleKey = '${AppConstants.prefixStorageKey}library_list_style';
const String _browseListStyleKey = '${AppConstants.prefixStorageKey}browse_list_style';
const String _pushNotificationsKey = '${AppConstants.prefixStorageKey}push_notifications';
const String _autoSuggestBrowseKey = '${AppConstants.prefixStorageKey}auto_suggest_browse';

class SettingsManager extends ChangeNotifier {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();

  static const String _listStyleKey = '${AppConstants.prefixStorageKey}list_style_pref';

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

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load List Style
    final listStyleIndex = prefs.getInt(_listStyleKey);
    if (listStyleIndex != null && listStyleIndex >= 0 && listStyleIndex < AppListStyle.values.length) {
      _currentListStyle = AppListStyle.values[listStyleIndex];
    }
    
    // Load Hide Library Series In Browse
    _hideLibrarySeriesInBrowse = prefs.getBool(_hideLibrarySeriesInBrowseKey) ?? false;
    
    // Load Content Preferences
    final savedContentPrefs = prefs.getStringList(_contentPreferencesKey);
    if (savedContentPrefs != null && savedContentPrefs.isNotEmpty) {
      _contentPreferences = savedContentPrefs;
    }

    // Load Onboarding Completed
    _hasCompletedOnboarding = prefs.getBool(_onboardingCompletedKey) ?? false;
    
    final startPageIndex = prefs.getInt(_defaultStartPageKey);
    if (startPageIndex != null && startPageIndex >= 0 && startPageIndex < AppStartPage.values.length) {
      _defaultStartPage = AppStartPage.values[startPageIndex];
    }

    final ratingStepIndex = prefs.getInt(_ratingSliderStepKey);
    if (ratingStepIndex != null && ratingStepIndex >= 0 && ratingStepIndex < RatingSliderStep.values.length) {
      _ratingSliderStep = RatingSliderStep.values[ratingStepIndex];
    }

    _addLibraryDefaultTab = prefs.getString(_addLibraryDefaultTabKey) ?? 'plan_to_read';

    final titleLangIndex = prefs.getInt(_defaultTitleLanguageKey);
    if (titleLangIndex != null && titleLangIndex >= 0 && titleLangIndex < TitleLanguage.values.length) {
      _defaultTitleLanguage = TitleLanguage.values[titleLangIndex];
    }

    _separateListStyles = prefs.getBool(_separateListStylesKey) ?? false;

    final libStyleIndex = prefs.getInt(_libraryListStyleKey);
    if (libStyleIndex != null && libStyleIndex >= 0 && libStyleIndex < AppListStyle.values.length) {
      _libraryListStyle = AppListStyle.values[libStyleIndex];
    }

    final browseStyleIndex = prefs.getInt(_browseListStyleKey);
    if (browseStyleIndex != null && browseStyleIndex >= 0 && browseStyleIndex < AppListStyle.values.length) {
      _browseListStyle = AppListStyle.values[browseStyleIndex];
    }

    _pushNotifications = prefs.getBool(_pushNotificationsKey) ?? false;
    _autoSuggestBrowse = prefs.getBool(_autoSuggestBrowseKey) ?? false;

    notifyListeners();
  }

  Future<void> setListStyle(AppListStyle style) async {
    if (_currentListStyle == style) return;
    
    _currentListStyle = style;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_listStyleKey, style.index);
    
    notifyListeners();
  }

  Future<void> setHideLibrarySeriesInBrowse(bool value) async {
    if (_hideLibrarySeriesInBrowse == value) return;
    
    _hideLibrarySeriesInBrowse = value;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideLibrarySeriesInBrowseKey, value);
    
    notifyListeners();
  }

  Future<void> setContentPreferences(List<String> prefsList) async {
    _contentPreferences = prefsList;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_contentPreferencesKey, prefsList);
    
    notifyListeners();
  }

  Future<void> setHasCompletedOnboarding(bool value) async {
    if (_hasCompletedOnboarding == value) return;

    _hasCompletedOnboarding = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, value);

    notifyListeners();
  }

  Future<void> setDefaultStartPage(AppStartPage page) async {
    if (_defaultStartPage == page) return;
    _defaultStartPage = page;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultStartPageKey, page.index);
    notifyListeners();
  }

  Future<void> setRatingSliderStep(RatingSliderStep step) async {
    if (_ratingSliderStep == step) return;
    _ratingSliderStep = step;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_ratingSliderStepKey, step.index);
    notifyListeners();
  }

  Future<void> setAddLibraryDefaultTab(String tabKey) async {
    if (_addLibraryDefaultTab == tabKey) return;
    _addLibraryDefaultTab = tabKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addLibraryDefaultTabKey, tabKey);
    notifyListeners();
  }

  Future<void> setDefaultTitleLanguage(TitleLanguage lang) async {
    if (_defaultTitleLanguage == lang) return;
    _defaultTitleLanguage = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultTitleLanguageKey, lang.index);
    notifyListeners();
  }

  Future<void> setSeparateListStyles(bool value) async {
    if (_separateListStyles == value) return;
    _separateListStyles = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_separateListStylesKey, value);
    notifyListeners();
  }

  Future<void> setLibraryListStyle(AppListStyle style) async {
    if (_libraryListStyle == style) return;
    _libraryListStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_libraryListStyleKey, style.index);
    notifyListeners();
  }

  Future<void> setBrowseListStyle(AppListStyle style) async {
    if (_browseListStyle == style) return;
    _browseListStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_browseListStyleKey, style.index);
    notifyListeners();
  }

  Future<void> setPushNotifications(bool value) async {
    if (_pushNotifications == value) return;
    _pushNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushNotificationsKey, value);
    notifyListeners();
  }

  Future<void> setAutoSuggestBrowse(bool value) async {
    if (_autoSuggestBrowse == value) return;
    _autoSuggestBrowse = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSuggestBrowseKey, value);
    notifyListeners();
  }
}

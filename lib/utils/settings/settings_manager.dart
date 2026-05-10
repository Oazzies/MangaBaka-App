import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mangabaka_app/utils/settings/settings_enums.dart';
import 'package:mangabaka_app/utils/settings/settings_keys.dart';

class SettingsManager extends ChangeNotifier {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();

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
    
    try {
      final tempDir = await getTemporaryDirectory();
      final markerFile = File('${tempDir.path}/.install_marker');
      if (!await markerFile.exists()) {
        await prefs.setBool(SettingsKeys.onboardingCompleted, false);
        await markerFile.writeAsString(DateTime.now().toIso8601String());
      }
    } catch (e) {
      debugPrint('Error setting install marker: $e');
    }

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
}

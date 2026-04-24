import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

enum AppListStyle {
  comfortable,
  compact,
  minimalList,
  grid,
}

const String _hideLibrarySeriesInBrowseKey = '${AppConstants.prefixStorageKey}hide_library_series';
const String _contentPreferencesKey = '${AppConstants.prefixStorageKey}content_prefs';
const String _onboardingCompletedKey = '${AppConstants.prefixStorageKey}onboarding_completed';

class SettingsManager extends ChangeNotifier {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();

  static const String _listStyleKey = '${AppConstants.prefixStorageKey}list_style_pref';

  AppListStyle _currentListStyle = AppListStyle.comfortable;
  AppListStyle get currentListStyle => _currentListStyle;

  bool _hideLibrarySeriesInBrowse = false;
  bool get hideLibrarySeriesInBrowse => _hideLibrarySeriesInBrowse;

  List<String> _contentPreferences = ['safe', 'suggestive'];
  List<String> get contentPreferences => _contentPreferences;

  bool _hasCompletedOnboarding = false;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

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
}

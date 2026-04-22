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

class SettingsManager extends ChangeNotifier {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();

  static const String _listStyleKey = '${AppConstants.prefixStorageKey}list_style_pref';

  AppListStyle _currentListStyle = AppListStyle.comfortable;
  AppListStyle get currentListStyle => _currentListStyle;

  bool _hideLibrarySeriesInBrowse = false;
  bool get hideLibrarySeriesInBrowse => _hideLibrarySeriesInBrowse;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load List Style
    final listStyleIndex = prefs.getInt(_listStyleKey);
    if (listStyleIndex != null && listStyleIndex >= 0 && listStyleIndex < AppListStyle.values.length) {
      _currentListStyle = AppListStyle.values[listStyleIndex];
    }
    
    // Load Hide Library Series In Browse
    _hideLibrarySeriesInBrowse = prefs.getBool(_hideLibrarySeriesInBrowseKey) ?? false;
    
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
}

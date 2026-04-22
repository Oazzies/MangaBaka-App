import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class ThemeManager extends ChangeNotifier with WidgetsBindingObserver {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  static String _themeKey = '${AppConstants.prefixStorageKey}theme_pref';

  AppTheme _currentTheme = AppTheme.dark;
  AppTheme get currentTheme => _currentTheme;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null && themeIndex >= 0 && themeIndex < AppTheme.values.length) {
      _currentTheme = AppTheme.values[themeIndex];
    }
    AppConstants.setAppTheme(_currentTheme);
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    if (_currentTheme == theme) return;
    
    _currentTheme = theme;
    AppConstants.setAppTheme(_currentTheme);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
    
    notifyListeners();
  }

  @override
  void didChangePlatformBrightness() {
    if (_currentTheme == AppTheme.system) {
      AppConstants.setAppTheme(AppTheme.system);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

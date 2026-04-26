import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class ThemeManager extends ChangeNotifier with WidgetsBindingObserver {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  static const String _themeModeKey =
      '${AppConstants.prefixStorageKey}theme_mode_pref';
  static const String _appThemeKey =
      '${AppConstants.prefixStorageKey}app_theme_pref';

  ThemeMode _currentThemeMode = ThemeMode.system;
  ThemeMode get currentThemeMode => _currentThemeMode;

  AppTheme _currentTheme = AppTheme.defaultTheme;
  AppTheme get currentTheme => _currentTheme;

  bool get isDarkMode {
    if (_currentThemeMode == ThemeMode.system) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _currentThemeMode == ThemeMode.dark;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final modeIndex = prefs.getInt(_themeModeKey);
    if (modeIndex != null &&
        modeIndex >= 0 &&
        modeIndex < ThemeMode.values.length) {
      _currentThemeMode = ThemeMode.values[modeIndex];
    }

    final themeIndex = prefs.getInt(_appThemeKey);
    if (themeIndex != null &&
        themeIndex >= 0 &&
        themeIndex < AppTheme.values.length) {
      _currentTheme = AppTheme.values[themeIndex];
    }

    _applyTheme();
  }

  void _applyTheme() {
    bool isDark = false;
    if (_currentThemeMode == ThemeMode.system) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      isDark = brightness == Brightness.dark;
    } else {
      isDark = _currentThemeMode == ThemeMode.dark;
    }
    AppConstants.setAppTheme(_currentTheme, isDark);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_currentThemeMode == mode) return;

    _currentThemeMode = mode;
    _applyTheme();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setTheme(AppTheme theme) async {
    if (_currentTheme == theme) return;

    _currentTheme = theme;
    _applyTheme();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_appThemeKey, theme.index);
  }

  @override
  void didChangePlatformBrightness() {
    if (_currentThemeMode == ThemeMode.system) {
      _applyTheme();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

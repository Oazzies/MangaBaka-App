import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/core/theme/theme_manager.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Reset singleton state between tests
    await ThemeManager().setThemeMode(ThemeMode.system);
  });

  group('ThemeManager', () {
    test('is a singleton', () {
      expect(ThemeManager(), same(ThemeManager()));
    });

    test('defaults to system theme mode', () {
      expect(ThemeManager().currentThemeMode, ThemeMode.system);
    });

    test('setThemeMode persists and updates current mode', () async {
      final mgr = ThemeManager();
      await mgr.setThemeMode(ThemeMode.dark);
      expect(mgr.currentThemeMode, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('mangabaka_app_theme_mode_pref'), ThemeMode.dark.index);
    });

    test('setThemeMode is a no-op when mode unchanged', () async {
      final mgr = ThemeManager();
      await mgr.setThemeMode(ThemeMode.light);

      var notified = false;
      mgr.addListener(() => notified = true);
      await mgr.setThemeMode(ThemeMode.light);
      expect(notified, isFalse);
      mgr.removeListener(() {});
    });

    test('init restores persisted theme mode', () async {
      SharedPreferences.setMockInitialValues({
        'mangabaka_app_theme_mode_pref': ThemeMode.dark.index,
      });
      await ThemeManager().init();
      expect(ThemeManager().currentThemeMode, ThemeMode.dark);
    });

    test('isDarkMode returns true when mode is dark', () async {
      await ThemeManager().setThemeMode(ThemeMode.dark);
      expect(ThemeManager().isDarkMode, isTrue);
    });

    test('isDarkMode returns false when mode is light', () async {
      await ThemeManager().setThemeMode(ThemeMode.light);
      expect(ThemeManager().isDarkMode, isFalse);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_keys.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/palette/mb_theme_spec.dart';
import 'package:mangabaka_app/core/theme/presets/theme_presets.dart';
import 'package:mangabaka_app/core/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ThemeController> boot([Map<String, Object> prefs = const {}]) async {
    SharedPreferences.setMockInitialValues(prefs);
    SettingsManager.resetForTesting();
    ThemeController.resetForTesting();
    await SettingsManager().init();
    return ThemeController()..init();
  }

  tearDown(() {
    ThemeController.resetForTesting();
  });

  test('defaults to the original dark theme', () async {
    final c = await boot();
    expect(c.mode, AppThemeMode.dark);
    expect(c.current, inkPalette);
  });

  test('unknown stored ids fall back to the default theme', () async {
    final c = await boot({
      SettingsKeys.darkThemeId: 'retired_theme',
      SettingsKeys.lightThemeId: 'amoled', // dark-only preset
    });
    expect(c.darkPalette, inkPalette);
    expect(c.lightPalette, ThemePresets.fallback.light);
  });

  test('mode and selection resolve the current palette', () async {
    final c = await boot();
    await c.apply('nord', Brightness.light);
    expect(c.mode, AppThemeMode.light);
    expect(c.current, ThemePresets.byId('nord')!.light);

    await c.setMode(AppThemeMode.dark);
    expect(c.current, inkPalette);
  });

  test('system mode follows platform brightness', () async {
    final c = await boot();
    await c.setMode(AppThemeMode.system);
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(binding.platformDispatcher.clearPlatformBrightnessTestValue);
    expect(c.current.brightness, Brightness.light);
    binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    expect(c.current.brightness, Brightness.dark);
  });

  test('accent override applies to both slots and clears', () async {
    final c = await boot();
    await c.setAccentOverride(const Color(0xFFF43F5E));
    expect(c.darkPalette.accent, const Color(0xFFF43F5E));
    expect(c.lightPalette.accent, isNot(ThemePresets.fallback.light!.accent));
    await c.setAccentOverride(null);
    expect(c.darkPalette, inkPalette);
  });

  test('custom themes save, select, import and delete', () async {
    final c = await boot();
    const spec = MbThemeSpec(
      id: 'custom:one',
      name: 'Mine',
      background: Color(0xFF101820),
      accent: Color(0xFFFF8800),
    );
    await c.saveCustom(spec);
    expect(c.customThemes, [spec]);
    expect(c.choicesFor(Brightness.dark).last.id, spec.id);
    expect(c.choicesFor(Brightness.light).any((x) => x.id == spec.id), isFalse);

    await c.select(spec.id, Brightness.dark);
    expect(c.darkPalette, spec.palette);

    final imported = await c.importShareCode(spec.toShareCode());
    expect(imported, isNotNull);
    expect(c.customThemes.length, 2);
    expect(await c.importShareCode('not a theme'), isNull);

    await c.deleteCustom(spec.id);
    expect(c.customThemes.length, 1);
    expect(c.darkThemeId, ThemePresets.defaultId);
    expect(c.darkPalette, inkPalette);
  });

  test('does not notify for unrelated settings', () async {
    final c = await boot();
    var count = 0;
    c.addListener(() => count++);
    await SettingsManager().setShowTooltips(false);
    expect(count, 0);
    await c.select('dracula', Brightness.dark);
    expect(count, 1);
  });
}

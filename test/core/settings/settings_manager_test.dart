import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
  });

  group('SettingsManager', () {
    test('initializes with default values', () async {
      final manager = SettingsManager();
      await manager.init();

      expect(manager.currentListStyle, AppListStyle.compactGrid);
      expect(manager.hideLibrarySeriesInBrowse, false);
      expect(manager.contentPreferences, ['safe', 'suggestive']);
      expect(manager.showTooltips, true);
      expect(manager.compactGridTitleRows, 1);
    });

    test('loads values from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        SettingsKeys.listStylePref: AppListStyle.comfortable.index,
        SettingsKeys.hideLibrarySeriesInBrowse: true,
        SettingsKeys.contentPreferences: ['safe', 'suggestive', 'erotica'],
        SettingsKeys.showTooltips: false,
        SettingsKeys.compactGridTitleRows: 3,
      });

      final manager = SettingsManager();
      await manager.init();

      expect(manager.currentListStyle, AppListStyle.comfortable);
      expect(manager.hideLibrarySeriesInBrowse, true);
      expect(manager.contentPreferences, contains('erotica'));
      expect(manager.showTooltips, false);
      expect(manager.compactGridTitleRows, 3);
    });

    test('updates values and notifies listeners', () async {
      final manager = SettingsManager();
      await manager.init();

      bool notified = false;
      manager.addListener(() {
        notified = true;
      });

      await manager.setListStyle(AppListStyle.compact);
      expect(manager.currentListStyle, AppListStyle.compact);
      expect(notified, true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(SettingsKeys.listStylePref), AppListStyle.compact.index);
    });

    test('setContentPreferences updates and persists', () async {
      final manager = SettingsManager();
      await manager.init();

      await manager.setContentPreferences(['safe']);
      expect(manager.contentPreferences, ['safe']);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(SettingsKeys.contentPreferences), ['safe']);
    });

    test('toggle separateListStyles persists', () async {
      final manager = SettingsManager();
      await manager.init();

      await manager.setSeparateListStyles(true);
      expect(manager.separateListStyles, true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(SettingsKeys.separateListStyles), true);
    });

    test('compactGridTitleRows updates and persists within limits', () async {
      final manager = SettingsManager();
      await manager.init();

      await manager.setCompactGridTitleRows(5);
      expect(manager.compactGridTitleRows, 5);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(SettingsKeys.compactGridTitleRows), 5);

      // Test clamping/limits
      await manager.setCompactGridTitleRows(100);
      expect(manager.compactGridTitleRows, 99); // Clamped to 99

      await manager.setCompactGridTitleRows(0);
      expect(manager.compactGridTitleRows, 1); // Clamped to 1
    });
  });
}

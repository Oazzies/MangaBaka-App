import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_customization_settings.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_style_preview_item.dart';

class _FakeAuth extends Fake implements ProfileAuthService {
  @override
  bool get isLoggedIn => false;
  @override
  MbProfile? get cachedProfile => null;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

class _FakeLibraryService extends Fake implements LibraryService {
  @override
  Stream<LibraryEntry?> watchEntryFromDb(String seriesId) =>
      Stream<LibraryEntry?>.value(null);
}

/// A 4000px canvas lays the whole column out, so every control is hit-testable.
Future<void> _pumpPanel(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListenableBuilder(
          listenable: SettingsManager(),
          builder: (context, _) => SingleChildScrollView(
            child: ListCustomizationSettings(l10n: LocalizationService()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _tapStyle(WidgetTester tester, AppListStyle style) async {
  final item = find.byWidgetPredicate(
    (w) => w is ListStylePreviewItem && w.style == style,
  );
  expect(item, findsOneWidget);
  await tester.tap(item, warnIfMissed: false);
  await tester.pump();
}

void main() {
  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
    getIt.registerSingleton<ProfileAuthService>(_FakeAuth());
    getIt.registerSingleton<LibraryService>(_FakeLibraryService());

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );

    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
  });

  testWidgets(
    'picking a style writes the shared style the lists actually read',
    (tester) async {
      final settings = SettingsManager();
      expect(settings.separateListStyles, isFalse);

      await _pumpPanel(tester);
      await _tapStyle(tester, AppListStyle.comfortable);

      expect(settings.currentListStyle, AppListStyle.comfortable);
    },
  );

  testWidgets(
    'with separation on, the Library tab writes the library style',
    (tester) async {
      final settings = SettingsManager();
      await settings.setSeparateListStyles(true);

      await _pumpPanel(tester);
      await _tapStyle(tester, AppListStyle.minimalList);

      expect(settings.libraryListStyle, AppListStyle.minimalList);
      expect(settings.browseListStyle, isNot(AppListStyle.minimalList));
    },
  );

  testWidgets(
    'the tab selector only appears once a list is configured separately',
    (tester) async {
      final settings = SettingsManager();

      await _pumpPanel(tester);
      expect(find.text('start_page_library'), findsNothing);

      await settings.setSeparateListStyles(true);
      await tester.pump();
      expect(find.text('start_page_library'), findsOneWidget);
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/widgets/adaptive_form.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_status_controller.dart';
import 'package:mangabaka_app/features/stacks/screens/stack_editor_screen.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_series_search.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../responsive/support/fake_services.dart';
import '../../responsive/support/fixtures.dart' as rf;
import 'fake_stack_service.dart';

class _NoSeriesSearch extends Fake implements SeriesSearchService {}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
    await resetServiceLocator();
    LocalizationService.resetForTesting();
    await LocalizationService().init();
    getIt.registerSingleton<LoggingService>(LoggingService());
    final stacks = FakeStacksService();
    final auth = FakeAuth(signedIn: true);
    getIt
      ..registerSingleton<ProfileAuthService>(auth)
      ..registerSingleton<LibraryService>(FakeLibrary(rf.Fixtures.library(0)))
      ..registerSingleton<StackService>(stacks)
      ..registerSingleton<SeriesSearchService>(_NoSeriesSearch())
      ..registerSingleton<StackStatusController>(
        StackStatusController(service: stacks, auth: auth),
      );
  });

  tearDown(() {
    DesktopLayout.debugOverride = null;
    return resetServiceLocator();
  });

  String t(String key) => LocalizationService().translate(key);

  Future<void> pumpEditor(
    WidgetTester tester, {
    required Size size,
    bool desktop = false,
  }) async {
    DesktopLayout.debugOverride = desktop;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: StackEditorScreen(stackId: 7)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> openSeriesTab(WidgetTester tester) async {
    await tester.tap(find.text(t('stacks_tab_series').replaceAll('{n}', '2')));
    await settle(tester);
  }

  testWidgets('on a phone the note editor is its own page', (tester) async {
    await pumpEditor(tester, size: const Size(420, 900));
    await openSeriesTab(tester);
    await tester.tap(find.text('Hi'));
    await settle(tester);

    final page = find.byType(AdaptiveFormPage);
    expect(page, findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    await tester.enterText(
      find.descendant(of: page, matching: find.byType(TextField)),
      'A better note',
    );
    await tester.tap(
      find.descendant(of: page, matching: find.byType(MbPrimaryButton)),
    );
    await settle(tester);
    expect(find.byType(AdaptiveFormPage), findsNothing);
    expect(find.text('A better note'), findsOneWidget);
  });

  testWidgets('on a phone the series picker is its own page', (tester) async {
    await pumpEditor(tester, size: const Size(420, 900));
    await openSeriesTab(tester);
    await tester.tap(find.text(t('stacks_add_series').toUpperCase()));
    await settle(tester);

    expect(
      find.descendant(
        of: find.byType(AdaptiveFormPage),
        matching: find.byType(StackSeriesSearch),
      ),
      findsOneWidget,
    );
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('on desktop the series picker is a dialog', (tester) async {
    await pumpEditor(tester, size: const Size(1100, 800), desktop: true);
    await tester.tap(find.text(t('stacks_add_series').toUpperCase()));
    await settle(tester);

    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(StackSeriesSearch),
      ),
      findsOneWidget,
    );
    expect(find.byType(AdaptiveFormPage), findsNothing);
    await tester.tap(find.text(t('done')));
    await settle(tester);
    expect(find.byType(Dialog), findsNothing);
  });
}

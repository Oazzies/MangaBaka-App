import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/desktop/screens/settings/desktop_settings_screen.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuth extends Fake implements ProfileAuthService {
  @override
  bool get isLoggedIn => true;
  @override
  MbProfile? get cachedProfile => null;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsManager().init();
  });

  group('DesktopSettingsScreen', () {
    setUp(() async {
      await resetServiceLocator();
      getIt.registerSingleton<ProfileAuthService>(_FakeAuth());
    });

    tearDown(resetServiceLocator);

    Future<void> pumpSettings(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DesktopSettingsScreen(key: DesktopSettingsScreen.stateKey),
          ),
        ),
      );
      DesktopSettingsScreen.stateKey.currentState?.debugSelectCategory('general');
      await tester.pumpAndSettle();
    }

    testWidgets('Developer Tools are hidden until developer mode is on',
        (tester) async {
      await pumpSettings(tester);
      expect(find.text('advanced_settings'), findsNothing);

      await SettingsManager().setDeveloperMode(true);
      await tester.pumpAndSettle();
      expect(find.text('advanced_settings'), findsOneWidget);
    });

    testWidgets('logs open from Advanced and go back to it', (tester) async {
      await pumpSettings(tester);
      await SettingsManager().setDeveloperMode(true);
      await tester.pumpAndSettle();

      await tester.tap(find.text('advanced_settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(DesktopPillButton, 'LOGS'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('back'), findsOneWidget);
      expect(find.text('redo_onboarding'.toUpperCase()), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.byTooltip('back'), findsNothing);
      expect(find.text('REDO_ONBOARDING'), findsWidgets);
    });

    testWidgets('categories switch to selected category', (tester) async {
      await pumpSettings(tester);

      expect(find.text('LANGUAGE'), findsOneWidget, reason: 'General selected');
      await tester.tap(find.text('content'));
      await tester.pumpAndSettle();
      expect(find.text('LANGUAGE'), findsNothing, reason: 'General left');
      expect(find.text('RATING_STEP'), findsOneWidget, reason: 'Content arrived');
    });

    testWidgets('a shown content rating can have its covers blurred',
        (tester) async {
      await pumpSettings(tester);
      await tester.tap(find.text('content'));
      await tester.pumpAndSettle();

      expect(SettingsManager().contentPreferences, contains('safe'));
      expect(SettingsManager().blurredContentRatings, isNot(contains('safe')));

      final rows = find.byType(Switch);
      await tester.ensureVisible(rows.first);
      final safeRow = find.ancestor(
        of: find.text('SAFE'),
        matching: find.byType(DesktopHoverSurface),
      );
      final blurSwitch = find.descendant(
        of: safeRow.first,
        matching: find.byType(Switch),
      );
      await tester.tap(blurSwitch);
      await tester.pumpAndSettle();

      expect(SettingsManager().blurredContentRatings, contains('safe'));
    });
  });
}

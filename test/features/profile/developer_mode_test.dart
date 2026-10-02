import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/profile/developer/developer_tools.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A clock the tests move by hand: widget tests never advance the real one.
DateTime _now = DateTime(2026);
DateTime _clock() => _now;

Future<void> _tap(WidgetTester tester, int times, {Duration gap = const Duration(milliseconds: 100)}) async {
  for (var i = 0; i < times; i++) {
    await tester.tap(find.byKey(const Key('logo')));
    _now = _now.add(gap);
    await tester.pump(gap);
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
    LocalizationService.resetForTesting();
    await LocalizationService().init();
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: DeveloperModeTapTarget(
                clock: _clock,
                child: const SizedBox(key: Key('logo'), width: 60, height: 60),
              ),
            ),
          ),
        ),
      );

  testWidgets('ten quick taps switch developer mode on', (tester) async {
    await pump(tester);
    expect(SettingsManager().developerMode, isFalse);

    await _tap(tester, 9);
    expect(SettingsManager().developerMode, isFalse);

    await _tap(tester, 1);
    await tester.pumpAndSettle();
    expect(SettingsManager().developerMode, isTrue);
  });

  testWidgets('slow taps never get there', (tester) async {
    await pump(tester);
    await _tap(tester, 12, gap: const Duration(milliseconds: 900));
    expect(SettingsManager().developerMode, isFalse);
  });

  testWidgets('switching off asks first, and cancelling keeps it on', (tester) async {
    await SettingsManager().setDeveloperMode(true);
    await pump(tester);

    await _tap(tester, 10);
    await tester.pumpAndSettle();
    expect(find.text('Deactivate developer mode?'), findsOneWidget);
    expect(SettingsManager().developerMode, isTrue);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(SettingsManager().developerMode, isTrue);

    await _tap(tester, 10);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deactivate'));
    await tester.pumpAndSettle();
    expect(SettingsManager().developerMode, isFalse);
  });
}

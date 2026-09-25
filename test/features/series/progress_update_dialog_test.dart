import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_theme.dart';
import 'package:mangabaka_app/core/theme/presets/theme_presets.dart';
import 'package:mangabaka_app/features/series/widgets/progress_update_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalizationService().init();
  });

  /// Pumps the dialog and returns a getter for the value it last saved.
  Future<int? Function()> pumpDialog(
    WidgetTester tester, {
    int initial = 5,
  }) async {
    int? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(ThemePresets.fallback.dark!, showTooltips: false),
        home: Scaffold(
          body: ProgressUpdateDialog(
            initialValue: initial,
            title: 'Chapter',
            maxValue: '100',
            onUpdate: (v) => saved = v,
          ),
        ),
      ),
    );
    return () => saved;
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text(LocalizationService().translate('save')));
    await tester.pump();
  }

  testWidgets('typed input keeps digits only, so it can never go negative',
      (tester) async {
    final saved = await pumpDialog(tester);

    await tester.enterText(find.byType(TextField), '-12');
    expect(find.text('12'), findsOneWidget);

    await save(tester);
    expect(saved(), 12);
  });

  testWidgets('typed input is capped at the maximum length', (tester) async {
    final saved = await pumpDialog(tester);

    await tester.enterText(find.byType(TextField), '1234567');
    await save(tester);

    expect(saved(), lessThanOrEqualTo(ProgressUpdateDialog.maxProgress));
    expect(saved(), 12345);
  });

  testWidgets('the minus button stops at zero', (tester) async {
    final saved = await pumpDialog(tester, initial: 1);

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    await save(tester);

    expect(saved(), 0);
  });

  testWidgets('the plus button stops at the maximum', (tester) async {
    final saved =
        await pumpDialog(tester, initial: ProgressUpdateDialog.maxProgress);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await save(tester);

    expect(saved(), ProgressUpdateDialog.maxProgress);
  });
}

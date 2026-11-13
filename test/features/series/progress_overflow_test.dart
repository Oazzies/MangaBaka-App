import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_theme.dart';
import 'package:mangabaka_app/core/theme/presets/theme_presets.dart';
import 'package:mangabaka_app/features/series/widgets/progress_update_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
    await LocalizationService().init();
  });

  group('SettingsManager.progressOverflow', () {
    test('defaults to promptCompletedOnly and persists changes', () async {
      expect(
        SettingsManager().progressOverflow,
        ProgressOverflowMode.promptCompletedOnly,
      );

      await SettingsManager().setProgressOverflow(ProgressOverflowMode.never);
      expect(SettingsManager().progressOverflow, ProgressOverflowMode.never);

      // Re-init from SharedPreferences to verify persistence.
      SettingsManager.resetForTesting();
      await SettingsManager().init();
      expect(SettingsManager().progressOverflow, ProgressOverflowMode.never);
    });
  });

  group('ProgressUpdateDialog overflow handling', () {
    Future<int? Function()> pumpDialog(
      WidgetTester tester, {
      int initial = 10,
      String maxValue = '10',
      bool isChapter = true,
      String? seriesStatus = 'completed',
    }) async {
      int? saved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(ThemePresets.fallback.dark!, showTooltips: false),
          home: Scaffold(
            body: ProgressUpdateDialog(
              initialValue: initial,
              title: isChapter ? 'Chapters' : 'Volumes',
              maxValue: maxValue,
              isChapter: isChapter,
              seriesStatus: seriesStatus,
              onUpdate: (v) => saved = v,
            ),
          ),
        ),
      );
      return () => saved;
    }

    testWidgets('never mode stops plus button and clamps typed input at total',
        (tester) async {
      await SettingsManager().setProgressOverflow(ProgressOverflowMode.never);
      final saved = await pumpDialog(tester, initial: 10, maxValue: '10');

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('10'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '25');
      await tester.pump();
      expect(find.text('10'), findsOneWidget);

      await tester.tap(find.text(LocalizationService().translate('save')));
      await tester.pump();
      expect(saved(), 10);
    });

    testWidgets('never mode allows decreasing when already above total',
        (tester) async {
      await SettingsManager().setProgressOverflow(ProgressOverflowMode.never);
      final saved = await pumpDialog(tester, initial: 15, maxValue: '10');

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('15'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(find.text('14'), findsOneWidget);

      await tester.tap(find.text(LocalizationService().translate('save')));
      await tester.pump();
      expect(saved(), 14);
    });

    testWidgets('prompt mode asks on overflow and respects cancel/confirm',
        (tester) async {
      await SettingsManager().setProgressOverflow(ProgressOverflowMode.prompt);
      final saved = await pumpDialog(
        tester,
        initial: 10,
        maxValue: '10',
        isChapter: false,
        seriesStatus: 'releasing',
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('11'), findsOneWidget);

      await tester.tap(find.text(LocalizationService().translate('save')));
      await tester.pumpAndSettle();

      // Overflow prompt should be visible with volume message.
      expect(
        find.text(
          LocalizationService().translate('progress_overflow_title').toUpperCase(),
        ),
        findsOneWidget,
      );

      // Cancel keeps dialog open without saving.
      await tester.tap(find.text(LocalizationService().translate('cancel')).last);
      await tester.pumpAndSettle();
      expect(saved(), isNull);

      // Save again and confirm.
      await tester.tap(find.text(LocalizationService().translate('save')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(LocalizationService().translate('progress_overflow_confirm')),
      );
      await tester.pumpAndSettle();
      expect(saved(), 11);
    });

    testWidgets('always mode saves overflow without prompting', (tester) async {
      await SettingsManager().setProgressOverflow(ProgressOverflowMode.always);
      final saved = await pumpDialog(
        tester,
        initial: 10,
        maxValue: '10',
        seriesStatus: 'completed',
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.text(LocalizationService().translate('save')));
      await tester.pump();

      expect(saved(), 11);
    });

    testWidgets('promptCompletedOnly allows releasing series without prompt',
        (tester) async {
      await SettingsManager().setProgressOverflow(
        ProgressOverflowMode.promptCompletedOnly,
      );

      final savedReleasing = await pumpDialog(
        tester,
        initial: 10,
        maxValue: '10',
        seriesStatus: 'releasing',
      );
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.text(LocalizationService().translate('save')));
      await tester.pump();
      expect(savedReleasing(), 11);
    });

    testWidgets('promptCompletedOnly prompts for completed series',
        (tester) async {
      await SettingsManager().setProgressOverflow(
        ProgressOverflowMode.promptCompletedOnly,
      );

      final savedCompleted = await pumpDialog(
        tester,
        initial: 10,
        maxValue: '10',
        seriesStatus: 'completed',
      );
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.text(LocalizationService().translate('save')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          LocalizationService().translate('progress_overflow_title').toUpperCase(),
        ),
        findsOneWidget,
      );
      expect(savedCompleted(), isNull);
    });
  });
}

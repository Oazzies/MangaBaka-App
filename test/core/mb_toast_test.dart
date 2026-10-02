import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/mb_toast.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/features/library/widgets/sync_progress_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
    LocalizationService.resetForTesting();
    await LocalizationService().init();
  });

  testWidgets('toast colours are solid for every kind', (tester) async {
    late MbPalette palette;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            palette = context.colors;
            return const SizedBox();
          },
        ),
      ),
    );
    for (final kind in ToastKind.values) {
      final t = ToastColors.of(palette, kind);
      for (final c in [t.fill, t.ink, t.inkMuted, t.disc, t.onDisc, t.action, t.onAction]) {
        expect(c.a, 1.0, reason: '$kind has a translucent colour');
      }
    }
  });

  for (final desktop in [false, true]) {
    for (final status in [
      const LibrarySyncStatus(isSyncing: true, currentEntries: 128),
      const LibrarySyncStatus(currentEntries: 128, error: 'Connection timed out'),
    ]) {
      testWidgets(
          'sync card lays out (${desktop ? 'desktop' : 'phone'}, ${status.error == null ? 'syncing' : 'error'})',
          (tester) async {
        tester.view.physicalSize = const Size(600, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var stopped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: SyncStatusCard(
                  status: status,
                  isDesktop: desktop,
                  onStop: () => stopped = true,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        if (status.isSyncing) {
          await tester.tap(find.text('STOP'));
          expect(stopped, isTrue);
        }
      });
    }
  }
}

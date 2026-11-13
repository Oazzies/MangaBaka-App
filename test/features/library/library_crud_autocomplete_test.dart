import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';

import 'library_crud_test_harness.dart';

void main() {
  final h = LibraryCrudTestHarness();

  setUp(h.setUp);
  tearDown(h.tearDown);

  group('autoCompleteSeriesStatus', () {
    test(
      'auto-completes state and volumes when chapter reaches total on completed series with always mode',
      () async {
        await SettingsManager().init();
        await SettingsManager().setAutoCompleteSeriesStatus(
          AutoCompleteProgressMode.always,
        );
        await h.seedEntry(
          '42',
          seriesStatus: 'completed',
          chapter: 82,
          totalChapters: '83',
          volume: 10,
          finalVolume: '16',
        );

        await h.withServer(
          (_) async => http.Response('{}', 200),
          () => h.service.updateLibraryEntryProgress('42', progressChapter: 83),
        );

        expect(jsonDecode(h.requests.single.body), {
          'state': 'completed',
          'progress_chapter': 83,
          'progress_volume': 16,
        });
        final updated = (await h.entryFor('42'))!;
        expect(updated.state, 'completed');
        expect(updated.progressChapter, 83);
        expect(updated.progressVolume, 16);
      },
    );

    test(
      'auto-completes state and chapters when volume reaches total on completed series with always mode',
      () async {
        await SettingsManager().init();
        await SettingsManager().setAutoCompleteSeriesStatus(
          AutoCompleteProgressMode.always,
        );
        await h.seedEntry(
          '42',
          seriesStatus: 'completed',
          chapter: 50,
          totalChapters: '83',
          volume: 15,
          finalVolume: '16',
        );

        await h.withServer(
          (_) async => http.Response('{}', 200),
          () => h.service.updateLibraryEntryProgress('42', progressVolume: 16),
        );

        expect(jsonDecode(h.requests.single.body), {
          'state': 'completed',
          'progress_chapter': 83,
          'progress_volume': 16,
        });
        final updated = (await h.entryFor('42'))!;
        expect(updated.state, 'completed');
        expect(updated.progressChapter, 83);
        expect(updated.progressVolume, 16);
      },
    );

    test('does not auto-complete when series is not completed', () async {
      await SettingsManager().init();
      await SettingsManager().setAutoCompleteSeriesStatus(
        AutoCompleteProgressMode.always,
      );
      await h.seedEntry(
        '42',
        seriesStatus: 'releasing',
        chapter: 82,
        totalChapters: '83',
        volume: 10,
        finalVolume: '16',
      );

      await h.withServer(
        (_) async => http.Response('{}', 200),
        () => h.service.updateLibraryEntryProgress('42', progressChapter: 83),
      );

      expect(jsonDecode(h.requests.single.body), {'progress_chapter': 83});
      final updated = (await h.entryFor('42'))!;
      expect(updated.state, 'reading');
      expect(updated.progressChapter, 83);
      expect(updated.progressVolume, 10);
    });

    test('rolls back state, chapter, and volume when server fails', () async {
      await SettingsManager().init();
      await SettingsManager().setAutoCompleteSeriesStatus(
        AutoCompleteProgressMode.always,
      );
      await h.seedEntry(
        '42',
        seriesStatus: 'completed',
        chapter: 82,
        totalChapters: '83',
        volume: 10,
        finalVolume: '16',
      );

      await expectLater(
        h.withServer(
          (_) async => http.Response('boom', 500),
          () => h.service.updateLibraryEntryProgress('42', progressChapter: 83),
        ),
        throwsA(isA<ApiException>()),
      );

      final rolledBack = (await h.entryFor('42'))!;
      expect(rolledBack.state, 'reading');
      expect(rolledBack.progressChapter, 82);
      expect(rolledBack.progressVolume, 10);
    });

    test('does not auto-complete in prompt or never mode', () async {
      await SettingsManager().init();
      await SettingsManager().setAutoCompleteSeriesStatus(
        AutoCompleteProgressMode.never,
      );
      await h.seedEntry(
        '42',
        seriesStatus: 'completed',
        chapter: 82,
        totalChapters: '83',
        volume: 10,
        finalVolume: '16',
      );

      await h.withServer(
        (_) async => http.Response('{}', 200),
        () => h.service.updateLibraryEntryProgress('42', progressChapter: 83),
      );

      expect(jsonDecode(h.requests.single.body), {'progress_chapter': 83});
      final updated = (await h.entryFor('42'))!;
      expect(updated.state, 'reading');
      expect(updated.progressChapter, 83);
      expect(updated.progressVolume, 10);
    });
  });
}

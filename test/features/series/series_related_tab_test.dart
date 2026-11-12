import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/models/related_series.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/features/series/widgets/tabs/series_related_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSeriesService extends Fake implements SeriesService {}

class _FakeLibraryService extends Fake implements LibraryService {
  @override
  Stream<LibraryEntry?> watchEntryFromDb(String id) => Stream.value(null);
}

class _FakeAuthService extends ChangeNotifier implements ProfileAuthService {
  @override
  bool get isLoggedIn => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Series _series(String id, String title) => Series.fromJson({
  'id': id,
  'title': title,
  'state': 'active',
  'content_rating': 'safe',
});

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  late LocalizationService l10n;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await resetServiceLocator();
    await SettingsManager().init();
    await SettingsManager().setBrowseListStyle(AppListStyle.comfortable);
    l10n = LocalizationService();
    await l10n.init();

    getIt.registerSingleton<SeriesService>(_FakeSeriesService());
    getIt.registerSingleton<LibraryService>(_FakeLibraryService());
    getIt.registerSingleton<ProfileAuthService>(_FakeAuthService());
  });

  tearDown(() async {
    await resetServiceLocator();
  });

  group('SeriesRelatedTab.formatRelationType', () {
    test('translates known relation types', () {
      expect(SeriesRelatedTab.formatRelationType(l10n, 'sequel'), 'Sequel');
      expect(SeriesRelatedTab.formatRelationType(l10n, 'prequel'), 'Prequel');
      expect(SeriesRelatedTab.formatRelationType(l10n, 'spin_off'), 'Spin-off');
      expect(SeriesRelatedTab.formatRelationType(l10n, 'spin-off'), 'Spin-off');
    });

    test('title-cases unknown relation types as fallback', () {
      expect(
        SeriesRelatedTab.formatRelationType(l10n, 'custom_relation'),
        'Custom Relation',
      );
    });

    test('falls back to tab_related when relationType is empty', () {
      expect(
        SeriesRelatedTab.formatRelationType(l10n, '  '),
        l10n.translate('tab_related'),
      );
    });
  });

  group('SeriesRelatedTab', () {
    testWidgets('shows spinner while related is null', (tester) async {
      await tester.pumpWidget(
        _wrap(SeriesRelatedTab(related: null, l10n: l10n)),
      );
      expect(find.byType(MbSpinner), findsOneWidget);
    });

    testWidgets('shows empty message when only currentSeriesId is present', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SeriesRelatedTab(
            related: [
              RelatedSeries(
                relationType: 'sequel',
                series: _series('100', 'Self'),
              ),
            ],
            currentSeriesId: '100',
            l10n: l10n,
          ),
        ),
      );
      expect(find.text(l10n.translate('no_related_series')), findsOneWidget);
    });

    testWidgets('groups related series under relation type headers', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SeriesRelatedTab(
            currentSeriesId: '1',
            l10n: l10n,
            related: [
              RelatedSeries(
                relationType: 'sequel',
                series: _series('2', 'Sequel Title'),
              ),
              RelatedSeries(
                relationType: 'prequel',
                series: _series('3', 'Prequel Title'),
              ),
              RelatedSeries(
                relationType: 'spin_off',
                series: _series('4', 'Spin-off Title'),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('PREQUEL'), findsOneWidget);
      expect(find.text('SEQUEL'), findsOneWidget);
      expect(find.text('SPIN-OFF'), findsOneWidget);
      expect(find.text('Prequel Title'), findsOneWidget);
      expect(find.text('Sequel Title'), findsOneWidget);
      expect(find.text('Spin-off Title'), findsOneWidget);

      // Canonical order: Prequel before Sequel before Spin-off
      final prequelY = tester.getTopLeft(find.text('PREQUEL')).dy;
      final sequelY = tester.getTopLeft(find.text('SEQUEL')).dy;
      final spinOffY = tester.getTopLeft(find.text('SPIN-OFF')).dy;
      expect(prequelY, lessThan(sequelY));
      expect(sequelY, lessThan(spinOffY));
    });
  });
}

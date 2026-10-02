import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/collections/models/edition.dart';
import 'package:mangabaka_app/features/collections/services/collection_service.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';
import 'package:mangabaka_app/features/home/widgets/home_publishers_rail.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/screens/publisher_detail_screen.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCollections extends Fake implements CollectionService {
  int collectionCalls = 0;

  @override
  Future<List<Edition>> fetchEditions() async => const [
        Edition(id: '1', name: 'Omnibus Edition', description: 'Several volumes in one'),
      ];

  @override
  Future<PagedList<SeriesCollection>> fetchPublisherCollections(
    String publisherId, {
    int page = 1,
    int limit = 25,
  }) async {
    collectionCalls++;
    return const PagedList([], hasNext: false);
  }
}

class _FakePublishers extends Fake implements PublisherSearchService {
  bool failStats = false;

  @override
  Future<Publisher> getPublisher(String id) async => Publisher(
        id: id,
        name: 'Shueisha',
        subType: 'both',
        countryOfOrigin: 'JP',
        languages: const ['ja'],
        founded: 1926,
        description: 'The largest publisher in Japan.',
        canonicalUrl: 'https://mangabaka.org/publisher/35/Shueisha',
        aliases: [
          PublisherAlias(language: 'ja', type: 'native', title: '集英社'),
        ],
        imprints: [Publisher(id: '36', name: 'MANGA Plus')],
      );

  @override
  Future<PublisherStats> getStats(String id) async {
    if (failStats) throw Exception('stats down');
    return const PublisherStats(
      seriesCount: 12380,
      averageScore: 66.4,
      firstYear: 1949,
      lastYear: 2026,
      decades: [
        StatBucket(key: '1990', count: 2418),
        StatBucket(key: '2000', count: 2375),
      ],
      knownFor: [
        StatTag(id: '30', name: 'Sports', count: 842, share: 0.07, catalogShare: 0.02),
      ],
      sharesWith: [
        SharedPublisher(id: '36', name: 'Viz Media', sharedCount: 99),
      ],
    );
  }

  @override
  Future<List<Series>> getShelf(
    String publisherId,
    PublisherShelf shelf, {
    int limit = 20,
  }) async =>
      const [];

  @override
  Future<List<SimilarPublisher>> getSimilar(String id) async => const [
        SimilarPublisher(id: '32', name: 'Kodansha'),
      ];
}

Future<void> _pump(WidgetTester tester, _FakePublishers fake) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  getIt.registerSingleton<PublisherSearchService>(fake);
  await tester.pumpWidget(
    const MaterialApp(home: PublisherDetailScreen(publisherId: '35')),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
    await resetServiceLocator();
    LocalizationService.resetForTesting();
    await LocalizationService().init();
  });

  testWidgets('shows the record, stats and similar publishers', (tester) async {
    await _pump(tester, _FakePublishers());

    expect(find.text('Shueisha'), findsWidgets);
    expect(find.text('The largest publisher in Japan.'), findsOneWidget);
    expect(find.text('集英社'), findsOneWidget);
    expect(find.text('MANGA PLUS'), findsOneWidget);
    expect(find.text('12,380'), findsOneWidget);
    expect(find.text('1949–2026'), findsOneWidget);
    expect(find.text('1990s'), findsOneWidget);
    expect(find.text('Sports'), findsOneWidget);
    expect(find.text('VIZ MEDIA'), findsOneWidget);
    expect(find.text('KODANSHA'), findsOneWidget);
  });

  testWidgets('a stats failure leaves the rest of the page up', (tester) async {
    await _pump(tester, _FakePublishers()..failStats = true);

    expect(find.text('The largest publisher in Japan.'), findsOneWidget);
    expect(find.text('KODANSHA'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('12,380'), findsNothing);
  });

  group('SeriesPublisher', () {
    test('parses id, language and role from a series payload', () {
      final ref = SeriesPublisher.tryParse({
        'id': 4874,
        'name': 'LINE Webtoon',
        'canonical_url': 'https://mangabaka.org/publisher/4874/LINE-Webtoon',
        'language': 'en',
        'note': null,
        'type': 'English',
      });
      expect(ref!.id, '4874');
      expect(ref.language, 'en');
      expect(ref.role, 'English');
    });

    test('skips entries with no name', () {
      expect(SeriesPublisher.tryParse({'id': 1, 'name': ''}), isNull);
      expect(SeriesPublisher.tryParse('nope'), isNull);
    });
  });

  testWidgets('the home rail lists publishers and hides when empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePublishersRail(
            loader: () async => [
              Publisher(id: '35', name: 'Shueisha', seriesCount: 12380),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Shueisha'), findsOneWidget);
    expect(find.text('12,380 series'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePublishersRail(key: UniqueKey(), loader: () async => []),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Shueisha'), findsNothing);
  });

  group('desktop layout', () {
    tearDown(() => DesktopLayout.debugOverride = null);

    for (final width in [1400.0, 1050.0]) {
      testWidgets('lays out without overflow at ${width.toInt()}px', (tester) async {
        DesktopLayout.debugOverride = true;
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        getIt.registerSingleton<PublisherSearchService>(_FakePublishers());
        await tester.pumpWidget(
          const MaterialApp(home: PublisherDetailScreen(publisherId: '35')),
        );
        await tester.pump();
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('The largest publisher in Japan.'), findsOneWidget);
        expect(find.text('12,380'), findsOneWidget);
        expect(find.text('KODANSHA'), findsOneWidget);
      });
    }
  });

  group('tabs', () {
    tearDown(() => DesktopLayout.debugOverride = null);

    for (final desktop in [false, true]) {
      testWidgets('switch the content in place (${desktop ? 'desktop' : 'mobile'})',
          (tester) async {
        DesktopLayout.debugOverride = desktop;
        tester.view.physicalSize = Size(desktop ? 1400 : 900, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final collections = _FakeCollections();
        getIt.registerSingleton<CollectionService>(collections);
        getIt.registerSingleton<PublisherSearchService>(_FakePublishers());
        await tester.pumpWidget(
          const MaterialApp(home: PublisherDetailScreen(publisherId: '35')),
        );
        await tester.pump();
        await tester.pump();

        // Info is the default tab; collections have not been requested.
        expect(find.text('The largest publisher in Japan.'), findsOneWidget);
        expect(collections.collectionCalls, 0);

        await tester.tap(find.text('COLLECTIONS'));
        await tester.pump();
        await tester.pump();
        expect(collections.collectionCalls, 1);
        expect(find.text('No collections available.'), findsOneWidget);
        // Mobile swaps the About card out; desktop keeps its identity card.
        if (!desktop) expect(find.text('The largest publisher in Japan.'), findsNothing);
        expect(find.byType(PublisherDetailScreen), findsOneWidget);

        await tester.tap(find.text('EDITIONS'));
        await tester.pump();
        await tester.pump();
        expect(find.text('OMNIBUS EDITION'), findsOneWidget);

        await tester.tap(find.text('INFO'));
        await tester.pump();
        expect(find.text('The largest publisher in Japan.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}

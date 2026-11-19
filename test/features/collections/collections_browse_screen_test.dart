import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/collections/models/edition.dart';
import 'package:mangabaka_app/features/collections/screens/collections_browse_screen.dart';
import 'package:mangabaka_app/features/collections/services/collection_service.dart';
import 'package:mangabaka_app/features/collections/widgets/collection_card.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCollections extends Fake implements CollectionService {
  final int pages;
  final int perPage;
  final List<int> requested = [];

  _FakeCollections({required this.pages, required this.perPage});

  @override
  Future<List<Edition>> fetchEditions() async => const [
    Edition(id: '1', name: 'Standard Edition', description: 'The usual one'),
  ];

  @override
  Future<PagedList<SeriesCollection>> fetchPublisherCollections(
    String publisherId, {
    int page = 1,
    int limit = 25,
  }) async {
    requested.add(page);
    return PagedList([
      for (var i = 0; i < perPage; i++)
        SeriesCollection(
          id: '$page-$i',
          title: 'Collection $page-$i',
          format: 'tankobon',
          type: 'manga',
          status: 'ongoing',
          medium: 'print',
          publisherName: 'Publisher',
          editionName: 'Standard Edition',
          countMain: 3,
        ),
    ], hasNext: page < pages);
  }
}

class _FakePublisherSearch extends Fake implements PublisherSearchService {}

final _publisher = Publisher(
  id: '7',
  type: 'company',
  subType: 'publisher',
  aliases: const [],
  name: 'Publisher',
);

void main() {
  late _FakeCollections collections;

  Future<void> pumpScreen(
    WidgetTester tester, {
    required int pages,
    required int perPage,
    Size size = const Size(900, 700),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    collections = _FakeCollections(pages: pages, perPage: perPage);
    getIt.registerSingleton<CollectionService>(collections);
    getIt.registerSingleton<PublisherSearchService>(_FakePublisherSearch());

    await tester.pumpWidget(
      MaterialApp(
        home: CollectionsBrowseScreen(initialPublisher: _publisher),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
    await resetServiceLocator();
    DesktopLayout.debugOverride = false;
  });

  tearDown(() async {
    DesktopLayout.debugOverride = null;
    await resetServiceLocator();
  });

  group('collections list', () {
    testWidgets('has no "load more" button', (tester) async {
      await pumpScreen(tester, pages: 3, perPage: 10);
      expect(find.text('LOAD_MORE'), findsNothing);
      expect(find.text('load_more'), findsNothing);
      expect(find.widgetWithText(TextButton, 'LOAD_MORE'), findsNothing);
    });

    testWidgets('loads the next page as the end comes into view',
        (tester) async {
      await pumpScreen(tester, pages: 3, perPage: 10);
      // 10 cards fill well over a 700px window, so only page 1 is needed yet.
      expect(collections.requested, [1]);

      await tester.drag(find.byType(ListView).first, const Offset(0, -20000));
      await tester.pumpAndSettle();

      expect(collections.requested, contains(2));
    });

    testWidgets('keeps loading while a short page leaves the window unfilled',
        (tester) async {
      await pumpScreen(tester, pages: 4, perPage: 1);
      await tester.pumpAndSettle();

      expect(collections.requested, [1, 2, 3, 4]);
      expect(find.byType(CollectionCard), findsNWidgets(4));
    });

    testWidgets('stops when the last page is reached', (tester) async {
      await pumpScreen(tester, pages: 2, perPage: 3);
      await tester.pumpAndSettle();

      expect(collections.requested, [1, 2]);
      await tester.drag(find.byType(ListView).first, const Offset(0, -5000));
      await tester.pumpAndSettle();
      expect(collections.requested, [1, 2]);
    });

    testWidgets('builds only the visible cards of a long list',
        (tester) async {
      await pumpScreen(tester, pages: 1, perPage: 60);
      expect(find.byType(CollectionCard).evaluate().length, lessThan(30));
    });
  });

  group('desktop tabs', () {
    setUp(() => DesktopLayout.debugOverride = true);

    testWidgets('switching crossfades and keeps both tabs mounted',
        (tester) async {
      await pumpScreen(
        tester,
        pages: 1,
        perPage: 2,
        size: const Size(1300, 800),
      );

      expect(find.byType(TabBarView), findsNothing);
      expect(find.text('Collection 1-0'), findsOneWidget);
      final editions = find.text('STANDARD EDITION');
      expect(editions, findsOneWidget);
      final hiddenOpacity = tester
          .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
          .map((o) => o.opacity);
      expect(hiddenOpacity, contains(0));

      await tester.tap(find.text('EDITIONS'));
      await tester.pump(const Duration(milliseconds: 100));
      final midOpacity = tester
          .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
          .map((o) => o.opacity)
          .toList();
      expect(midOpacity, containsAll([0, 1]));

      await tester.pumpAndSettle();
      final blocked = tester
          .widgetList<IgnorePointer>(find.byType(IgnorePointer))
          .where((p) => p.ignoring)
          .length;
      expect(blocked, greaterThan(0));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/features/browse/widgets/results/browse_content.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_list_item.dart';
import 'package:mangabaka_app/features/staff/models/staff.dart';
import 'package:mangabaka_app/features/staff/widgets/staff_list_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

Publisher _publisher(int i) => Publisher(
  id: '$i',
  type: 'company',
  subType: 'publisher',
  aliases: const [],
  name: 'Publisher $i',
  founded: 1990,
  description: 'A publisher of comics.',
);

Widget _content(BrowseType type, List<dynamic> results) {
  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          BrowseContent(
            searchResults: results,
            browseType: type,
            isLoading: false,
            isLoadingMore: false,
            error: null,
            scrollController: ScrollController(),
            onRetry: () {},
            onNavigateToDetail: (_) {},
            onNavigateToResults: (_, __, {type, staff, publisher}) {},
            onNavigateToMix: () {},
            onNavigateToDiscoveryQueue: () {},
          ),
        ],
      ),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
    await resetServiceLocator();
  });

  tearDown(() => DesktopLayout.debugOverride = null);

  group('list items', () {
    testWidgets('a publisher has no icon tile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PublisherListItem(publisher: _publisher(1), onTap: () {}),
          ),
        ),
      );
      expect(find.text('Publisher 1'), findsOneWidget);
      expect(find.byIcon(Icons.business_rounded), findsNothing);
    });

    testWidgets('a person with no photo gets no stand-in glyph',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffListItem(staff: Staff(id: 1, name: 'Akira Toriyama')),
          ),
        ),
      );
      expect(find.text('Akira Toriyama'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsNothing);
      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.leading, isNull);
    });
  });

  group('results layout', () {
    testWidgets('desktop shows publishers as a grid of cards', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      DesktopLayout.debugOverride = true;

      await tester.pumpWidget(
        _content(BrowseType.publishers, [for (var i = 0; i < 6; i++) _publisher(i)]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      final first = tester.getRect(find.byType(PublisherListItem).at(0));
      final second = tester.getRect(find.byType(PublisherListItem).at(1));
      expect(second.top, first.top);
      expect(first.width, lessThanOrEqualTo(460));
    });

    testWidgets('desktop shows staff as a grid too', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      DesktopLayout.debugOverride = true;

      await tester.pumpWidget(
        _content(BrowseType.staff, [
          for (var i = 0; i < 6; i++) Staff(id: i, name: 'Person $i', seriesCount: i),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(StaffListItem), findsWidgets);
    });

    testWidgets('the phone keeps the vertical list', (tester) async {
      DesktopLayout.debugOverride = false;

      await tester.pumpWidget(
        _content(BrowseType.publishers, [for (var i = 0; i < 3; i++) _publisher(i)]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}

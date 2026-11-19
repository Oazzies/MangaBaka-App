import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/screens/browse_screen.dart';
import 'package:mangabaka_app/features/browse/widgets/browse_type_tabs.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/filter_chips_row.dart';
import 'package:mangabaka_app/features/browse/widgets/search/mb_search_bar.dart';
import 'package:mangabaka_app/features/browse/widgets/shortcuts/browse_shortcuts.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';

class MockSeriesSearchService extends Fake implements SeriesSearchService {
  @override
  Future<List<Map<String, dynamic>>> getGenres() async => [];
  @override
  Future<List<Map<String, dynamic>>> getTags() async => [];
}

class MockProfileAuthService extends Fake implements ProfileAuthService {
  @override
  bool get isLoggedIn => false;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

class MockMetadataService extends Fake implements MetadataService {
  @override
  String getGenreLabel(String value) => value;
  @override
  String getTagName(int id) => 'Tag $id';
}

class MockPublisherSearchService extends Fake implements PublisherSearchService {
  @override
  Future<PublisherSearchResult> search(Map<String, dynamic> params) async {
    return PublisherSearchResult(publishers: [], total: 0);
  }
}

class MockSeriesService extends Fake implements SeriesService {}

class MockLibraryService extends Fake implements LibraryService {}


void main() {
  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
    SharedPreferences.setMockInitialValues({});
    await resetServiceLocator();
    await SettingsManager().init();
    
    getIt.registerSingleton<LoggingService>(LoggingService());
    getIt.registerSingleton<SeriesSearchService>(MockSeriesSearchService());
    getIt.registerSingleton<ProfileAuthService>(MockProfileAuthService());
    getIt.registerSingleton<MetadataService>(MockMetadataService());
    getIt.registerSingleton<PublisherSearchService>(MockPublisherSearchService());
    getIt.registerSingleton<SeriesService>(MockSeriesService());
    getIt.registerSingleton<LibraryService>(MockLibraryService());
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: BrowseScreen(),
    );
  }

  testWidgets('BrowseScreen renders search bar and shortcuts', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(BrowseShortcuts), findsOneWidget);

    expect(find.byType(MBSearchBar), findsNothing);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();

    expect(find.byType(MBSearchBar), findsOneWidget);
  });

  testWidgets('Typing in search bar updates state', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'One Piece');
    await tester.pump();

    expect(find.text('One Piece'), findsOneWidget);
  });

  testWidgets('a filter disables the type tabs instead of removing them', (
    tester,
  ) async {
    final key = GlobalKey<BrowseScreenState>();
    await tester.pumpWidget(MaterialApp(home: BrowseScreen(key: key)));

    key.currentState!.enterSearchMode();
    key.currentState!.controller.updateFilters(
      SearchFilters(genre: const ['action']),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(BrowseTypeTabs), findsOneWidget);
    expect(find.byType(FilterChipsRow), findsOneWidget);

    await tester.tap(find.text('PUBLISHERS'));
    await tester.pump();
    expect(key.currentState!.controller.currentType, BrowseType.series);
  });
}

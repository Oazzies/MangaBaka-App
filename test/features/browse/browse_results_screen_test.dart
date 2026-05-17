import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';
import 'package:mangabaka_app/features/browse/widgets/browse_results_status_widgets.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/services/series_id_service.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';

import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';

class MockSeriesSearchService extends Fake implements SeriesSearchService {
  List<Series> response = [];
  bool wasCalled = false;
  bool shouldFail = false;

  @override
  Future<SeriesSearchResult> searchSeries(String query, {String? sortBy, String? type, Map<String, dynamic>? extraParams}) async {
    wasCalled = true;
    if (shouldFail) throw Exception('Search failed');
    return SeriesSearchResult(series: response, total: response.length);
  }

  @override
  Future<List<Series>> searchSeriesByName(String query, {String? sortBy, String? type, Map<String, dynamic>? extraParams}) async {
    wasCalled = true;
    if (shouldFail) throw Exception('Search failed');
    return response;
  }
}

class MockProfileAuthService extends Fake implements ProfileAuthService {
  @override
  bool get isLoggedIn => false;
}

class MockSeriesService extends Fake implements SeriesService {
  @override
  Future<Series> fetchSeries(String id) async => Series.fromJson({'id': id, 'title': 'Mock'});
}

class MockPublisherSearchService extends Fake implements PublisherSearchService {
  @override
  Future<PublisherSearchResult> search(Map<String, dynamic> params) async {
    return PublisherSearchResult(publishers: [], total: 0);
  }
}

class MockLibraryService extends Fake implements LibraryService {
  @override
  Stream<LibraryEntry?> watchEntryFromDb(String id) => Stream.value(null);
}

void main() {
  late MockSeriesSearchService mockSearchService;

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
    mockSearchService = MockSeriesSearchService();
    getIt.registerSingleton<SeriesSearchService>(mockSearchService);
    getIt.registerSingleton<ProfileAuthService>(MockProfileAuthService());
    getIt.registerSingleton<SeriesService>(MockSeriesService());
    getIt.registerSingleton<PublisherSearchService>(MockPublisherSearchService());
    getIt.registerSingleton<LibraryService>(MockLibraryService());
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: BrowseResultsScreen(sortType: 'Test Search', sortBy: 'test'),
    );
  }

  testWidgets('BrowseResultsScreen renders title and results', (WidgetTester tester) async {
    mockSearchService.response = [
      Series.fromJson({'id': '1', 'title': 'Result 1'}),
    ];

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Test Search'), findsOneWidget);
    expect(find.text('Result 1'), findsAtLeast(1));
  });

  testWidgets('BrowseResultsScreen shows loading state initially', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byType(BrowseResultsLoading), findsOneWidget);
    await tester.pumpAndSettle(); // Resolve pending timers from initState fetch
  });

  testWidgets('BrowseResultsScreen shows empty state when no results found', (WidgetTester tester) async {
    mockSearchService.response = [];

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(BrowseResultsEmpty), findsOneWidget);
  });

  testWidgets('BrowseResultsScreen shows error state and allows retry', (WidgetTester tester) async {
    mockSearchService.shouldFail = true;

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(BrowseResultsError), findsOneWidget);
    
    // Test retry
    mockSearchService.shouldFail = false;
    mockSearchService.response = [Series.fromJson({'id': '1', 'title': 'Result 1'})];
    
    await tester.tap(find.text('retry'));
    await tester.pumpAndSettle();

    expect(mockSearchService.wasCalled, isTrue);
    expect(find.text('Result 1'), findsAtLeast(1));
  });

  testWidgets('BrowseResultsScreen triggers pagination on scroll', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.reset());

    mockSearchService.response = List.generate(20, (i) => Series.fromJson({
      'id': '$i',
      'title': 'Result $i',
    }));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    mockSearchService.wasCalled = false;
    
    final scrollableFinder = find.byType(Scrollable);
    await tester.runAsync(() async {
      await tester.fling(scrollableFinder, const Offset(0, -1000), 1000);
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    
    expect(mockSearchService.wasCalled, isTrue);
  });

  testWidgets('BrowseResultsScreen shows back to top button after scrolling', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.reset());

    mockSearchService.response = List.generate(20, (i) => Series.fromJson({
      'id': '$i',
      'title': 'Result $i',
    }));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_upward), findsNothing);

    final scrollableFinder = find.byType(Scrollable);
    await tester.runAsync(() async {
      await tester.fling(scrollableFinder, const Offset(0, -1000), 1000);
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    
    await tester.runAsync(() async {
      await tester.tap(find.byType(FloatingActionButton));
    });
    await tester.pumpAndSettle();
    
    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    expect(scrollable.position.pixels, 0.0);
  });
}

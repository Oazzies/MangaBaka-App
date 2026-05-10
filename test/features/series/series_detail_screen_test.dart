import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/services/series_id_service.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/database/database.dart';
import 'package:drift/native.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/models/series_link.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_skeleton.dart';
import 'package:mangabaka_app/features/series/models/series_cover.dart';
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';
import 'package:mangabaka_app/features/series/models/series_work.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';

class MockSeriesService extends Fake implements SeriesService {
  Series? seriesResponse;
  Object? error;
  bool fetchSeriesCalled = false;
  bool fetchCoversCalled = false;
  bool delayFetch = false;

  @override
  Future<List<SeriesLink>> fetchSeriesLinks(String id) async => [];
  
  @override
  Future<Series> fetchSeries(String id) async {
    fetchSeriesCalled = true;
    if (delayFetch) await Future.delayed(const Duration(milliseconds: 100));
    if (error != null) throw error!;
    return seriesResponse ?? Series.fromJson({
      'id': id, 
      'title': 'Fetched Title',
      'description': 'Fetched Description',
    });
  }
  
  @override
  get logger => LoggingService.logger;

  @override
  Future<List<SeriesCover>> fetchSeriesCovers(String id) async {
    fetchCoversCalled = true;
    return [];
  }
  
  @override
  Future<List<Series>> fetchSeriesRelated(String id) async => [];
  @override
  Future<List<News>> fetchSeriesNews(String id) async => [];
  @override
  Future<List<SeriesCollection>> fetchSeriesCollections(String id) async => [];
  @override
  Future<List<SeriesWork>> fetchSeriesWorks(String id) async => [];
}

class MockLibraryService extends Fake implements LibraryService {
  final _controller = StreamController<LibraryEntry?>.broadcast(sync: true);
  LibraryEntry? currentEntry;
  bool createCalled = false;
  bool deleteCalled = false;

  @override
  Stream<LibraryEntry?> watchEntryFromDb(String id) {
    return Stream.multi((controller) {
      controller.add(currentEntry);
      final sub = _controller.stream.listen(controller.add);
      controller.onCancel = () => sub.cancel();
    }, isBroadcast: true);
  }

  @override
  Future<void> createLibraryEntry(String id, String status) async {
    createCalled = true;
    currentEntry = LibraryEntry(
      id: id,
      state: status,
      series: Series.fromJson({'id': id, 'title': 'Test Manga'}),
    );
    _controller.add(currentEntry);
  }
  
  @override
  Future<void> deleteEntry(String id) async {
    deleteCalled = true;
    currentEntry = null;
    _controller.add(null);
  }
}

class MockProfileAuthService extends ChangeNotifier implements ProfileAuthService {
  bool _isLoggedIn = false;
  @override
  bool get isLoggedIn => _isLoggedIn;
  set isLoggedIn(bool value) {
    _isLoggedIn = value;
    notifyListeners();
  }
  @override
  MbProfile? get cachedProfile => null;
  
  @override
  Future<void> init() async {}
  @override
  Future<void> login() async {}
  @override
  Future<void> logout() async {}
  @override
  Future<bool> hasSession() async => _isLoggedIn;
  @override
  Future<MbProfile> fetchProfile({bool forceRefresh = false}) async => MbProfile(id: '1', role: 'user', scopes: []);
  @override
  Future<String> getValidAccessToken() async => 'token';
}

void main() {
  late MockSeriesService mockSeriesService;
  late MockLibraryService mockLibraryService;
  late MockProfileAuthService mockAuthService;
  AppDatabase? db;

  final testSeries = Series.fromJson({
    'id': '123',
    'title': 'Test Manga',
    'native_title': 'Native',
    'description': 'Description',
  });

  setUp(() async {
    await resetServiceLocator();
    SharedPreferences.setMockInitialValues({});
    mockSeriesService = MockSeriesService();
    mockLibraryService = MockLibraryService();
    mockAuthService = MockProfileAuthService();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    
    getIt.registerSingleton<LoggingService>(LoggingService());
    getIt.registerSingleton<AppDatabase>(db!);
    getIt.registerSingleton<SeriesService>(mockSeriesService);
    getIt.registerSingleton<LibraryService>(mockLibraryService);
    getIt.registerSingleton<ProfileAuthService>(mockAuthService);
    getIt.registerSingleton<MetadataService>(MetadataService());
    getIt.registerSingleton<SeriesSearchService>(SeriesSearchService());
  });

  tearDown(() async {
    await db?.close();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: SeriesDetailScreen(series: testSeries),
    );
  }

  testWidgets('SeriesDetailScreen shows skeleton while loading', (WidgetTester tester) async {
    mockSeriesService.delayFetch = true;
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    expect(find.byType(SeriesDetailSkeleton), findsAtLeast(1));
    
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.byType(SeriesDetailSkeleton), findsNothing);
  });

  testWidgets('SeriesDetailScreen renders fetched info on success', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
    expect(find.text('Fetched Title'), findsAtLeast(1));
  });

  testWidgets('SeriesDetailScreen shows error banner on fetch failure', (WidgetTester tester) async {
    mockSeriesService.error = Exception('Network error');
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
    expect(find.text('failed_to_load'), findsOneWidget);
    
    mockSeriesService.error = null;
    await tester.tap(find.text('retry'));
    await tester.pumpAndSettle();
    expect(mockSeriesService.fetchSeriesCalled, isTrue);
  });

  testWidgets('SeriesDetailScreen allows adding to library when logged in', (WidgetTester tester) async {
    mockAuthService.isLoggedIn = true;
    
    // Set a large viewport for widget tests
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    await tester.pump();
    addTearDown(() => tester.view.reset());
    
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
    
    final fabFinder = find.byKey(const Key('add_to_library_fab'));
    expect(fabFinder, findsOneWidget);
    expect(tester.widget<FloatingActionButton>(fabFinder).onPressed, isNotNull);
    
    // Use standard tap instead of tapAt to be more robust
    await tester.tap(fabFinder);
    await tester.pump();
    await tester.pumpAndSettle();
    
    expect(mockLibraryService.createCalled, isTrue);
  });

  testWidgets('SeriesDetailScreen fetches tab data when switching tabs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.reset());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
    
    final iconFinder = find.byIcon(Icons.image_outlined);
    await tester.ensureVisible(iconFinder);
    await tester.pumpAndSettle();
    
    await tester.tap(iconFinder);
    await tester.pumpAndSettle();
    expect(mockSeriesService.fetchCoversCalled, isTrue);
  });
}

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

class MockSeriesService extends Fake implements SeriesService {
  @override
  Future<List<SeriesLink>> fetchSeriesLinks(String id) async => [];
  @override
  Future<Series> fetchSeries(String id) async => Series.fromJson({
    'id': id, 
    'title': 'Fetched Title',
    'description': 'Fetched Description',
  });
  @override
  dynamic get logger => LoggingService.logger;
}

class MockLibraryService extends Fake implements LibraryService {
  @override
  Stream<LibraryEntry?> watchEntryFromDb(String id) => Stream<LibraryEntry?>.empty().asBroadcastStream();
}

class MockProfileAuthService extends Fake implements ProfileAuthService {
  @override
  bool get isLoggedIn => false;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

void main() {
  final testSeries = Series.fromJson({
    'id': '123',
    'title': 'Test Manga',
    'native_title': 'Native',
    'description': 'Description',
  });

  setUp(() async {
    await resetServiceLocator();
    SharedPreferences.setMockInitialValues({});
    getIt.registerSingleton<LoggingService>(LoggingService());
    getIt.registerSingleton<AppDatabase>(AppDatabase.forTesting(NativeDatabase.memory()));
    getIt.registerSingleton<SeriesService>(MockSeriesService());
    getIt.registerSingleton<LibraryService>(MockLibraryService());
    getIt.registerSingleton<ProfileAuthService>(MockProfileAuthService());
    getIt.registerSingleton<MetadataService>(MetadataService());
    getIt.registerSingleton<SeriesSearchService>(SeriesSearchService());
  });

  testWidgets('SeriesDetailScreen renders basic info', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SeriesDetailScreen(series: testSeries),
    ));

    // Initially might show skeleton or the passed series data
    expect(find.text('Test Manga'), findsAtLeast(1));
    
    // Wait for the async fetch to complete
    await tester.pump(); // Start fetch
    await tester.pump(const Duration(seconds: 1)); // Wait for fetch
    await tester.pumpAndSettle(); // Handle animations
    
    // Now it should show the fetched title (from our mock) or the original if we didn't change it
    // Our mock returns "Fetched Title"
    expect(find.text('Fetched Title'), findsAtLeast(1));
    expect(find.text('Fetched Description'), findsAtLeast(1));
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/browse/controllers/browse_controller.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';

class MockSeriesSearchService extends Fake implements SeriesSearchService {
  List<Series> mockResults = [];
  bool throwError = false;

  @override
  Future<List<Series>> searchSeriesByName(String query, {String? sortBy, String? type, Map<String, dynamic>? extraParams}) async {
    if (throwError) throw Exception('Search failed');
    return mockResults;
  }
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
  late BrowseController controller;
  late MockSeriesSearchService mockSearchService;

  setUp(() async {
    await resetServiceLocator();
    mockSearchService = MockSeriesSearchService();
    getIt.registerSingleton<SeriesSearchService>(mockSearchService);
    getIt.registerSingleton<ProfileAuthService>(MockProfileAuthService());
    
    // We need to initialize SettingsManager if needed, but it's a singleton.
    // In a real test we might want to mock SharedPreferences.
    
    controller = BrowseController();
  });

  group('BrowseController', () {
    test('initial state is empty', () {
      expect(controller.searchResults, isEmpty);
      expect(controller.isLoading, isFalse);
      expect(controller.error, isNull);
    });

    test('searchSeries updates results on success', () async {
      final mockSeries = Series(
        id: '1',
        title: 'Test Manga',
        state: '',
        nativeTitle: '',
        romanizedTitle: '',
        secondaryTitles: [],
        coverUrl: '',
        rawCoverUrl: '',
        authors: [],
        artists: [],
        description: '',
        year: '',
        status: '',
        isLicensed: '',
        hasAnime: '',
        contentRating: '',
        type: '',
        rating: '',
        finalVolume: '',
        totalChapters: '',
        links: [],
        publishers: [],
        genres: [],
        tags: [],
        lastUpdated: '',
      );
      mockSearchService.mockResults = [mockSeries];

      controller.updateSearchQuery('test');
      await controller.searchSeries();

      expect(controller.searchResults, hasLength(1));
      expect(controller.searchResults.first.title, 'Test Manga');
      expect(controller.isLoading, isFalse);
    });

    test('searchSeries sets error on failure', () async {
      mockSearchService.throwError = true;

      controller.updateSearchQuery('test');
      await controller.searchSeries();

      expect(controller.searchResults, isEmpty);
      expect(controller.error, contains('Exception: Search failed'));
      expect(controller.isLoading, isFalse);
    });

    test('cleanTitle removes volume and edition noise', () {
      expect(controller.cleanTitle('One Piece Vol. 100'), 'One Piece');
      expect(controller.cleanTitle('Naruto Volume 1'), 'Naruto');
      expect(controller.cleanTitle('Bleach (Manga)'), 'Bleach');
      expect(controller.cleanTitle('Attack on Titan Deluxe Edition'), 'Attack on Titan');
      expect(controller.cleanTitle('Spy x Family - Part 1'), 'Spy x Family');
    });

    test('resetSearchState clears everything', () {
      controller.updateSearchQuery('test');
      controller.resetSearchState();

      expect(controller.currentSearchQuery, isEmpty);
      expect(controller.searchResults, isEmpty);
      expect(controller.error, isNull);
    });
  });
}

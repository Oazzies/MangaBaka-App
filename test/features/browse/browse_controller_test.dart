import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/browse/controllers/browse_controller.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/browse/utils/browse_helpers.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';

class MockSeriesSearchService extends Fake implements SeriesSearchService {
  List<Series> mockResults = [];
  bool throwError = false;

  /// When set, takes over responses entirely (used to simulate slow/overlapping
  /// requests).
  Future<SeriesSearchResult> Function(String query)? onSearch;

  @override
  Future<SeriesSearchResult> searchSeries(String query, {String? sortBy, String? type, Map<String, dynamic>? extraParams}) async {
    if (onSearch != null) return onSearch!(query);
    if (throwError) throw Exception('Search failed');
    return SeriesSearchResult(series: mockResults, total: mockResults.length);
  }

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
  MbProfile? get cachedProfile => null;
  
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

class MockPublisherSearchService extends Fake implements PublisherSearchService {
  @override
  Future<PublisherSearchResult> search(Map<String, dynamic> params) async {
    return PublisherSearchResult(publishers: [], total: 0);
  }
}

void main() {
  late BrowseController controller;
  late MockSeriesSearchService mockSearchService;

  setUp(() async {
    await resetServiceLocator();
    mockSearchService = MockSeriesSearchService();
    getIt.registerSingleton<SeriesSearchService>(mockSearchService);
    getIt.registerSingleton<ProfileAuthService>(MockProfileAuthService());
    getIt.registerSingleton<PublisherSearchService>(MockPublisherSearchService());
    
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
      expect(BrowseHelpers.cleanTitle('One Piece Vol. 100'), 'One Piece');
      expect(BrowseHelpers.cleanTitle('Naruto Volume 1'), 'Naruto');
      expect(BrowseHelpers.cleanTitle('Bleach (Manga)'), 'Bleach');
      expect(BrowseHelpers.cleanTitle('Attack on Titan Deluxe Edition'), 'Attack on Titan');
      expect(BrowseHelpers.cleanTitle('Spy x Family - Part 1'), 'Spy x Family');
    });

    test('resetSearchState clears everything', () {
      controller.updateSearchQuery('test');
      controller.resetSearchState();

      expect(controller.currentSearchQuery, isEmpty);
      expect(controller.searchResults, isEmpty);
      expect(controller.error, isNull);
    });

    Series makeSeries(String id, String title) => Series(
          id: id,
          title: title,
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

    test('slow results from a superseded search are discarded', () async {
      final slowResponse = Completer<SeriesSearchResult>();
      mockSearchService.onSearch = (query) {
        if (query == 'first') return slowResponse.future;
        return Future.value(
          SeriesSearchResult(series: [makeSeries('2', 'Second')], total: 1),
        );
      };

      // Kick off a search whose response hangs...
      controller.updateSearchQuery('first');
      final firstSearch = controller.searchSeries();

      // ...then start a newer search that completes immediately.
      controller.updateSearchQuery('second');
      await controller.searchSeries();
      expect(controller.searchResults.map((s) => s.title), ['Second']);

      // The old response finally arrives — it must not touch the results.
      slowResponse.complete(
        SeriesSearchResult(series: [makeSeries('1', 'First')], total: 1),
      );
      await firstSearch;

      expect(controller.searchResults.map((s) => s.title), ['Second']);
      expect(controller.isLoading, isFalse);
      expect(controller.error, isNull);
    });

    test('slow error from a superseded search does not surface', () async {
      final slowResponse = Completer<SeriesSearchResult>();
      mockSearchService.onSearch = (query) {
        if (query == 'first') return slowResponse.future;
        return Future.value(
          SeriesSearchResult(series: [makeSeries('2', 'Second')], total: 1),
        );
      };

      controller.updateSearchQuery('first');
      final firstSearch = controller.searchSeries();

      controller.updateSearchQuery('second');
      await controller.searchSeries();

      slowResponse.completeError(Exception('boom'));
      await firstSearch;

      expect(controller.error, isNull);
      expect(controller.searchResults.map((s) => s.title), ['Second']);
    });

    test('in-flight results are discarded after resetSearchState', () async {
      final slowResponse = Completer<SeriesSearchResult>();
      mockSearchService.onSearch = (_) => slowResponse.future;

      controller.updateSearchQuery('query');
      final search = controller.searchSeries();

      controller.resetSearchState();

      slowResponse.complete(
        SeriesSearchResult(series: [makeSeries('1', 'Stale')], total: 1),
      );
      await search;

      expect(controller.searchResults, isEmpty);
    });
  });
}

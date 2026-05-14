import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/series/services/series_id_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/exceptions/app_exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/settings/settings_keys.dart';

void main() {
  group('SeriesFetchMixin Content Rating Filtering', () {
    late SeriesService seriesService;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await resetServiceLocator();
      getIt.registerSingleton<LoggingService>(LoggingService());
      
      SharedPreferences.setMockInitialValues({
        SettingsKeys.contentPreferences: ['safe'],
      });
      await SettingsManager().init();
      seriesService = SeriesService();
    });

    Series createDummySeries({required String id, required String contentRating}) {
      return Series(
        id: id,
        state: '',
        title: 'Series $id',
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
        contentRating: contentRating,
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
    }

    test('fetchSeries returns series when rating is allowed (safe)', () async {
      final series = createDummySeries(id: '1', contentRating: 'safe');
      seriesService.precacheSeries(series);
      
      final result = await seriesService.fetchSeries('1');
      expect(result.id, '1');
      expect(result.contentRating, 'safe');
    });

    test('fetchSeries throws AppException when rating is restricted (suggestive)', () async {
      final series = createDummySeries(id: '2', contentRating: 'suggestive');
      seriesService.precacheSeries(series);
      
      expect(
        () => seriesService.fetchSeries('2'),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'CONTENT_FILTERED')),
      );
    });

    test('fetchSeries allows suggestive when preference is updated', () async {
      // 1. Initial restricted state
      final series = createDummySeries(id: '3', contentRating: 'suggestive');
      seriesService.precacheSeries(series);
      
      // Should throw and remove from cache
      await expectLater(
        () => seriesService.fetchSeries('3'),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'CONTENT_FILTERED')),
      );
      expect(seriesService.cache.containsKey('3'), isFalse);

      // 2. Update preferences
      await SettingsManager().setContentPreferences(['safe', 'suggestive']);
      
      // 3. Re-precache (simulating a fresh fetch or just testing the filtering logic again)
      seriesService.precacheSeries(series);
      
      // 4. Now it should be allowed
      final result = await seriesService.fetchSeries('3');
      expect(result.id, '3');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/series_search_filter.dart';

Series _series({String rating = '0', String contentRating = 'safe'}) =>
    Series.fromJson({
      'id': '1',
      'title': 'A',
      'rating': rating,
      'content_rating': contentRating,
    });

void main() {
  group('SeriesSearchFilter content ratings', () {
    test('an empty preference list permits everything', () {
      const filter = SeriesSearchFilter();
      expect(filter.allows(_series(contentRating: 'explicit')), isTrue);
    });

    test('keeps an allowed rating', () {
      const filter = SeriesSearchFilter(contentPreferences: ['safe']);
      expect(filter.allows(_series(contentRating: 'safe')), isTrue);
    });

    test('drops a rating the user has hidden', () {
      const filter = SeriesSearchFilter(contentPreferences: ['safe']);
      expect(filter.allows(_series(contentRating: 'explicit')), isFalse);
    });

    test('matches the rating case-insensitively', () {
      const filter = SeriesSearchFilter(contentPreferences: ['safe']);
      expect(filter.allows(_series(contentRating: 'Safe')), isTrue);
    });
  });

  group('SeriesSearchFilter score bounds', () {
    test('keeps a score inside the range', () {
      const filter = SeriesSearchFilter(ratingLower: 50, ratingUpper: 90);
      expect(filter.allows(_series(rating: '70')), isTrue);
    });

    test('drops a score below the lower bound', () {
      const filter = SeriesSearchFilter(ratingLower: 50);
      expect(filter.allows(_series(rating: '30')), isFalse);
    });

    test('drops a score above the upper bound', () {
      const filter = SeriesSearchFilter(ratingUpper: 50);
      expect(filter.allows(_series(rating: '80')), isFalse);
    });

    test('bounds take precedence over the sort-by-score rule', () {
      // An explicit range is honoured even when it includes unrated series.
      const filter = SeriesSearchFilter(ratingLower: 0, sortBy: 'score_desc');
      expect(filter.allows(_series(rating: '0')), isTrue);
    });
  });

  group('SeriesSearchFilter unrated series', () {
    test('drops unrated series when sorting by score', () {
      const filter = SeriesSearchFilter(sortBy: 'score_desc');
      expect(filter.allows(_series(rating: '0')), isFalse);
    });

    test('keeps unrated series under any other sort', () {
      const filter = SeriesSearchFilter(sortBy: 'name_asc');
      expect(filter.allows(_series(rating: '0')), isTrue);
    });
  });

  group('SeriesSearchFilter.normalizedRating', () {
    test('scales the 0-10 form up to 0-100', () {
      expect(SeriesSearchFilter.normalizedRating(_series(rating: '8.5')), 85);
    });

    test('leaves a value already on the 0-100 scale alone', () {
      expect(SeriesSearchFilter.normalizedRating(_series(rating: '85')), 85);
    });

    test('treats an unparseable rating as unrated', () {
      expect(SeriesSearchFilter.normalizedRating(_series(rating: 'N/A')), 0);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';

void main() {
  group('SearchFilters', () {
    test('default values are correct', () {
      final filters = SearchFilters();
      expect(filters.type, isEmpty);
      expect(filters.status, isEmpty);
      expect(filters.genre, isEmpty);
      expect(filters.tag, isEmpty);
      expect(filters.sortBy, isNull);
      expect(filters.ratingLower, 0);
      expect(filters.ratingUpper, 100);
      expect(filters.tagMode, 'and');
    });

    test('copyWith updates values correctly', () {
      final filters = SearchFilters();
      final updated = filters.copyWith(
        type: ['manga'],
        sortBy: 'popularity_desc',
        ratingLower: 50,
      );

      expect(updated.type, ['manga']);
      expect(updated.sortBy, 'popularity_desc');
      expect(updated.ratingLower, 50);
      expect(updated.ratingUpper, 100); // Should remain same
    });

    test('toMap generates correct query parameters', () {
      final filters = SearchFilters(
        type: ['manga', 'manhwa'],
        status: ['ongoing'],
        genre: ['action'],
        sortBy: 'name_asc',
        ratingLower: 20,
        ratingUpper: 80,
        publishedYearLower: 2020,
        isLicensed: true,
      );

      final map = filters.toMap();

      expect(map['type'], ['manga', 'manhwa']);
      expect(map['status'], ['ongoing']);
      expect(map['genre'], ['action']);
      expect(map['sort_by'], 'name_asc');
      expect(map['rating_lower'], 20);
      expect(map['rating_upper'], 80);
      expect(map['published_start_date_lower'], '2020');
      expect(map['is_licensed'], true);
    });

    test('toMap excludes empty or default values', () {
      final filters = SearchFilters();
      final map = filters.toMap();

      expect(map.containsKey('type'), isFalse);
      expect(map.containsKey('rating_lower'), isFalse); // Default is 0
      expect(map.containsKey('rating_upper'), isFalse); // Default is 100
    });

    test('toMap adds rating_lower=1 when sorting by community rating if not set', () {
      final filters = SearchFilters(sortBy: 'score_desc');
      final map = filters.toMap();

      expect(map['sort_by'], 'score_desc');
      expect(map['rating_lower'], 1);
    });

    test('toMap respects explicit rating_lower when sorting by community rating', () {
      final filters = SearchFilters(sortBy: 'score_desc', ratingLower: 50);
      final map = filters.toMap();

      expect(map['sort_by'], 'score_desc');
      expect(map['rating_lower'], 50);
    });
  });
}

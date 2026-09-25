import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/utils/json_utils.dart';

void main() {
  group('JsonUtils', () {
    test('getField returns nested value', () {
      final map = {
        'a': {
          'b': {
            'c': 123
          }
        }
      };
      expect(JsonUtils.getField<int>(map, ['a', 'b', 'c']), 123);
    });

    test('getField returns null for missing key', () {
      final map = {
        'a': {
          'b': {}
        }
      };
      expect(JsonUtils.getField<int>(map, ['a', 'b', 'c']), null);
    });

    test('getField returns null for non-map intermediate value', () {
      final map = {
        'a': 123
      };
      expect(JsonUtils.getField<int>(map, ['a', 'b']), null);
    });

    test('getCover extracts x350 x1 cover', () {
      final map = {
        'cover': {
          'x350': {
            'x1': 'https://example.com/cover.jpg'
          }
        }
      };
      expect(JsonUtils.getCover(map), 'https://example.com/cover.jpg');
    });

    test('getCover returns empty string if missing', () {
      final map = {'cover': {}};
      expect(JsonUtils.getCover(map), '');
    });

    test('getRawCover extracts raw url', () {
      final map = {
        'cover': {
          'raw': {
            'url': 'https://example.com/raw.jpg'
          }
        }
      };
      expect(JsonUtils.getRawCover(map), 'https://example.com/raw.jpg');
    });

    test('getRawCover returns empty string if missing', () {
      final map = {'cover': {}};
      expect(JsonUtils.getRawCover(map), '');
    });
  });

  group('JsonUtils numbers', () {
    test('toDouble accepts numbers and numeric strings', () {
      expect(JsonUtils.toDouble(8), 8.0);
      expect(JsonUtils.toDouble(8.5), 8.5);
      expect(JsonUtils.toDouble(' 8.5 '), 8.5);
    });

    test('toDouble returns null for anything else', () {
      expect(JsonUtils.toDouble(null), isNull);
      expect(JsonUtils.toDouble('n/a'), isNull);
      expect(JsonUtils.toDouble(true), isNull);
      expect(JsonUtils.toDouble({'v': 1}), isNull);
    });

    test('normalizedRating reads a source entry and tolerates bad shapes', () {
      expect(JsonUtils.normalizedRating({'rating_normalized': 86}), 86.0);
      expect(JsonUtils.normalizedRating({'rating_normalized': '86'}), 86.0);
      expect(JsonUtils.normalizedRating({'rating_normalized': null}), isNull);
      expect(JsonUtils.normalizedRating('not a map'), isNull);
      expect(JsonUtils.normalizedRating(null), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/utils/uri_utils.dart';

void main() {
  group('UriUtils.encodeQueryParameters', () {
    test('converts scalar values to strings', () {
      final result = UriUtils.encodeQueryParameters({'page': 1, 'limit': 20});
      expect(result['page'], '1');
      expect(result['limit'], '20');
    });

    test('preserves List values as List<String>', () {
      final result = UriUtils.encodeQueryParameters({
        'content_rating': ['safe', 'suggestive'],
      });
      expect(result['content_rating'], ['safe', 'suggestive']);
    });

    test('converts list elements to strings', () {
      final result = UriUtils.encodeQueryParameters({'ids': [1, 2, 3]});
      expect(result['ids'], ['1', '2', '3']);
    });

    test('handles empty map', () {
      final result = UriUtils.encodeQueryParameters({});
      expect(result, isEmpty);
    });

    test('handles empty list value', () {
      final result = UriUtils.encodeQueryParameters({'tags': <String>[]});
      expect(result['tags'], <String>[]);
    });

    test('handles boolean values via toString', () {
      final result = UriUtils.encodeQueryParameters({'strict': true});
      expect(result['strict'], 'true');
    });
  });
}

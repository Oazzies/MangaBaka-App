import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/browse/services/book_lookup_service.dart';

void main() {
  group('BookLookupService', () {
    test('instantiates successfully', () {
      final service = BookLookupService();
      expect(service, isNotNull);
    });
  });
}

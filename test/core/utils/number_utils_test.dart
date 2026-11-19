import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/utils/number_utils.dart';

void main() {
  group('NumberUtils.formatCount', () {
    test('returns exact count for values under 1000', () {
      expect(NumberUtils.formatCount(0), '0');
      expect(NumberUtils.formatCount(500), '500');
      expect(NumberUtils.formatCount(999), '999');
    });

    test('formats thousands with k suffix', () {
      expect(NumberUtils.formatCount(1000), '1k');
      expect(NumberUtils.formatCount(1100), '1.1k');
      expect(NumberUtils.formatCount(1550), '1.6k');
      expect(NumberUtils.formatCount(5000), '5k');
      expect(NumberUtils.formatCount(9999), '10k');
    });

    test('avoids decimals for values >= 10k', () {
      expect(NumberUtils.formatCount(10000), '10k');
      expect(NumberUtils.formatCount(12345), '12k');
      expect(NumberUtils.formatCount(99999), '100k');
    });

    test('formats millions with M suffix', () {
      expect(NumberUtils.formatCount(1000000), '1M');
      expect(NumberUtils.formatCount(1100000), '1.1M');
      expect(NumberUtils.formatCount(1550000), '1.6M');
      expect(NumberUtils.formatCount(5000000), '5M');
    });

    test('avoids decimals for values >= 10M', () {
      expect(NumberUtils.formatCount(10000000), '10M');
      expect(NumberUtils.formatCount(12345678), '12M');
      expect(NumberUtils.formatCount(999999999), '1000M');
    });
  });
}

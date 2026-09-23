import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';

void main() {
  group('parseDataList', () {
    test('skips an item whose parser throws instead of failing the page', () {
      final json = {
        'data': [
          {'id': 1},
          {'id': 'bad'},
          {'id': 3},
        ],
      };

      final ids = parseDataList(json, (item) => item['id'] as int);

      expect(ids, [1, 3]);
    });
  });
}

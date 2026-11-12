import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/features/series/services/mixins/series_metadata_mixin.dart';

class _Host with SeriesMetadataMixin {
  _Host(this._api);
  final ApiClient _api;

  @override
  ApiClient get metadataApi => _api;
}

Map<String, dynamic> _edge(int id, String title) => {
      'id': 'edge-$id',
      'relation_type': 'sequel',
      'is_manual': false,
      'note': null,
      'series': {
        'id': id,
        'title': title,
        'state': 'active',
        'content_rating': 'safe',
      },
    };

void main() {
  group('fetchSeriesRelated', () {
    test('reads the series out of each /relationships edge', () async {
      late Uri requested;
      final host = _Host(ApiClient(
        client: MockClient((request) async {
          requested = request.url;
          return http.Response(
            jsonEncode({
              'status': 200,
              'data': [_edge(1, 'One'), _edge(2, 'Two')],
              'pagination': {'count': 2, 'limit': 50, 'page': 1},
              'counts': {'sequel': 2},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ));

      final related = await host.fetchSeriesRelated('84926');

      expect(requested.path, '/v1/series/84926/relationships');
      expect(requested.queryParameters['limit'], '50');
      expect(related.map((r) => r.series.id), ['1', '2']);
      expect(related.map((r) => r.relationType), ['sequel', 'sequel']);
    });

    test('skips an edge with no series rather than failing the tab', () async {
      final host = _Host(ApiClient(
        client: MockClient((_) async => http.Response(
              jsonEncode({
                'status': 200,
                'data': [
                  {'id': 'broken', 'relation_type': 'sequel'},
                  _edge(3, 'Three'),
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            )),
      ));

      final related = await host.fetchSeriesRelated('1');

      expect(related.map((r) => r.series.id), ['3']);
      expect(related.map((r) => r.relationType), ['sequel']);
    });
  });
}

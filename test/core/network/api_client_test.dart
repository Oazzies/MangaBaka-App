import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';

ApiClient _clientReturning(http.Response response) => ApiClient(
      client: MockClient((_) async => response),
    );

ApiClient _clientThrowing(Object error) => ApiClient(
      client: MockClient((_) async => throw error),
      timeout: const Duration(milliseconds: 50),
    );

void main() {
  group('ApiClient.uri', () {
    test('returns the bare URI when there are no parameters', () {
      expect(ApiClient.uri('https://x.test/a').toString(), 'https://x.test/a');
    });

    test('stringifies scalar values', () {
      final uri = ApiClient.uri('https://x.test/a', {'page': 2, 'ok': true});
      expect(uri.queryParameters['page'], '2');
      expect(uri.queryParameters['ok'], 'true');
    });

    test('repeats a list as multiple parameters', () {
      final uri = ApiClient.uri('https://x.test/a', {
        'series': [1, 2, 3],
      });
      expect(uri.queryParametersAll['series'], ['1', '2', '3']);
    });

    test('drops null, empty strings and empty lists', () {
      final uri = ApiClient.uri('https://x.test/a', {
        'a': null,
        'b': '',
        'c': <String>[],
        'd': 'kept',
      });
      expect(uri.queryParameters.keys, ['d']);
    });
  });

  group('ApiClient.getJson', () {
    test('parses an accepted response', () async {
      final client = _clientReturning(
        http.Response(jsonEncode({'data': [], 'total': 7}), 200),
      );

      final total = await client.getJson(
        Uri.parse('https://x.test/a'),
        operation: 'fetch things',
        parse: totalCount,
      );
      expect(total, 7);
    });

    test('sends a User-Agent', () async {
      String? sentAgent;
      final client = ApiClient(
        client: MockClient((request) async {
          sentAgent = request.headers['User-Agent'];
          return http.Response('{}', 200);
        }),
      );

      await client.getJson(
        Uri.parse('https://x.test/a'),
        operation: 'fetch things',
        parse: (_) => null,
      );
      expect(sentAgent, isNotEmpty);
    });

    test('throws ApiException with the status for an unaccepted response',
        () async {
      final client = _clientReturning(http.Response('nope', 503));

      await expectLater(
        client.getJson(
          Uri.parse('https://x.test/a'),
          operation: 'fetch things',
          parse: (_) => null,
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 503)
            .having((e) => e.responseBody, 'responseBody', 'nope')),
      );
    });

    test('accepts a status the caller opted into', () async {
      final client = _clientReturning(http.Response('{}', 404));

      final result = await client.send(
        Uri.parse('https://x.test/a'),
        operation: 'fetch things',
        acceptedStatuses: const {200, 404},
      );
      expect(result.statusCode, 404);
    });

    test('throws ParseException for a malformed body', () async {
      final client = _clientReturning(http.Response('not json', 200));

      await expectLater(
        client.getJson(
          Uri.parse('https://x.test/a'),
          operation: 'fetch things',
          parse: dataList,
        ),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('ApiClient failure translation', () {
    test('SocketException becomes a NETWORK_ERROR NetworkException', () async {
      final client = _clientThrowing(const SocketException('down'));

      await expectLater(
        client.send(Uri.parse('https://x.test/a'), operation: 'fetch things'),
        throwsA(isA<NetworkException>()
            .having((e) => e.code, 'code', 'NETWORK_ERROR')),
      );
    });

    test('ClientException becomes a NETWORK_ERROR NetworkException', () async {
      final client = _clientThrowing(http.ClientException('boom'));

      await expectLater(
        client.send(Uri.parse('https://x.test/a'), operation: 'fetch things'),
        throwsA(isA<NetworkException>()
            .having((e) => e.code, 'code', 'NETWORK_ERROR')),
      );
    });

    test('a timeout becomes a TIMEOUT NetworkException', () async {
      final client = ApiClient(
        client: MockClient((_) => Future.delayed(
              const Duration(seconds: 5),
              () => http.Response('{}', 200),
            )),
        timeout: const Duration(milliseconds: 20),
      );

      await expectLater(
        client.send(Uri.parse('https://x.test/a'), operation: 'fetch things'),
        throwsA(
          isA<NetworkException>().having((e) => e.code, 'code', 'TIMEOUT'),
        ),
      );
    });

    test('anything else becomes an AppError rather than escaping raw',
        () async {
      final client = _clientThrowing(StateError('unexpected'));

      await expectLater(
        client.send(Uri.parse('https://x.test/a'), operation: 'fetch things'),
        throwsA(isA<AppError>()),
      );
    });
  });

  group('api_envelope', () {
    test('dataList returns the rows', () {
      final rows = dataList({
        'data': [
          {'id': 1},
          {'id': 2},
        ],
      });
      expect(rows, hasLength(2));
      expect(rows.first['id'], 1);
    });

    test('dataList degrades to empty for a missing or wrong-typed field', () {
      expect(dataList({}), isEmpty);
      expect(dataList({'data': 'nope'}), isEmpty);
      expect(dataList('nope'), isEmpty);
    });

    test('dataObject returns null unless data is an object', () {
      expect(dataObject({'data': {'id': 1}}), {'id': 1});
      expect(dataObject({'data': []}), isNull);
      expect(dataObject({}), isNull);
    });

    test('totalCount defaults to zero', () {
      expect(totalCount({'total': 12}), 12);
      expect(totalCount({}), 0);
      expect(totalCount('nope'), 0);
    });

    test('parseDataList skips a row that fails to parse', () {
      final parsed = parseDataList<int>(
        {
          'data': [
            {'n': 1},
            {'n': null},
            {'n': 3},
          ],
        },
        (row) => row['n'] as int?,
      );
      expect(parsed, [1, 3]);
    });
  });
}

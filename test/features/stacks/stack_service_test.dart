import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/stacks/models/stack_draft.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/services/stack_exceptions.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../profile/auth_test_helpers.dart';
import 'stack_fixtures.dart';

void main() {
  late List<http.Request> requests;
  late http.Response Function(http.Request) handler;
  late ProfileAuthService auth;
  late StackService service;
  late int refreshCalls;

  http.Response json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();

    final storage = MemoryAuthStorage();
    seedSession(storage, access: 'old');
    refreshCalls = 0;
    auth = ProfileAuthService(
      storage: storage,
      network: FakeAuthNetwork(),
      refresher: (_) async {
        refreshCalls++;
        return tokens('new', refresh: 'refresh-2');
      },
    );
    await auth.init();

    requests = [];
    handler = (_) => json({'status': 200, 'data': []});
    service = StackService(
      client: MockClient((r) async {
        requests.add(r);
        return handler(r);
      }),
      auth: auth,
    );
  });

  tearDown(resetServiceLocator);

  group('public reads', () {
    test('browse sends paging and parses pagination', () async {
      handler = (_) => json({
        'status': 200,
        'data': [stackSummaryJson(id: 1), stackSummaryJson(id: 2)],
        'pagination': {'count': 30, 'next': 'https://x/?page=2', 'page': 1},
      });
      final page = await service.browse(page: 1, featured: true);
      expect(page.items.map((s) => s.id), [1, 2]);
      expect(page.hasNext, isTrue);
      expect(page.total, 30);
      final uri = requests.single.url;
      expect(uri.path, '/v2/stacks');
      expect(uri.queryParameters['featured'], 'true');
      expect(uri.queryParameters['limit'], '24');
      expect(requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('forSeries sends sort and spoiler filter', () async {
      await service.forSeries(
        '217',
        sort: StackSort.mostSaved,
        spoilers: StackSpoilerFilter.include,
      );
      final uri = requests.single.url;
      expect(uri.path, '/v2/series/217/stacks');
      expect(uri.queryParameters['sort_by'], 'save_count_desc');
      expect(uri.queryParameters['spoilers'], 'include');
    });

    test('a missing stack is a StackApiException 404', () async {
      handler = (_) => json({'status': 404, 'message': 'Not Found'}, 404);
      await expectLater(
        service.fetch(5),
        throwsA(
          isA<StackApiException>()
              .having((e) => e.isNotFound, 'isNotFound', isTrue)
              .having((e) => e.serverMessage, 'serverMessage', 'Not Found'),
        ),
      );
    });
  });

  group('authed calls', () {
    test('status batches ids in chunks of 50 with the bearer token', () async {
      handler = (r) => json({
        'status': 200,
        'data': [
          for (final id in r.url.queryParametersAll['id']!)
            statusJson(int.parse(id)),
        ],
      });
      final result = await service.status(List.generate(60, (i) => i + 1));
      expect(result, hasLength(60));
      expect(requests, hasLength(2));
      expect(requests.first.url.queryParametersAll['id'], hasLength(50));
      expect(requests.first.headers['Authorization'], 'Bearer old');
    });

    test('create posts the draft body', () async {
      handler = (_) => json({'status': 200, 'data': ownerStackDetailJson()});
      final created = await service.create(
        const StackDraft(
          title: '  Best isekai ',
          entries: [StackDraftEntry(seriesId: '217', note: 'yes')],
        ),
      );
      expect(created.token, 'tok-1');
      final r = requests.single;
      expect(r.method, 'POST');
      expect(r.url.path, '/v2/my/stacks');
      final body = jsonDecode(r.body) as Map;
      expect(body['title'], 'Best isekai');
      expect(body['entries'], [
        {'series_id': 217, 'note': 'yes'},
      ]);
      expect(body.containsKey('visibility'), isFalse);
    });

    test('a stale token surfaces as stale_token', () async {
      handler = (_) => json({
        'status': 409,
        'message': 'Conflict',
        'code': 'stale_token',
      }, 409);
      await expectLater(
        service.update(7, const StackDraft(title: 't'), 'tok-0'),
        throwsA(
          isA<StackApiException>().having(
            (e) => e.isStaleToken,
            'isStaleToken',
            isTrue,
          ),
        ),
      );
      expect(jsonDecode(requests.single.body)['token'], 'tok-0');
    });

    test('addEntry omits null rank and rating', () async {
      handler = (_) => json({
        'status': 200,
        'data': {'rank': 6, 'token': 't'},
      });
      final rank = await service.addEntry(7, '42');
      expect(rank, 6);
      final body = jsonDecode(requests.single.body) as Map;
      expect(body, {'series_id': 42});
    });

    test('vote and unvote use PUT and DELETE', () async {
      handler = (_) =>
          json({'status': 200, 'data': statusJson(3, voted: true)});
      final s = await service.vote(3);
      expect(s.hasVoted, isTrue);
      await service.unvote(3);
      expect(requests.map((r) => r.method), ['PUT', 'DELETE']);
      expect(requests.first.url.path, '/v2/my/stacks/votes/3');
    });

    test('a 401 is recovered by refreshing the token', () async {
      handler = (r) => r.headers['Authorization'] == 'Bearer old'
          ? json({'status': 401, 'message': 'Unauthorized'}, 401)
          : json({
              'status': 200,
              'data': [],
              'pagination': {'next': null},
            });
      await service.mine();
      expect(refreshCalls, 1);
      expect(requests.last.headers['Authorization'], 'Bearer new');
    });

    test('rate limiting carries its code', () async {
      handler = (_) => json({
        'status': 429,
        'message': 'Too Many',
        'code': 'rate_limited',
      }, 429);
      await expectLater(
        service.save(1),
        throwsA(
          isA<StackApiException>().having(
            (e) => e.code,
            'code',
            StackErrorCode.rateLimited,
          ),
        ),
      );
    });

    test('signed out never sends a request', () async {
      await auth.logout();
      requests.clear();
      await expectLater(
        service.mine(),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(requests, isEmpty);
    });
  });
}

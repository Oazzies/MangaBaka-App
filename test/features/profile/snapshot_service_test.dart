import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/services/snapshot_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuth extends Fake implements ProfileAuthService {
  String token = 'tok-abc';

  @override
  Future<String> getValidAccessToken() async => token;

  @override
  Future<http.Response> sendAuthorized(
    Future<http.Response> Function(String token) send,
  ) => send(token);
}

Map<String, dynamic> _entryJson(String id, {String contentRating = 'safe'}) {
  return {
    'id': id,
    'state': 'reading',
    'Series': {
      'id': id,
      'title': 'Series $id',
      'native_title': '',
      'romanized_title': '',
      'secondary_titles': {},
      'authors': [],
      'artists': [],
      'description': '',
      'year': '',
      'status': '',
      'is_licensed': false,
      'has_anime': false,
      'content_rating': contentRating,
      'type': '',
      'rating': '',
      'final_volume': '',
      'total_chapters': '',
      'links': [],
      'publishers': [],
      'genres': [],
      'tags': [],
      'last_updated_at': '',
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
  });

  group('SnapshotService.fetchSnapshot', () {
    test('issues authenticated request and parses entries', () async {
      Uri? captured;
      Map<String, String>? capturedHeaders;
      final mockClient = MockClient((req) async {
        captured = req.url;
        capturedHeaders = req.headers;
        return http.Response(
          jsonEncode({'data': [_entryJson('1'), _entryJson('2')]}),
          200,
        );
      });

      final result = await http.runWithClient(
        () => SnapshotService(auth: _FakeAuth()).fetchSnapshot(
          sortBy: 'recent',
          page: 1,
          limit: 10,
        ),
        () => mockClient,
      );

      expect(result, hasLength(2));
      expect(captured!.queryParameters['sort_by'], 'recent');
      expect(captured!.queryParameters['page'], '1');
      expect(captured!.queryParameters['limit'], '10');
      expect(capturedHeaders!['Authorization'], 'Bearer tok-abc');
    });

    test('filters out entries outside contentPreferences', () async {
      final mockClient = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'data': [
              _entryJson('1', contentRating: 'safe'),
              _entryJson('2', contentRating: 'erotica'),
            ],
          }),
          200,
        );
      });

      // Default content prefs include 'safe' and 'suggestive' but not 'erotica'.
      final result = await http.runWithClient(
        () => SnapshotService(auth: _FakeAuth()).fetchSnapshot(sortBy: 'recent'),
        () => mockClient,
      );

      expect(result.map((e) => e.id), ['1']);
    });

    test('throws ApiException on non-200', () async {
      final mockClient = MockClient((_) async => http.Response('err', 500));
      await expectLater(
        http.runWithClient(
          () => SnapshotService(auth: _FakeAuth()).fetchSnapshot(sortBy: 'recent'),
          () => mockClient,
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('wraps unknown errors in NetworkException', () async {
      final mockClient = MockClient((_) async {
        throw Exception('boom');
      });
      await expectLater(
        http.runWithClient(
          () => SnapshotService(auth: _FakeAuth()).fetchSnapshot(sortBy: 'recent'),
          () => mockClient,
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('SnapshotService cache', () {
    test('setCachedActivities + cachedActivities + clearCache', () {
      final svc = SnapshotService(auth: _FakeAuth());
      expect(svc.cachedActivities, isNull);
      svc.setCachedActivities([]);
      expect(svc.cachedActivities, isNotNull);
      svc.clearCache();
      expect(svc.cachedActivities, isNull);
    });
  });
}

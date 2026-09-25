import 'dart:async';
import 'dart:io';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/profile/services/auth/auth_storage.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';

import 'auth_test_helpers.dart';

void main() {
  late MemoryAuthStorage storage;
  late int refreshCalls;

  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
    storage = MemoryAuthStorage();
    refreshCalls = 0;
  });

  ProfileAuthService service(
    Future<TokenResponse?> Function(String refreshToken) refresher,
  ) =>
      ProfileAuthService(
        storage: storage,
        network: FakeAuthNetwork(),
        refresher: (token) {
          refreshCalls++;
          return refresher(token);
        },
      );

  /// A server that accepts only [valid] and answers 401 to anything else.
  Future<http.Response> Function(String) acceptOnly(
    String valid, {
    List<String>? seen,
  }) =>
      (token) async {
        seen?.add(token);
        return http.Response('{}', token == valid ? 200 : 401);
      };

  group('getValidAccessToken', () {
    test('returns the stored token without refreshing while it is valid',
        () async {
      seedSession(storage);
      final auth = service((_) async => tokens('new'));

      expect(await auth.getValidAccessToken(), 'old');
      expect(refreshCalls, 0);
    });

    test('refreshes a token within five minutes of expiry and keeps the '
        'rotated refresh token', () async {
      seedSession(storage, expiresIn: const Duration(minutes: 2));
      final auth = service((_) async => tokens('new', refresh: 'refresh-2'));

      expect(await auth.getValidAccessToken(), 'new');
      expect(refreshCalls, 1);
      expect(storage.values[AuthStorage.kRefreshToken], 'refresh-2');
    });

    test('keeps the old refresh token when the server does not rotate it',
        () async {
      seedSession(storage, expiresIn: Duration.zero);
      final auth = service((_) async => tokens('new'));

      await auth.getValidAccessToken();
      expect(storage.values[AuthStorage.kRefreshToken], 'refresh-1');
    });

    test('throws NOT_LOGGED_IN without a session', () async {
      final auth = service((_) async => tokens('new'));

      await expectLater(
        auth.getValidAccessToken(),
        throwsA(isA<AuthException>()
            .having((e) => e.code, 'code', 'NOT_LOGGED_IN')),
      );
    });
  });

  group('sendAuthorized', () {
    test('passes a non-401 response straight through', () async {
      seedSession(storage);
      final auth = service((_) async => tokens('new'));

      final response = await auth.sendAuthorized(
        (token) async => http.Response('nope', 404),
      );

      expect(response.statusCode, 404);
      expect(refreshCalls, 0);
    });

    test('refreshes after a 401 and retries with the new token', () async {
      // The token is revoked server-side while still valid locally.
      seedSession(storage);
      final auth = service((_) async => tokens('new', refresh: 'refresh-2'));
      final seen = <String>[];

      final response = await auth.sendAuthorized(acceptOnly('new', seen: seen));

      expect(response.statusCode, 200);
      expect(seen, ['old', 'new']);
      expect(refreshCalls, 1);
      expect(storage.values[AuthStorage.kAccessToken], 'new');
    });

    test('concurrent 401s share a single refresh', () async {
      seedSession(storage);
      final release = Completer<void>();
      final auth = service((_) async {
        await release.future;
        return tokens('new', refresh: 'refresh-2');
      });

      final requests = [
        for (var i = 0; i < 3; i++) auth.sendAuthorized(acceptOnly('new')),
      ];
      await Future<void>.delayed(Duration.zero);
      release.complete();
      final responses = await Future.wait(requests);

      expect(responses.map((r) => r.statusCode), everyElement(200));
      // A second refresh would spend the rotated refresh token the first
      // one just received.
      expect(refreshCalls, 1);
    });

    test('ends the session when the refresh token is rejected', () async {
      seedSession(storage);
      final auth = service(
        (_) async => throw ApiException(
          message: 'invalid_grant',
          statusCode: 400,
        ),
      );
      await auth.init();
      // Let init's background profile refresh settle before the session changes.
      await Future<void>.delayed(Duration.zero);
      expect(auth.isLoggedIn, isTrue);
      var notified = false;
      auth.addListener(() => notified = true);

      await expectLater(
        auth.sendAuthorized(acceptOnly('new')),
        throwsA(isA<SessionExpiredException>()),
      );

      expect(auth.isLoggedIn, isFalse);
      expect(notified, isTrue);
      expect(storage.values, isEmpty);
    });

    test('ends the session when the retry is rejected as well', () async {
      seedSession(storage);
      final auth = service((_) async => tokens('new'));

      await expectLater(
        auth.sendAuthorized((_) async => http.Response('', 401)),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(storage.values, isEmpty);
    });

    test('ends the session on a 401 when there is no refresh token',
        () async {
      seedSession(storage, refresh: null);
      final auth = service((_) async => tokens('new'));

      await expectLater(
        auth.sendAuthorized(acceptOnly('new')),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(refreshCalls, 0);
      expect(storage.values, isEmpty);
    });

    test('keeps the session when the refresh fails for a network reason',
        () async {
      seedSession(storage);
      final auth = service(
        (_) async => throw const SocketException('offline'),
      );

      await expectLater(
        auth.sendAuthorized(acceptOnly('new')),
        throwsA(isA<AuthException>()),
      );
      // Retryable: the tokens survive for the next attempt.
      expect(storage.values[AuthStorage.kAccessToken], 'old');
      expect(storage.values[AuthStorage.kRefreshToken], 'refresh-1');
    });
  });

  group('logout', () {
    test('clears the session', () async {
      seedSession(storage);
      final auth = service((_) async => tokens('new'));
      await auth.init();
      // Let init's background profile refresh settle before the session changes.
      await Future<void>.delayed(Duration.zero);

      // LibraryService is not registered here; clearing the library is
      // best-effort and must not stop the logout.
      await auth.logout();

      expect(auth.isLoggedIn, isFalse);
      expect(storage.values, isEmpty);
    });
  });
}

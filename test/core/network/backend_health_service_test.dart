import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangabaka_app/core/network/backend_health_service.dart';

void main() {
  BackendHealthService build({
    http.Client? client,
    int failureThreshold = 3,
  }) {
    return BackendHealthService(
      client: client ?? MockClient((_) async => http.Response('ok', 200)),
      failureThreshold: failureThreshold,
      probeInterval: const Duration(milliseconds: 50),
    );
  }

  test('starts in the unknown state', () {
    final health = build();
    expect(health.status.value, BackendHealthStatus.unknown);
    health.dispose();
  });

  test('a success moves it to healthy', () {
    final health = build();
    health.reportSuccess();
    expect(health.status.value, BackendHealthStatus.healthy);
    health.dispose();
  });

  test('goes down only after the failure threshold is reached', () {
    final health = build(failureThreshold: 3);

    health.reportServerFailure(context: 'x', statusCode: 530);
    health.reportServerFailure(context: 'x', statusCode: 502);
    expect(health.status.value, BackendHealthStatus.unknown);

    health.reportServerFailure(context: 'x', statusCode: 500);
    expect(health.status.value, BackendHealthStatus.down);

    health.dispose();
  });

  test('a 429 does not count toward the backend being down', () {
    final health = build(failureThreshold: 2);
    health.reportServerFailure(context: 'x', statusCode: 429);
    health.reportServerFailure(context: 'x', statusCode: 429);
    health.reportServerFailure(context: 'x', statusCode: 429);
    expect(health.status.value, BackendHealthStatus.unknown);
    health.dispose();
  });

  test('transport errors count toward the threshold', () {
    final health = build(failureThreshold: 2);
    health.reportServerFailure(context: 'x', error: 'SocketException');
    health.reportServerFailure(context: 'x', error: 'timeout');
    expect(health.status.value, BackendHealthStatus.down);
    health.dispose();
  });

  test('a real request succeeding brings it back up', () {
    final health = build(failureThreshold: 1);
    health.reportServerFailure(context: 'x', statusCode: 530);
    expect(health.status.value, BackendHealthStatus.down);

    health.reportSuccess();
    expect(health.status.value, BackendHealthStatus.healthy);
    health.dispose();
  });

  test('recovery probe brings it back up when the origin answers', () async {
    final health = build(
      failureThreshold: 1,
      client: MockClient((_) async => http.Response('not found', 404)),
    );
    health.reportServerFailure(context: 'x', statusCode: 530);
    expect(health.status.value, BackendHealthStatus.down);

    // A 404 still proves the origin is reachable.
    await health.checkNow();
    expect(health.status.value, BackendHealthStatus.healthy);
    health.dispose();
  });

  test('recovery probe keeps it down while the origin still 5xxs', () async {
    final health = build(
      failureThreshold: 1,
      client: MockClient((_) async => http.Response('bad gateway', 502)),
    );
    health.reportServerFailure(context: 'x', statusCode: 530);
    expect(health.status.value, BackendHealthStatus.down);

    await health.checkNow();
    expect(health.status.value, BackendHealthStatus.down);
    health.dispose();
  });

  test('reportApiOutcome is a no-op when the service is not registered', () {
    reportApiOutcome(ok: false, context: 'x', statusCode: 500);
    reportApiOutcome(ok: true, context: 'x', statusCode: 200);
  });

  test('isServerErrorStatus only flags 5xx', () {
    expect(isServerErrorStatus(200), isFalse);
    expect(isServerErrorStatus(404), isFalse);
    expect(isServerErrorStatus(429), isFalse);
    expect(isServerErrorStatus(500), isTrue);
    expect(isServerErrorStatus(530), isTrue);
  });
}

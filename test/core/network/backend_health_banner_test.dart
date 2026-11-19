import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/network/backend_health_banner.dart';
import 'package:mangabaka_app/core/network/backend_health_service.dart';

void main() {
  BackendHealthService register({MockClient? client}) {
    final health = BackendHealthService(
      client: client ?? MockClient((_) async => http.Response('bad gateway', 502)),
      failureThreshold: 1,
      probeInterval: const Duration(hours: 1),
    );
    getIt.registerSingleton<BackendHealthService>(health);
    addTearDown(() async {
      health.dispose();
      await getIt.reset();
    });
    return health;
  }

  Widget wrap(BackendHealthService health) => MaterialApp(
        home: Scaffold(body: BackendHealthBanner(health: health)),
      );

  testWidgets('is invisible while the backend is healthy', (tester) async {
    final health = register();
    health.reportSuccess();
    await tester.pumpWidget(wrap(health));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_off_rounded), findsNothing);
  });

  testWidgets('appears when the backend goes down', (tester) async {
    final health = register();
    await tester.pumpWidget(wrap(health));

    health.reportServerFailure(context: 'x', statusCode: 530);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);

    health.dispose();
  });

  testWidgets('retry button triggers a recovery check', (tester) async {
    var probeCount = 0;
    final health = register(
      client: MockClient((_) async {
        probeCount++;
        return http.Response('ok', 200);
      }),
    );

    await tester.pumpWidget(wrap(health));
    health.reportServerFailure(context: 'x', statusCode: 530);
    await tester.pumpAndSettle();

    await tester.tap(find.text('RETRY'));
    await tester.pumpAndSettle();

    expect(probeCount, greaterThan(0));
    expect(health.status.value, BackendHealthStatus.healthy);
  });
}

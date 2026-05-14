import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';
import 'package:mangabaka_app/features/navigation/screens/onboarding_screen.dart';
import 'package:mangabaka_app/main.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';

class MockProfileAuthService extends Fake implements ProfileAuthService {
  @override
  bool get isLoggedIn => false;
  @override
  MbProfile? get cachedProfile => null;
  @override
  Future<void> init() async {}
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

void main() {
  setUp(() async {
    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return '.';
    });
    await resetServiceLocator();
    setupServiceLocator();
    // Override with mocks if necessary
    getIt.unregister<ProfileAuthService>();
    getIt.registerSingleton<ProfileAuthService>(MockProfileAuthService());
  });

  testWidgets('App smoke test - shows onboarding initially', (WidgetTester tester) async {
    await tester.pumpWidget(const MangaBakaApp());
    // Initial pump to start animations
    await tester.pump();
    // Pump enough to let the splash screen finish its work
    await tester.pump(const Duration(seconds: 3));
    // Final settle
    await tester.pumpAndSettle();

    // Since onboarding is shown when not logged in and not completed onboarding
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}

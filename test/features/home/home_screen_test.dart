import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/home/screens/home_screen.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';

class MockProfileAuthService extends Fake implements ProfileAuthService {
  @override
  bool get isLoggedIn => false;
  @override
  MbProfile? get cachedProfile => null;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

void main() {
  setUp(() async {
    await resetServiceLocator();
    setupServiceLocator();
    getIt.unregister<ProfileAuthService>();
    getIt.registerSingleton<ProfileAuthService>(MockProfileAuthService());
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('HomeScreen renders its header', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    // Header is uppercased by the design system; 'home' is the untranslated key.
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('HomeScreen no longer shows the library-backed Now hero',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    // The reading hero is gone: MangaBaka tracks reading, it doesn't host it.
    expect(find.text('NOW'), findsNothing);
    expect(find.text('CONTINUE READING'), findsNothing);
  });
}

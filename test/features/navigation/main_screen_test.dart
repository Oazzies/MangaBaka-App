import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/navigation/screens/main_screen.dart';
import 'package:mangabaka_app/features/browse/screens/browse_screen.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';
import 'package:mangabaka_app/core/widgets/design/mb_nav.dart';

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

  testWidgets('MainScreen starts on Browse tab by default', (WidgetTester tester) async {
    // Set mobile size to ensure the bottom bar is used instead of the rail
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.reset());

    await tester.pumpWidget(MaterialApp(
      home: MainScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(BrowseScreen), findsOneWidget);
    
    final navBar = tester.widget<MbBottomNav>(find.byType(MbBottomNav));
    expect(navBar.selectedIndex, 2);
  });
}

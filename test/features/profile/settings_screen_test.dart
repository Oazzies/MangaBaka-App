import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/profile/screens/settings_screen.dart';
import 'package:mangabaka_app/features/profile/widgets/settings_section_header.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';

import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';

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
    getIt.registerSingleton<LoggingService>(LoggingService());
    getIt.registerSingleton<ProfileAuthService>(MockProfileAuthService());
    
    SharedPreferences.setMockInitialValues({});
    await SettingsManager().init();
  });

  testWidgets('SettingsScreen renders all sections', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsSectionHeader, skipOffstage: false), findsAtLeast(5));
    
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

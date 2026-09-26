import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/navigation/screens/onboarding_screen.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/core/database/database.dart';
import 'package:drift/native.dart';

class MockProfileAuthService extends Fake implements ProfileAuthService {
  @override
  bool get isLoggedIn => false;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

void main() {
  setUp(() async {
    // These tests cover the phone flow whatever host they run on.
    DesktopLayout.debugOverride = false;
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
    getIt.registerSingleton<AppDatabase>(AppDatabase.forTesting(NativeDatabase.memory()));
    getIt.registerSingleton<ProfileAuthService>(MockProfileAuthService());
    getIt.registerSingleton<MetadataService>(MetadataService());
    getIt.registerLazySingleton<SeriesSearchService>(() => SeriesSearchService());
  });

  tearDown(() async {
    DesktopLayout.debugOverride = null;
    await getIt<AppDatabase>().close();
    await resetServiceLocator();
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: OnboardingScreen(),
    );
  }

  testWidgets('OnboardingScreen renders first page and allows next', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Check for "app_name" which is the first thing on WelcomePage
    expect(find.text('APP_NAME'), findsOneWidget);

    // Check for Next button (translated key)
    final nextButton = find.text('ONBOARDING_NEXT');
    expect(nextButton, findsOneWidget);

    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // Should be on LanguagePage now (translated key 'onboarding_language_title')
    expect(find.text('ONBOARDING_LANGUAGE_TITLE'), findsOneWidget);
  });

  testWidgets('OnboardingScreen allows skipping', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    final skipButton = find.text('onboarding_skip');
    expect(skipButton, findsOneWidget);

    // Tapping skip should call _finishOnboarding
    await tester.tap(skipButton);
    await tester.pump();
    
  });

  testWidgets('desktop onboarding lists the steps and skips the camera step',
      (WidgetTester tester) async {
    DesktopLayout.debugOverride = true;
    tester.view.physicalSize = const Size(1040, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('ONBOARDING_WELCOME_TITLE'), findsOneWidget);
    expect(find.text('ONBOARDING_LOGIN_TITLE'), findsOneWidget);
    expect(find.text('ONBOARDING_CAMERA_TITLE'), findsNothing);
  });

  testWidgets('desktop onboarding switches pages when clicking on sidebar steps',
      (WidgetTester tester) async {
    DesktopLayout.debugOverride = true;
    tester.view.physicalSize = const Size(1040, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Initially on Welcome page
    expect(find.text('APP_NAME'), findsOneWidget);

    // Tap on Language step in the sidebar
    final languageStep = find.text('ONBOARDING_LANGUAGE_TITLE');
    expect(languageStep, findsOneWidget);
    await tester.tap(languageStep);
    await tester.pumpAndSettle();

    // Now Language title appears both in sidebar and in LanguagePage body
    expect(find.text('ONBOARDING_LANGUAGE_TITLE'), findsNWidgets(2));
  });
}

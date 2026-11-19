import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/profile/screens/profile_screen.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/services/snapshot_service.dart';
import 'package:mangabaka_app/features/profile/services/statistics_service.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/database/database.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class MockSnapshotService extends Fake implements SnapshotService {}

void main() {
  setUp(() async {
    await resetServiceLocator();
    SharedPreferences.setMockInitialValues({});
    getIt.registerSingleton<LoggingService>(LoggingService());
    getIt.registerSingleton<AppDatabase>(AppDatabase());
    getIt.registerSingleton<ProfileAuthService>(MockProfileAuthService());
    getIt.registerSingleton<SnapshotService>(MockSnapshotService());
    getIt.registerLazySingleton<StatisticsService>(() => StatisticsService(getIt<AppDatabase>()));
    getIt.registerLazySingleton<SeriesSearchService>(() => SeriesSearchService());
    getIt.registerSingleton<LibraryService>(LibraryService(auth: getIt<ProfileAuthService>()));
  });

  testWidgets('ProfileScreen shows login prompt when not logged in', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ProfileScreen(),
    ));

    expect(find.text('login_prompt_profile'), findsOneWidget); // Key if not translated
  });
}

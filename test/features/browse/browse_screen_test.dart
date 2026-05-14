import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/features/browse/screens/browse_screen.dart';
import 'package:mangabaka_app/features/browse/widgets/mb_search_bar.dart';
import 'package:mangabaka_app/features/browse/widgets/browse_shortcuts.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';

class MockSeriesSearchService extends Fake implements SeriesSearchService {
  @override
  Future<List<Map<String, dynamic>>> getGenres() async => [];
  @override
  Future<List<Map<String, dynamic>>> getTags() async => [];
}

class MockProfileAuthService extends Fake implements ProfileAuthService {
  @override
  bool get isLoggedIn => false;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

class MockMetadataService extends Fake implements MetadataService {
  @override
  String getGenreLabel(String value) => value;
  @override
  String getTagName(int id) => 'Tag $id';
}

void main() {
  setUp(() async {
    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return '.';
    });
    SharedPreferences.setMockInitialValues({});
    await resetServiceLocator();
    await SettingsManager().init();
    
    getIt.registerSingleton<LoggingService>(LoggingService());
    getIt.registerSingleton<SeriesSearchService>(MockSeriesSearchService());
    getIt.registerSingleton<ProfileAuthService>(MockProfileAuthService());
    getIt.registerSingleton<MetadataService>(MockMetadataService());
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: BrowseScreen(),
    );
  }

  testWidgets('BrowseScreen renders search bar and shortcuts', (WidgetTester tester) async {
    // Note: We might need to bypass LocalizationService if it fails to load assets in tests
    // For now, let's assume it handles missing assets gracefully (it returns the key as the translation)

    await tester.pumpWidget(createWidgetUnderTest());

    // Check for MBSearchBar
    expect(find.byType(MBSearchBar), findsOneWidget);

    // Check for BrowseShortcuts (initially visible when search is empty)
    expect(find.byType(BrowseShortcuts), findsOneWidget);
  });

  testWidgets('Typing in search bar updates state', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'One Piece');
    await tester.pump();

    expect(find.text('One Piece'), findsOneWidget);
  });
}

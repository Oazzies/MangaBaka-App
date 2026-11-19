import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/exceptions/error_messages.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/features/library/widgets/library_body.dart';
import 'package:mangabaka_app/features/profile/widgets/login/mb_login_prompt.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/services/series_list_deps.dart';

class _NoAuth extends Fake implements ProfileAuthService {}

class _NoLibrary extends Fake implements LibraryService {}

void main() {
  Widget createWidgetUnderTest({
    required bool loggedIn,
    Stream<List<LibraryEntry>>? entriesStream,
    required TabController tabController,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: LibraryBody(
          loggedIn: loggedIn,
          entriesStream: entriesStream,
          query: '',
          filters: SearchFilters(),
          tabController: tabController,
          scrollControllers: {},
          onRefresh: () async {},
          onLogin: () {},
          onItemTap: (_) {},
          deps: SeriesListDeps(
            auth: _NoAuth(),
            library: _NoLibrary(),
            prefetch: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('LibraryBody shows MBLoginPrompt when not logged in', (WidgetTester tester) async {
    final tabController = TabController(length: 7, vsync: const TestVSync());
    
    await tester.pumpWidget(createWidgetUnderTest(
      loggedIn: false,
      tabController: tabController,
    ));

    expect(find.byType(MBLoginPrompt), findsOneWidget);
  });

  testWidgets('a database error is shown as a localized message, not raw', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
    LocalizationService.resetForTesting();
    await LocalizationService().init();
    final tabController = TabController(length: 7, vsync: const TestVSync());
    final error = Exception('SqliteException(1): no such table: series');

    await tester.pumpWidget(
      createWidgetUnderTest(
        loggedIn: true,
        entriesStream: Stream.error(error),
        tabController: tabController,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(ErrorMessages.describe(error)), findsOneWidget);
    expect(find.textContaining('SqliteException'), findsNothing);
  });
}

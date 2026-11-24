import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';
import 'package:mangabaka_app/features/lists/screens/library_lists_screen.dart';
import 'package:mangabaka_app/features/lists/widgets/series_lists_sheet.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../responsive/support/fake_services.dart';
import '../../responsive/support/fixtures.dart';
import 'lists_fakes.dart';

class _NoSeries extends Fake implements SeriesService {}

void main() {
  late FakeListsService service;
  late FakeEntriesLibrary library;
  late FakeAuth auth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
    await SettingsManager().setListStyle(AppListStyle.comfortable);
    await SettingsManager().setContentPreferences(['safe', 'suggestive']);
    await resetServiceLocator();
    LocalizationService.resetForTesting();
    await LocalizationService().init();
    auth = FakeAuth(signedIn: true);
    library = FakeEntriesLibrary(Fixtures.library(6));
    service = FakeListsService(
      lists: [
        const LibraryList(id: 1, name: 'Favourites', isPrivate: false),
        const LibraryList(id: 2, name: 'Read on the train', isPrivate: true),
      ],
      members: {
        1: {'1000', '1001'},
        2: {'1004'},
      },
    );
    getIt
      ..registerSingleton<LoggingService>(LoggingService())
      ..registerSingleton<ProfileAuthService>(auth)
      ..registerSingleton<LibraryService>(library)
      ..registerSingleton<SeriesService>(_NoSeries());
  });

  tearDown(() async {
    DesktopLayout.debugOverride = null;
    await resetServiceLocator();
  });

  String t(String key) => LocalizationService().translate(key);

  Finder label(String text) => find.byWidgetPredicate(
    (w) => w is Text && (w.data ?? '').toLowerCase() == text.toLowerCase(),
  );

  Future<void> pump(WidgetTester tester, Widget home, Size size) async {
    DesktopLayout.debugOverride = false;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: home));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  Widget hub() =>
      LibraryListsScreen(service: service, library: library, auth: auth);

  testWidgets('phone: lists with counts; a tap opens the list', (tester) async {
    await pump(tester, hub(), const Size(400, 800));
    expect(service.calls, ['refresh']);
    expect(find.text('Favourites'), findsOneWidget);
    expect(
      find.text(t('series_count').replaceAll('{count}', '2')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('lists_new_fab')), findsOneWidget);

    await tester.tap(find.text('Favourites'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(label('Favourites'), findsWidgets);
    expect(find.text(Fixtures.libraryEntry(0).series.title), findsWidgets);
    await finish(tester);
  });

  testWidgets('phone: Back clears a series selection before leaving', (
    tester,
  ) async {
    await pump(tester, hub(), const Size(400, 800));
    await tester.tap(find.text('Favourites'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    final title = Fixtures.libraryEntry(0).series.title;
    await tester.longPress(find.text(title).first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text(t('lists_selected_count').replaceAll('{count}', '1')),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text(title), findsWidgets);
    expect(find.byKey(const ValueKey('lists_new_fab')), findsNothing);
    await finish(tester);
  });

  testWidgets('phone: the new list form creates a list', (tester) async {
    await pump(tester, hub(), const Size(400, 800));
    await tester.tap(find.byKey(const ValueKey('lists_new_fab')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    await tester.enterText(
      find.byKey(const ValueKey('list_name_field')),
      'favourites',
    );
    await tester.tap(find.byKey(const ValueKey('list_form_save')));
    await tester.pump();
    expect(find.text(t('lists_error_name_taken')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('list_name_field')),
      'Weekend',
    );
    await tester.tap(find.byKey(const ValueKey('list_form_save')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(service.calls.last, 'create Weekend false');
    expect(find.text('Weekend'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('phone: long press selects; the bar deletes in bulk', (
    tester,
  ) async {
    await pump(tester, hub(), const Size(400, 800));
    await tester.longPress(find.text('Favourites'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text(t('lists_selected_count').replaceAll('{count}', '1')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip(t('lists_delete')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('list_confirm_action')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(service.calls.last, 'deleteMany [1]');
    expect(find.text('Favourites'), findsNothing);
    await finish(tester);
  });

  testWidgets('wide: the first list opens beside the lists', (tester) async {
    await pump(tester, hub(), const Size(1100, 800));
    expect(find.byKey(const ValueKey('lists_new_fab')), findsNothing);
    expect(label('Favourites'), findsNWidgets(2));
    await tester.tap(find.text('Read on the train'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(label('Read on the train'), findsNWidgets(2));
    expect(find.text(Fixtures.libraryEntry(4).series.title), findsWidgets);
    await finish(tester);
  });

  testWidgets('signed out, the lists ask for a sign in', (tester) async {
    auth = FakeAuth(signedIn: false);
    await pump(tester, hub(), const Size(400, 800));
    expect(find.text(t('login_prompt_lists')), findsOneWidget);
    expect(service.calls, isEmpty);
    await finish(tester);
  });

  testWidgets('series sheet toggles a list and makes a new one', (
    tester,
  ) async {
    final series = Fixtures.libraryEntry(2).series;
    await pump(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showSeriesListsSheet(
              context,
              service: service,
              library: library,
              series: series,
            ),
            child: const Text('open'),
          ),
        ),
      ),
      const Size(400, 800),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('series_list_1')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(service.calls.last, 'add ${series.id} 1');

    await tester.tap(find.byKey(const ValueKey('series_lists_new')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.enterText(find.byKey(const ValueKey('list_name_field')), 'Q');
    await tester.tap(find.byKey(const ValueKey('list_form_save')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(service.calls.sublist(service.calls.length - 2), [
      'create Q false',
      'add ${series.id} 900',
    ]);
    await finish(tester);
  });
}

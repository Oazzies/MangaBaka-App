import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/lists/controllers/library_lists_controller.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';
import 'package:mangabaka_app/features/lists/widgets/add_series_to_list_form.dart';
import 'package:mangabaka_app/features/lists/widgets/library_list_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../responsive/support/fixtures.dart';
import 'lists_fakes.dart';

void main() {
  late FakeListsService service;
  late FakeEntriesLibrary library;
  late FakeSeriesSearch search;
  late LibraryListsController lists;
  const list = LibraryList(id: 1, name: 'Favourites', isPrivate: false);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
    await SettingsManager().setContentPreferences(['safe', 'suggestive']);
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
    LocalizationService.resetForTesting();
    await LocalizationService().init();
    library = FakeEntriesLibrary(Fixtures.library(6));
    service = FakeListsService(
      lists: [list],
      members: {
        1: {'1000', '1001'},
      },
    );
    search = FakeSeriesSearch([
      Fixtures.libraryEntry(3).series,
      Fixtures.series(40),
    ]);
  });

  tearDown(() async {
    DesktopLayout.debugOverride = null;
    await resetServiceLocator();
  });

  String t(String key) => LocalizationService().translate(key);

  Future<void> finish(WidgetTester tester) async {
    lists.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets('wide: the dialog names the library and closes on its X', (
    tester,
  ) async {
    lists = LibraryListsController(service: service, library: library);
    await _host(tester, const Size(1100, 800), (context) {
      showAddSeriesToList(context, lists, list, search: search);
    });
    expect(find.text(t('lists_add_series_title').toUpperCase()), findsOne);
    expect(find.byKey(const ValueKey('add_series_search_all')), findsOne);

    await tester.tap(find.byKey(const ValueKey('list_form_close')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('add_series_submit')), findsNothing);
    await finish(tester);
  });

  testWidgets('phone: all series add to the list, through the library', (
    tester,
  ) async {
    lists = LibraryListsController(service: service, library: library);
    await _host(tester, const Size(400, 800), (context) {
      showAddSeriesToList(context, lists, list, search: search);
    });
    await tester.enterText(find.byType(TextField), 'zz');
    await tester.pump();
    final searchAll = t('lists_search_all_for').replaceAll('{query}', 'zz');
    expect(find.text(searchAll), findsOne);

    await tester.tap(find.text(searchAll));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(search.queries, ['zz']);

    await tester.tap(find.byKey(const ValueKey('global_series_1003')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(service.calls.last, 'add 1003 1');
    expect(library.created, isEmpty);

    await tester.tap(find.byKey(const ValueKey('global_series_1040')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('library_state_reading')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('add_to_library_confirm')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(library.created, ['1040 reading']);
    expect(service.calls.last, 'add 1040 1');
    await finish(tester);
  });

  testWidgets('the list form buttons share one height', (tester) async {
    lists = LibraryListsController(service: service, library: library);
    await _open(
      tester,
      const Size(1100, 800),
      () => LibraryListForm(onSubmit: (_, _) async => null),
    );
    final cancel = tester.getSize(
      find.byKey(const ValueKey('list_form_cancel')),
    );
    final save = tester.getSize(find.byKey(const ValueKey('list_form_save')));
    expect(cancel.height, save.height);
    expect(cancel.width, save.width);
    await finish(tester);
  });
}

Future<void> _host(
  WidgetTester tester,
  Size size,
  void Function(BuildContext context) onOpen,
) async {
  DesktopLayout.debugOverride = false;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => onOpen(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

Future<void> _open(
  WidgetTester tester,
  Size size,
  Widget Function() form,
) async {
  DesktopLayout.debugOverride = false;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: form())),
    ),
  );
  await tester.pump();
}

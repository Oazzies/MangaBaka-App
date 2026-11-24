import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/desktop/screens/lists/desktop_lists_page.dart';
import 'package:mangabaka_app/features/navigation/models/nav_destinations.dart';

import '../responsive/support/fixtures.dart';
import '../responsive/support/layout_sweep.dart';
import '../responsive/support/test_app.dart';
import '../responsive/support/viewports.dart';

void main() {
  setUpAll(loadAppFonts);
  setUp(() => setUpEnvironment(const Environment()));
  tearDown(tearDownEnvironment);

  String t(String key) => LocalizationService().translate(key);

  Finder heading(String text) =>
      find.byWidgetPredicate((w) => w is Text && w.data == text.toUpperCase());

  Future<void> open(WidgetTester tester) async {
    applyViewport(tester, WindowSizes.desktop().first);
    addTearDown(() => resetViewport(tester));
    await tester.pumpWidget(desktopApp(destination: NavTabs.library));
    await settle(tester);
  }

  testWidgets('a list in the side panel scopes the library', (tester) async {
    await open(tester);
    final favourites = Fixtures.libraryListsJson().first;
    final row = find.byKey(ValueKey('desktop_list_row_${favourites['id']}'));
    expect(row, findsOneWidget);

    await tester.tap(row);
    await settle(tester);
    expect(heading(favourites['name'] as String), findsOneWidget);
    expect(
      find.byKey(const ValueKey('desktop_list_add_series')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('desktop_list_clear_scope')));
    await settle(tester);
    expect(heading(t('library')), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('manage opens the lists table', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('desktop_lists_manage')));
    await settle(tester);
    expect(find.byType(DesktopListsPage), findsOneWidget);
    for (final list in Fixtures.libraryListsJson()) {
      expect(
        find.byKey(ValueKey('desktop_lists_row_${list['id']}')),
        findsOneWidget,
      );
    }
    await disposeApp(tester);
  });
}

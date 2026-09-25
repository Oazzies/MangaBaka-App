@Tags(['responsive'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/desktop/screens/home/desktop_home_screen.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';
import 'package:mangabaka_app/features/library/import/bulk_import_screen.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';

import 'support/fixtures.dart';
import 'support/layout_sweep.dart';
import 'support/test_app.dart';
import 'support/viewports.dart';

/// Screens pushed over a destination inside the desktop content area, swept
/// like the destinations themselves.
void main() {
  setUpAll(loadAppFonts);

  final routes = <String, Widget Function()>{
    // A long-titled series with every field filled, and one with almost none.
    'series detail (full)': () =>
        SeriesDetailScreen(series: Fixtures.series(2)),
    'series detail (sparse)': () =>
        SeriesDetailScreen(series: Fixtures.series(1)),
    'browse results': () =>
        const BrowseResultsScreen(sortType: 'Trending', sortBy: 'trending_7d'),
    'bulk import': () => const BulkImportScreen(),
  };

  for (final env in const [Environment(), Environment(language: 'de')]) {
    group(env.label, () {
      setUp(() => setUpEnvironment(env));
      tearDown(tearDownEnvironment);

      for (final MapEntry(key: name, value: build) in routes.entries) {
        testWidgets(name, (tester) async {
          final log = IssueLog();
          final sizes = WindowSizes.desktop();
          applyViewport(tester, sizes.first);
          addTearDown(() => resetViewport(tester));
          log
            ..viewport = sizes.first
            ..attach(tester);

          await tester.pumpWidget(desktopApp());
          await settle(tester);
          // Pushed from inside the content area, as a tap on a card would.
          final context = tester.element(find.byType(DesktopHomeScreen));
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => build()));
          await settle(tester);

          for (final collapsed in [false, true]) {
            DesktopShell.current!.debugSidebarCollapsed = collapsed;
            await tester.pump(const Duration(seconds: 1));
            await sweep(
              tester,
              log,
              scenario:
                  '$name, sidebar ${collapsed ? 'collapsed' : 'expanded'}',
              viewports: sizes,
            );
          }

          await disposeApp(tester);
          log
            ..detach()
            ..expectClean();
        });
      }
    });
  }
}

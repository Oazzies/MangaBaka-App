@Tags(['responsive'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/desktop/screens/browse/desktop_browse_screen.dart';
import 'package:mangabaka_app/desktop/screens/home/desktop_home_screen.dart';
import 'package:mangabaka_app/desktop/screens/library/desktop_library_screen.dart';
import 'package:mangabaka_app/desktop/screens/news/desktop_news_screen.dart';
import 'package:mangabaka_app/desktop/screens/profile/desktop_profile_screen.dart';
import 'package:mangabaka_app/desktop/screens/settings/desktop_settings_screen.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';
import 'package:mangabaka_app/features/navigation/models/nav_destinations.dart';

import 'support/layout_sweep.dart';
import 'support/resize_benchmark.dart';
import 'support/test_app.dart';
import 'support/viewports.dart';

/// Holds the resize work per frame to a budget, so a change that brings back
/// per-frame rebuilding fails here instead of quietly making resizing lag.
///
/// Rebuild counts, unlike frame times, are deterministic, so they can be
/// asserted. Before lib/desktop/RESPONSIVE.md's rules every page rebuilt
/// ~2,500 elements per resize frame; within its breakpoints a page now
/// rebuilds under a hundred, most of them the shell's own bookkeeping.
void main() {
  setUpAll(loadAppFonts);

  /// Elements rebuilt on a typical frame of a drag-resize, per page.
  const budget = 150;

  const pages = {
    'home': NavTabs.home,
    'library': NavTabs.library,
    'browse': NavTabs.browse,
    'news': NavTabs.news,
    'profile': NavTabs.profile,
    'settings': DesktopShellState.settingsIndex,
  };

  group('rebuild budget', () {
    setUp(() => setUpEnvironment(const Environment()));
    tearDown(tearDownEnvironment);

    for (final MapEntry(key: name, value: index) in pages.entries) {
      testWidgets('$name stays within $budget rebuilds per resize frame', (
        tester,
      ) async {
        await _pumpApp(tester, index);
        final cost = await measureDrag(tester, name);
        await disposeApp(tester);
        expect(
          cost.medianRebuilds,
          lessThanOrEqualTo(budget),
          reason:
              'A typical frame of a drag-resize rebuilt '
              '${cost.medianRebuilds} elements. Run resize_benchmark_test '
              'with RESIZE_BENCHMARK_DETAIL=1 to see which, and '
              'lib/desktop/RESPONSIVE.md for the fixes.',
        );
      });
    }
  });

  group('hidden pages', () {
    setUp(() => setUpEnvironment(const Environment()));
    tearDown(tearDownEnvironment);

    testWidgets('rebuild nothing while the window is resized', (tester) async {
      await _pumpApp(tester, NavTabs.home);
      // Show every page once, so each is built and laid out, then go home.
      for (final index in pages.values) {
        DesktopShell.current!.select(index);
        await settle(tester);
      }
      DesktopShell.current!.select(NavTabs.home);
      await settle(tester);

      const hidden = {
        DesktopLibraryScreen,
        DesktopBrowseScreen,
        DesktopNewsScreen,
        DesktopProfileScreen,
        DesktopSettingsScreen,
      };
      // Their layout as it stood when last shown; a resize must not redo it.
      final sizes = {
        for (final type in hidden)
          type:
              (tester
                          .element(find.byType(type, skipOffstage: false))
                          .findRenderObject()!
                      as RenderBox)
                  .size,
      };

      final rebuiltIn = <Type, int>{};
      final previous = debugOnRebuildDirtyWidget;
      debugOnRebuildDirtyWidget = (element, _) {
        element.visitAncestorElements((a) {
          final type = a.widget.runtimeType;
          if (hidden.contains(type)) {
            rebuiltIn[type] = (rebuiltIn[type] ?? 0) + 1;
            return false;
          }
          return type != DesktopHomeScreen;
        });
      };
      try {
        for (final size in WindowSizes.drag()) {
          applyViewport(tester, size);
          await tester.pump();
        }
      } finally {
        debugOnRebuildDirtyWidget = previous;
      }
      final relaidOut = [
        for (final type in hidden)
          if ((tester
                          .element(find.byType(type, skipOffstage: false))
                          .findRenderObject()!
                      as RenderBox)
                  .size !=
              sizes[type])
            type,
      ];
      await disposeApp(tester);
      expect(rebuiltIn, isEmpty, reason: 'hidden pages rebuilt');
      expect(relaidOut, isEmpty, reason: 'hidden pages were laid out');
    });
  });
}

Future<void> _pumpApp(WidgetTester tester, int destination) async {
  // Layout errors are the sweeps' business; here they'd only obscure the
  // count.
  final log = IssueLog();
  final start = WindowSizes.drag().first;
  applyViewport(tester, start);
  addTearDown(() => resetViewport(tester));
  log
    ..viewport = start
    ..attach(tester);
  await tester.pumpWidget(desktopApp(destination: destination));
  await settle(tester);
}

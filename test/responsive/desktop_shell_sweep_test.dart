@Tags(['responsive'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/desktop/screens/settings/desktop_settings_screen.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';
import 'package:mangabaka_app/features/navigation/models/nav_destinations.dart';

import 'support/layout_sweep.dart';
import 'support/test_app.dart';
import 'support/viewports.dart';

/// Every desktop destination, inside the real shell and window frame, resized
/// through every window the app can be given — signed in and out, with data
/// and empty, in English and German, with the sidebar pinned open and shut.
void main() {
  setUpAll(loadAppFonts);

  const destinations = {
    'home': NavTabs.home,
    'library': NavTabs.library,
    'browse': NavTabs.browse,
    'news': NavTabs.news,
    'profile': NavTabs.profile,
    'settings': DesktopShellState.settingsIndex,
  };

  const environments = [
    Environment(),
    Environment(language: 'de'),
    Environment(populated: false),
    Environment(signedIn: false),
  ];

  for (final env in environments) {
    group(env.label, () {
      setUp(() => setUpEnvironment(env));
      tearDown(tearDownEnvironment);

      for (final MapEntry(key: name, value: index) in destinations.entries) {
        testWidgets(name, (tester) async {
          await _sweepDestination(tester, name, index);
        });
      }
    });
  }

  // Every settings page, not just the one the screen opens on.
  group('settings pages', () {
    final env = const Environment(language: 'de');
    setUp(() => setUpEnvironment(env));
    tearDown(tearDownEnvironment);

    for (final page in DesktopSettingsScreenState.debugCategories) {
      testWidgets(page, (tester) async {
        await _sweepDestination(
          tester,
          'settings/$page',
          DesktopShellState.settingsIndex,
          prepare: () => DesktopSettingsScreen.stateKey.currentState!
              .debugSelectCategory(page),
        );
      });
    }
  });

  // A continuous drag-resize, both ways, in small uneven steps: catches what
  // only goes wrong mid-transition (realigning scroll positions, sizes that
  // lag behind their slot, breakpoints flipping back and forth).
  group('drag-resize', () {
    setUp(() => setUpEnvironment(const Environment()));
    tearDown(tearDownEnvironment);

    for (final MapEntry(key: name, value: index) in destinations.entries) {
      testWidgets(name, (tester) async {
        await _sweepDestination(
          tester,
          name,
          index,
          windows: WindowSizes.drag(),
          checkControls: false,
        );
      });
    }
  });

  // The library and browse lists render as tables on desktop, one layout per
  // list style; each gets its own sweep with the library full.
  for (final style in AppListStyle.values) {
    group('list style ${style.name}', () {
      final env = Environment(listStyle: style, language: 'de');
      setUp(() => setUpEnvironment(env));
      tearDown(tearDownEnvironment);

      testWidgets('library', (tester) async {
        await _sweepDestination(tester, 'library', NavTabs.library);
      });
    });
  }
}

Future<void> _sweepDestination(
  WidgetTester tester,
  String name,
  int index, {
  List<WindowSize>? windows,
  bool checkControls = true,
  void Function()? prepare,
}) async {
  final log = IssueLog();
  final viewports = windows ?? WindowSizes.desktop();
  applyViewport(tester, viewports.first);
  addTearDown(() => resetViewport(tester));
  log
    ..viewport = viewports.first
    ..attach(tester);

  await tester.pumpWidget(desktopApp(destination: index));
  await settle(tester);
  if (prepare != null) {
    prepare();
    await settle(tester);
  }

  for (final collapsed in [false, true]) {
    DesktopShell.current!.debugSidebarCollapsed = collapsed;
    await tester.pump(const Duration(seconds: 1));
    await sweep(
      tester,
      log,
      scenario: '$name, sidebar ${collapsed ? 'collapsed' : 'expanded'}',
      viewports: viewports,
      checkControls: checkControls,
    );
  }

  await disposeApp(tester);
  log
    ..detach()
    ..expectClean();
}

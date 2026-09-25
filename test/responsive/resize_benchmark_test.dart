@Tags(['responsive'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';
import 'package:mangabaka_app/features/navigation/models/nav_destinations.dart';

import 'support/layout_sweep.dart';
import 'support/resize_benchmark.dart';
import 'support/test_app.dart';
import 'support/viewports.dart';

/// Measures what a drag-resize costs on each desktop page, frame by frame.
///
/// Prints a table rather than asserting on times — wall-clock time in a debug
/// test build is noisy and far above release — so run it before and after a
/// change and compare. Set `RESIZE_BENCHMARK_OUT` to also write the table to
/// a file.
void main() {
  setUpAll(loadAppFonts);

  final results = <ResizeCost>[];

  tearDownAll(() {
    final table = [
      'Drag-resize cost per frame (debug build; compare, don\'t read as fps):',
      ...results.map((r) => r.row()),
    ].join('\n');
    // ignore: avoid_print
    print(table);
    final out = Platform.environment['RESIZE_BENCHMARK_OUT'];
    if (out != null) File(out).writeAsStringSync('$table\n');
  });

  const pages = {
    'home': NavTabs.home,
    'library (table)': NavTabs.library,
    'browse': NavTabs.browse,
    'news': NavTabs.news,
    'profile': NavTabs.profile,
    'settings': DesktopShellState.settingsIndex,
  };

  for (final MapEntry(key: name, value: index) in pages.entries) {
    group(name, () {
      setUp(() => setUpEnvironment(const Environment()));
      tearDown(tearDownEnvironment);

      testWidgets('drag-resize', (tester) async {
        await _measure(tester, results, name, index);
      });
    });
  }

  group('library (grid)', () {
    setUp(
      () => setUpEnvironment(
        const Environment(listStyle: AppListStyle.compactGrid),
      ),
    );
    tearDown(tearDownEnvironment);

    testWidgets('drag-resize', (tester) async {
      await _measure(tester, results, 'library (grid)', NavTabs.library);
    });
  });
}

Future<void> _measure(
  WidgetTester tester,
  List<ResizeCost> results,
  String name,
  int destination,
) async {
  // Layout errors are the sweeps' business; here they'd only abort the
  // measurement.
  final log = IssueLog();
  applyViewport(tester, WindowSizes.drag().first);
  addTearDown(() => resetViewport(tester));
  log
    ..viewport = WindowSizes.drag().first
    ..attach(tester);
  await tester.pumpWidget(desktopApp(destination: destination));
  await settle(tester);
  results.add(await measureDrag(tester, name));
  await disposeApp(tester);
  log.detach();
}

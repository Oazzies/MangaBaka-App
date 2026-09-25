import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/desktop/screens/home/desktop_trending_board.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

Series _series(int rank) => Series.fromJson({
  'id': '$rank',
  'title': 'A Very Long Trending Series Title Number $rank That Wraps',
  'state': 'active',
  'type': 'manga',
  'status': 'releasing',
  'year': 2020,
  'rating': '87',
  'genres': ['action', 'adventure', 'comedy', 'drama'],
  'description':
      'A long synopsis that goes on for quite a while, describing the plot '
      'in more detail than a narrow card would comfortably have room for, '
      'to make sure the fade-out clipping actually gets exercised here.',
});

List<Series> _trendingSeries() => List.generate(9, (i) => _series(i + 1));

void main() {
  setUp(() async {
    await resetServiceLocator();
    setupServiceLocator();
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
  });

  // The default test surface is 800x600 — narrower than several widths this
  // suite checks — so a SizedBox wider than that would silently be clamped
  // by the surface itself rather than actually exercising that width.
  void useWideSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(2200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget harness(double width, {bool loading = false, List<Series>? series}) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(
              child: DesktopTrendingBoard(
                series: series ?? _trendingSeries(),
                loading: loading,
                selectedType: null,
                window: 7,
                onTypeChanged: (_) {},
                onWindowChanged: (_) {},
                onViewAll: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  // From well below DesktopLayout.minWidth's tightest realistic content
  // column up through a very wide monitor — the whole range the desktop
  // shell can actually hand this section.
  const widths = [360.0, 460.0, 530.0, 700.0, 820.0, 900.0, 1200.0, 1900.0];

  group('DesktopTrendingBoard renders without overflow', () {
    for (final width in widths) {
      testWidgets('with results at width=$width', (tester) async {
        useWideSurface(tester);
        await tester.pumpWidget(harness(width));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('loading at width=$width', (tester) async {
        useWideSurface(tester);
        await tester.pumpWidget(harness(width, loading: true));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('empty at width=$width', (tester) async {
        useWideSurface(tester);
        await tester.pumpWidget(harness(width, series: const []));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('resizing across the stack breakpoint stays overflow-free', (
    tester,
  ) async {
    useWideSurface(tester);
    await tester.pumpWidget(harness(1200));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(harness(700));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(harness(1200));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

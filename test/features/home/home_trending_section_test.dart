import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/home/widgets/home_trending_section.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:shared_preferences/shared_preferences.dart';

Series _series(int rank) => Series.fromJson({
  'id': '$rank',
  'title': 'Trending $rank',
  'state': 'active',
  'type': 'manga',
  'content_rating': 'safe',
});

void main() {
  setUp(() async {
    await resetServiceLocator();
    setupServiceLocator();
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
  });

  Widget harness({required List<Series> series, required bool loading}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: HomeTrendingSection(
            series: series,
            loading: loading,
            selectedType: null,
            window: 7,
            onTypeChanged: (_) {},
            onWindowChanged: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('a filter reload keeps the rail on screen', (tester) async {
    final series = [_series(1), _series(2)];
    await tester.pumpWidget(harness(series: series, loading: false));
    await tester.pump(const Duration(seconds: 1));
    final idle = tester.getSize(find.byType(HomeTrendingSection));
    expect(find.text('Trending 1'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.pumpWidget(harness(series: series, loading: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Trending 1'), findsOneWidget);
    expect(find.text('Trending 2'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.getSize(find.byType(HomeTrendingSection)), idle);
  });

  testWidgets('a filter with no results keeps the rail height', (
    tester,
  ) async {
    await tester.pumpWidget(harness(series: [_series(1)], loading: false));
    await tester.pump(const Duration(seconds: 1));
    final filled = tester.getSize(find.byType(HomeTrendingSection));

    await tester.pumpWidget(harness(series: const [], loading: false));
    await tester.pump();
    expect(find.text('no_results'), findsOneWidget);
    expect(tester.getSize(find.byType(HomeTrendingSection)), filled);
  });
}

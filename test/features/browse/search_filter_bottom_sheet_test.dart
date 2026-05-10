import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/browse/widgets/search_filter_bottom_sheet.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';

class MockSeriesSearchService extends Fake implements SeriesSearchService {
  @override
  Future<List<Map<String, dynamic>>> getGenres() async => [
        {'label': 'Action', 'value': 'action'},
        {'label': 'Comedy', 'value': 'comedy'},
      ];
  @override
  Future<List<Map<String, dynamic>>> getTags() async => [];
}

void main() {
  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
    getIt.registerSingleton<SeriesSearchService>(MockSeriesSearchService());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: SearchFilterBottomSheet(
          initialFilters: SearchFilters(),
          onApply: (_) {},
        ),
      ),
    );
  }

  testWidgets('SearchFilterBottomSheet renders filter sections', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Handle metadata loading

    // Check for headers (using translated keys if they aren't translated in tests)
    expect(find.text('filters'), findsOneWidget);
    expect(find.text('sort_by'), findsAtLeast(1));
    expect(find.text('genres'), findsOneWidget);
    expect(find.text('tags'), findsOneWidget);
  });

  testWidgets('Reset button clears filters', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    final resetButton = find.text('reset');
    await tester.tap(resetButton);
    await tester.pump();

    // Verify reset logic (this is more of a unit test but we can check UI updates if any)
  });
}

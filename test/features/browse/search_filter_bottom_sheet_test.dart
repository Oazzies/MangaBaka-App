import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_bottom_sheet.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';

class MockSeriesSearchService extends Fake implements SeriesSearchService {
  @override
  Future<List<Map<String, dynamic>>> getGenres() async => [
        {'label': 'Action', 'value': 'action'},
        {'label': 'Comedy', 'value': 'comedy'},
      ];
  @override
  Future<List<Map<String, dynamic>>> getTags() async => [];
}

class MockMetadataService extends Fake implements MetadataService {
  @override
  String getGenreLabel(String value) => value;
  @override
  String getTagName(int id) => 'Tag $id';
}

void main() {
  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
    getIt.registerSingleton<SeriesSearchService>(MockSeriesSearchService());
    getIt.registerSingleton<MetadataService>(MockMetadataService());
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

    expect(find.text('FILTERS'), findsOneWidget);
    expect(find.text('SORT_BY'), findsAtLeast(1));
    expect(find.text('GENRES'), findsOneWidget);
    expect(find.text('TAGS'), findsOneWidget);
  });

  testWidgets('Reset button clears filters', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    final resetButton = find.text('RESET');
    await tester.tap(resetButton);
    await tester.pump();
  });
}

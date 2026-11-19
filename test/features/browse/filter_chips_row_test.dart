import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/filter_chip_badge.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/filter_chips_row.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';

class _FakeMetadataService extends Fake implements MetadataService {
  @override
  String getGenreLabel(String value) => value;
  @override
  String getTagName(int id) => 'Tag $id';
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Column(children: [child])),
);

void main() {
  testWidgets('the strip keeps its height with and without chips', (
    tester,
  ) async {
    var filters = SearchFilters();
    late StateSetter rebuild;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return FilterChipsRow(
              filters: filters,
              onFiltersChanged: (f) => setState(() => filters = f),
              metadata: _FakeMetadataService(),
            );
          },
        ),
      ),
    );

    final empty = tester.getSize(find.byType(FilterChipsRow));
    expect(empty.height, FilterChipsRow.stripHeight);
    expect(find.byType(FilterChipBadge), findsNothing);

    rebuild(() => filters = SearchFilters(genre: const ['action', 'drama']));
    await tester.pump();

    expect(find.byType(FilterChipBadge), findsNWidgets(2));
    expect(tester.getSize(find.byType(FilterChipsRow)), empty);

    await tester.tap(find.byIcon(Icons.restart_alt_rounded));
    await tester.pump();
    expect(filters.isEmpty, isTrue);
  });
}

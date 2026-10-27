import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/home/screens/upcoming_works_screen.dart';
import 'package:mangabaka_app/features/home/services/upcoming_loader.dart';
import 'package:mangabaka_app/features/series/models/series_work.dart';

SeriesWork _work(String id, int seriesId) => SeriesWork(
  id: id,
  seriesId: seriesId,
  seriesTitle: 'Series $seriesId',
  subTitle: '',
  countType: 'main',
  releaseDate: '2099-01-01',
  sequenceString: '1',
  pages: 0,
);

void main() {
  testWidgets('the Library pill narrows the list to library series', (
    tester,
  ) async {
    final data = UpcomingData(
      works: [_work('a', 1), _work('b', 2), _work('c', 3)],
      librarySeriesIds: const {'2'},
      libraryCovers: const {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: UpcomingWorksScreen(initial: data, loader: () async => data),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Series 1'), findsOneWidget);
    expect(find.text('Series 2'), findsOneWidget);
    expect(find.text('Series 3'), findsOneWidget);

    await tester.tap(find.text('LIBRARY'));
    await tester.pumpAndSettle();
    expect(find.text('Series 1'), findsNothing);
    expect(find.text('Series 2'), findsOneWidget);
    expect(find.text('Series 3'), findsNothing);

    await tester.tap(find.text('ALL'));
    await tester.pumpAndSettle();
    expect(find.text('Series 1'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/constants/mock_series_data.dart';
import 'package:mangabaka_app/features/series/mixins/series_detail_data_mixin.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/models/series_cover.dart';
import 'package:mangabaka_app/features/series/models/series_link.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';

class _FakeSeriesService extends SeriesService {
  bool throwOnCovers = false;
  final List<SeriesCover> coversResult;

  _FakeSeriesService({this.coversResult = const [], this.throwOnCovers = false});

  @override
  Future<List<SeriesCover>> fetchSeriesCovers(String id) async {
    if (throwOnCovers) throw Exception('covers error');
    return coversResult;
  }

  @override
  Future<List<Series>> fetchSeriesRelated(String id) async => [];

  @override
  Future<Series> fetchSeries(String id) async => mockSeries222;

  @override
  Future<List<SeriesLink>> fetchSeriesLinks(String id) async => [];
}

class _TestWidget extends StatefulWidget {
  final _FakeSeriesService svc;
  final String tab;
  const _TestWidget({required this.svc, required this.tab});

  @override
  State<_TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<_TestWidget>
    with SeriesDetailDataMixin<_TestWidget> {
  @override
  SeriesService get seriesService => widget.svc;

  @override
  Series get series => mockSeries222;

  @override
  String get selectedTab => widget.tab;

  @override
  Widget build(BuildContext context) => Container();
}

void main() {
  setUpAll(() async {
    await LoggingService.setup();
  });

  group('SeriesDetailDataMixin.fetchTabData', () {
    testWidgets('populates covers on Covers tab', (tester) async {
      final svc = _FakeSeriesService(
        coversResult: [SeriesCover(url: 'https://example.com/c.jpg', index: '1')],
      );
      late _TestWidgetState state;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (ctx) {
            return _TestWidget(svc: svc, tab: 'Covers');
          }),
        ),
      );

      state = tester.state(find.byType(_TestWidget));
      await state.fetchTabData('Covers');
      await tester.pump();

      expect(state.covers, isNotNull);
      expect(state.covers!.length, 1);
    });

    testWidgets('sets fetchError on covers fetch failure', (tester) async {
      final svc = _FakeSeriesService(throwOnCovers: true);
      await tester.pumpWidget(
        MaterialApp(home: _TestWidget(svc: svc, tab: 'Covers')),
      );

      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));
      await state.fetchTabData('Covers');
      await tester.pump();

      expect(state.fetchError, isTrue);
    });

    testWidgets('does not re-fetch covers if already loaded', (tester) async {
      final svc = _FakeSeriesService();

      await tester.pumpWidget(
        MaterialApp(home: _TestWidget(svc: svc, tab: 'Covers')),
      );
      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

      await state.fetchTabData('Covers');
      await state.fetchTabData('Covers');
      await tester.pump();
      // covers is set after first call and stays non-null — no re-fetch
      expect(state.covers, isNotNull);
    });

    testWidgets('unknown tab does not set fetchError', (tester) async {
      final svc = _FakeSeriesService();
      await tester.pumpWidget(
        MaterialApp(home: _TestWidget(svc: svc, tab: 'Unknown')),
      );
      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));
      await state.fetchTabData('NonExistentTab');
      await tester.pump();
      expect(state.fetchError, isFalse);
    });
  });
}

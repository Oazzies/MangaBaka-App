import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/browse/widgets/mix/mix_results_header.dart';
import 'package:mangabaka_app/features/browse/widgets/mix/mix_seed_search_field.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';

const _pick = AutocompleteSeriesResult(
  id: 7,
  title: 'Overlay Pick',
  thumbnailUrl: '',
);

void main() {
  group('MixSeedSearchField', () {
    late TextEditingController text;
    late FocusNode focus;

    setUp(() {
      text = TextEditingController(text: 'over');
      focus = FocusNode();
    });

    tearDown(() {
      text.dispose();
      focus.dispose();
    });

    Widget harness({
      required bool show,
      ValueChanged<AutocompleteSeriesResult>? onSelected,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MixSeedSearchField(
                controller: text,
                focusNode: focus,
                hintText: 'hint',
                suggestions: const [_pick],
                showSuggestions: show,
                onSuggestionSelected: onSelected ?? (_) {},
                onClear: () {},
              ),
              const Text('below', key: Key('below')),
            ],
          ),
        ),
      );
    }

    testWidgets('suggestions float over the content instead of pushing it', (
      tester,
    ) async {
      await tester.pumpWidget(harness(show: false));
      final before = tester.getTopLeft(find.byKey(const Key('below')));
      expect(find.text('Overlay Pick'), findsNothing);

      await tester.pumpWidget(harness(show: true));
      await tester.pumpAndSettle();
      expect(find.text('Overlay Pick'), findsOneWidget);
      expect(tester.getTopLeft(find.byKey(const Key('below'))), before);

      final field = tester.getRect(find.byType(TextField));
      final panel = tester.getRect(find.text('Overlay Pick'));
      expect(panel.top, greaterThan(field.bottom));
    });

    testWidgets('tapping a floating suggestion selects it', (tester) async {
      AutocompleteSeriesResult? selected;
      await tester.pumpWidget(
        harness(show: true, onSelected: (r) => selected = r),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Overlay Pick'));
      await tester.pump();
      expect(selected?.id, 7);
    });
  });

  group('MixResultsHeader', () {
    Widget header({required bool loading}) => MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: MixResultsHeader(
            l10n: LocalizationService(),
            resultCount: 12,
            loading: loading,
          ),
        ),
      ),
    );

    testWidgets('a reload shows a progress line without moving anything', (
      tester,
    ) async {
      await tester.pumpWidget(header(loading: false));
      final idle = tester.getSize(find.byType(MixResultsHeader));
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('12'), findsOneWidget);

      await tester.pumpWidget(header(loading: true));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(tester.getSize(find.byType(MixResultsHeader)), idle);
    });
  });
}

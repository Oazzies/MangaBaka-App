import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/series/widgets/complete_series_dialog.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets(
    'shows status row and checkbox for remaining progress when provided',
    (tester) async {
      CompleteSeriesChoice? result;

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showCompleteSeriesDialog(
                  context,
                  currentState: 'reading',
                  otherProgressLabel: 'Volumes',
                  otherCurrent: 2,
                  otherTotal: 16,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('2 → 16'), findsOneWidget);

      // Uncheck volumes, then tap confirm.
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.markCompleted, isTrue);
      expect(result!.updateOtherProgress, isFalse);
    },
  );

  testWidgets(
    'shows only status row without checkbox when other progress is null',
    (tester) async {
      CompleteSeriesChoice? result;

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showCompleteSeriesDialog(
                  context,
                  currentState: 'reading',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsNothing);

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.markCompleted, isFalse);
      expect(result!.updateOtherProgress, isFalse);
    },
  );
}

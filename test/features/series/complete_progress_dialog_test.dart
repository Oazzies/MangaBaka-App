import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/series/widgets/complete_progress_dialog.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets(
    'shows checkboxes when both chapters and volumes can be updated',
    (tester) async {
      CompleteProgressChoice? result;

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showCompleteProgressDialog(
                  context,
                  currentChapter: 10,
                  totalChapters: 83,
                  currentVolume: 2,
                  totalVolumes: 16,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsNWidgets(2));
      expect(find.text('10 → 83'), findsOneWidget);
      expect(find.text('2 → 16'), findsOneWidget);

      // Uncheck volumes, then tap Update.
      await tester.tap(find.byType(Checkbox).last);
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.updateChapters, isTrue);
      expect(result!.updateVolumes, isFalse);
    },
  );

  testWidgets(
    'shows single row without checkboxes when only chapters can be updated',
    (tester) async {
      CompleteProgressChoice? result;

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showCompleteProgressDialog(
                  context,
                  currentChapter: 10,
                  totalChapters: 83,
                  currentVolume: 16,
                  totalVolumes: 16,
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
      expect(find.text('10 → 83'), findsOneWidget);

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.updateChapters, isFalse);
      expect(result!.updateVolumes, isFalse);
    },
  );
}

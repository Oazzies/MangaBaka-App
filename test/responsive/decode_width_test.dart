import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';

void main() {
  group('WidgetUtils.decodeWidth', () {
    testWidgets('moves in 64px steps, so a resize rarely re-decodes', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      );
      tester.view.devicePixelRatio = 1.25;
      addTearDown(tester.view.reset);
      await tester.pump();

      final widths = {
        for (var w = 150.0; w <= 250; w += 0.5)
          WidgetUtils.decodeWidth(context, w),
      };
      // 100 logical px at 1.25x is 125 physical: two or three steps, not 200.
      expect(widths.length, lessThanOrEqualTo(3));
      for (final w in widths) {
        expect(w % 64, 0);
      }
      // Never below what the display needs.
      expect(WidgetUtils.decodeWidth(context, 200), greaterThanOrEqualTo(250));
    });
  });
}

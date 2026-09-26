import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/theme/app_theme.dart';
import 'package:mangabaka_app/core/theme/presets/theme_presets.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.build(ThemePresets.fallback.dark!, showTooltips: false),
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('MbSpinner', () {
    testWidgets('renders indeterminate at default size', (tester) async {
      await tester.pumpWidget(wrap(const MbSpinner()));
      expect(find.byType(MbSpinner), findsOneWidget);
      expect(tester.getSize(find.byType(MbSpinner)), const Size(24, 24));
    });

    testWidgets('renders at custom sizes', (tester) async {
      await tester.pumpWidget(wrap(const MbSpinner(size: 48)));
      expect(tester.getSize(find.byType(MbSpinner)), const Size(48, 48));
    });

    testWidgets('renders determinate mode with progress value', (tester) async {
      await tester.pumpWidget(wrap(const MbSpinner(value: 0.5, size: 32)));
      expect(find.byType(MbSpinner), findsOneWidget);
      expect(tester.getSize(find.byType(MbSpinner)), const Size(32, 32));
    });

    testWidgets('animates in indeterminate mode', (tester) async {
      await tester.pumpWidget(wrap(const MbSpinner()));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(MbSpinner), findsOneWidget);
    });
  });
}

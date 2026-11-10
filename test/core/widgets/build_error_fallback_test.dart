import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/widgets/build_error_fallback.dart';

void main() {
  testWidgets('renders without a Directionality or theme above it', (
    tester,
  ) async {
    await tester.pumpWidget(const BuildErrorFallback());
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits a tiny slot without overflowing', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(width: 12, height: 12, child: BuildErrorFallback()),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('survives an intrinsic-sizing parent', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: IntrinsicHeight(child: BuildErrorFallback())),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  test('install leaves the debug error screen in place in debug builds', () {
    final before = ErrorWidget.builder;
    BuildErrorFallback.install();
    expect(ErrorWidget.builder, same(before));
  });
}

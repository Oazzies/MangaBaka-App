import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/navigation/screens/animated_splash_screen.dart';

void main() {
  testWidgets('AnimatedSplashOverlay calls onComplete after animation', (WidgetTester tester) async {
    bool completed = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            AnimatedSplashOverlay(
              onComplete: () {
                completed = true;
              },
            ),
          ],
        ),
      ),
    ));

    // Initial state
    expect(find.byType(AnimatedSplashOverlay), findsOneWidget);
    expect(completed, isFalse);

    // Wait for the animation and delay (delay is 800ms, fadeIn 400ms, fadeOut 600ms)
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(completed, isTrue);
  });
}

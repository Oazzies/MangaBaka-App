import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/shared/widgets/app_shortcuts.dart';

void main() {
  group('AppShortcuts', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppShortcuts(
            child: const Text('hello'),
          ),
        ),
      );
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('contains Shortcuts widget wrapping child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppShortcuts(
            child: const SizedBox(),
          ),
        ),
      );
      expect(find.byType(Shortcuts), findsWidgets);
      expect(find.byType(Actions), findsWidgets);
    });

    testWidgets('BackIntent fires on Escape key', (tester) async {
      var backFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.escape): BackIntent(),
            },
            child: Actions(
              actions: {
                BackIntent: CallbackAction<BackIntent>(
                  onInvoke: (_) {
                    backFired = true;
                    return null;
                  },
                ),
              },
              child: Focus(
                autofocus: true,
                child: const SizedBox(),
              ),
            ),
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(backFired, isTrue);
    });
  });
}

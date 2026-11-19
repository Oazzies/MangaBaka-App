import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/profile/screens/translation_credits_screen.dart';

void main() {
  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
  });

  testWidgets('TranslationCreditsScreen renders title and a list', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TranslationCreditsScreen()),
    );
    await tester.pump();

    expect(find.text('TRANSLATION_CREDITS'), findsOneWidget);
    // LocalizationService isn't initialised here, so only the scaffold is checked.
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('back button pops the route', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      home: Builder(builder: (context) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TranslationCreditsScreen()),
                );
              },
              child: const Text('open'),
            ),
          ),
        );
      }),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(TranslationCreditsScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(TranslationCreditsScreen), findsNothing);
  });
}

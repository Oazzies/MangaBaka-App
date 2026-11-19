import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/widgets/adaptive_form.dart';
import 'package:mangabaka_app/features/appearance/widgets/mb_color_picker.dart';

void main() {
  Future<void> openPicker(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showMbColorPicker(
                context,
                initial: const Color(0xFF3366FF),
                title: 'Pick',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a phone in portrait opens the picker as its own page', (
    tester,
  ) async {
    await openPicker(tester, const Size(400, 800));

    expect(find.byType(AdaptiveFormPage), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.text('PICK'),
      findsOneWidget,
      reason: 'only the app bar carries the title',
    );
  });

  testWidgets('landscape opens the picker as a dialog with its own title', (
    tester,
  ) async {
    await openPicker(tester, const Size(900, 500));

    expect(find.byType(AdaptiveFormPage), findsNothing);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('PICK'), findsOneWidget);
  });
}

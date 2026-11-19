import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/library/widgets/library_status_banner.dart';

void main() {
  testWidgets('LibraryStatusBanner displays message and icon', (WidgetTester tester) async {
    bool actionPressed = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LibraryStatusBanner(
          message: 'Test Banner',
          icon: Icons.info,
          color: Colors.blue,
          action: TextButton(
            onPressed: () => actionPressed = true,
            child: const Text('Action'),
          ),
        ),
      ),
    ));

    expect(find.text('Test Banner'), findsOneWidget);
    expect(find.byIcon(Icons.info), findsOneWidget);
    
    await tester.tap(find.text('Action'));
    expect(actionPressed, isTrue);
  });

  testWidgets('LibraryStatusBanner close button works', (WidgetTester tester) async {
    bool closed = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LibraryStatusBanner(
          message: 'Test Banner',
          icon: Icons.info,
          color: Colors.blue,
          onClose: () => closed = true,
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(closed, isTrue);
  });
}

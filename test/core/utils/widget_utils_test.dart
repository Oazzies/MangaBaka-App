import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
  });

  group('WidgetUtils', () {
    testWidgets('responsiveConstraint constrains child width', (WidgetTester tester) async {
      const double maxWidth = 400;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetUtils.responsiveConstraint(
              Container(color: Colors.red),
              maxWidth: maxWidth,
            ),
          ),
        ),
      );

      // Check constraints on the parent ConstrainedBox
      final constrainedBox = tester.widget<ConstrainedBox>(
        find.ancestor(of: find.byType(Container), matching: find.byType(ConstrainedBox)).first
      );
      expect(constrainedBox.constraints.maxWidth, maxWidth);
    });

    testWidgets('AppTooltip shows tooltip when showTooltips is true', (WidgetTester tester) async {
      await SettingsManager().setShowTooltips(true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetUtils.tooltip(
              message: 'Test Tooltip',
              child: const Text('Target'),
            ),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);
      expect((tester.widget<Tooltip>(find.byType(Tooltip))).message, 'Test Tooltip');
    });

    testWidgets('AppTooltip hides tooltip when showTooltips is false', (WidgetTester tester) async {
      await SettingsManager().setShowTooltips(false);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetUtils.tooltip(
              message: 'Test Tooltip',
              child: const Text('Target'),
            ),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsNothing);
      expect(find.text('Target'), findsOneWidget);
    });

    testWidgets('chipWrap returns shrinked box if items are empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetUtils.chipWrap('Label', []),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text('Label'), findsNothing);
    });

    testWidgets('chipWrap displays label and chips', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetUtils.chipWrap('Tags', ['Action', 'Comedy']),
          ),
        ),
      );

      expect(find.text('TAGS'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Comedy'), findsOneWidget);
    });
  });
}

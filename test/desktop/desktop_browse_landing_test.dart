import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/screens/browse/desktop_browse_landing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child, {required double width, double height = 800}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, height: height, child: child),
      ),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
    LocalizationService.resetForTesting();
    await LocalizationService().init();
    DesktopLayout.debugOverride = true;
  });

  tearDown(() => DesktopLayout.debugOverride = null);

  group('DesktopBrowseLanding feature cards', () {
    testWidgets('discovery queue and mix cards match in height when wide', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          DesktopBrowseLanding(
            onNavigate: (_, __, {type}) {},
            onMix: () {},
            onDiscoveryQueue: () {},
          ),
          width: 1400,
        ),
      );
      await tester.pumpAndSettle();

      final queueFinder = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_DiscoveryQueueCard',
      );
      final mixFinder = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_MixCard',
      );

      expect(queueFinder, findsOneWidget);
      expect(mixFinder, findsOneWidget);

      final queueSize = tester.getSize(queueFinder);
      final mixSize = tester.getSize(mixFinder);

      expect(queueSize.height, equals(mixSize.height));
    });

    testWidgets('discovery queue and mix cards match in height when stacked at intermediate width', (
      tester,
    ) async {
      // At width 850px, each card is in a row but cardWidth < 580, so both stack buttons below.
      await tester.pumpWidget(
        _host(
          DesktopBrowseLanding(
            onNavigate: (_, __, {type}) {},
            onMix: () {},
            onDiscoveryQueue: () {},
          ),
          width: 850,
        ),
      );
      await tester.pumpAndSettle();

      final queueFinder = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_DiscoveryQueueCard',
      );
      final mixFinder = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_MixCard',
      );

      expect(queueFinder, findsOneWidget);
      expect(mixFinder, findsOneWidget);

      final queueSize = tester.getSize(queueFinder);
      final mixSize = tester.getSize(mixFinder);

      expect(queueSize.height, equals(mixSize.height));
    });

    testWidgets('discovery queue title is never cut off or truncated across various widths', (
      tester,
    ) async {
      final widths = [
        750.0,
        850.0,
        950.0,
        1050.0,
        1150.0,
        1250.0,
        1400.0,
        1500.0,
        1600.0,
      ];

      for (final width in widths) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          _host(
            DesktopBrowseLanding(
              onNavigate: (_, __, {type}) {},
              onMix: () {},
              onDiscoveryQueue: () {},
            ),
            width: width,
          ),
        );
        await tester.pumpAndSettle();

        final titleFinder = find.text('DISCOVERY QUEUE');
        expect(
          titleFinder,
          findsOneWidget,
          reason: 'Title should exist at width $width',
        );

        final renderParagraph = tester.renderObject<RenderParagraph>(
          titleFinder,
        );
        expect(
          renderParagraph.didExceedMaxLines,
          isFalse,
          reason: 'Discovery Queue title should not be cut off at width $width',
        );

        // Ensure the two cards still match in height when side-by-side
        final queueFinder = find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_DiscoveryQueueCard',
        );
        final mixFinder = find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_MixCard',
        );
        final qSize = tester.getSize(queueFinder);
        final mSize = tester.getSize(mixFinder);

        if (width - 64 >= 720) {
          expect(
            qSize.height,
            equals(mSize.height),
            reason: 'Card heights must match when side-by-side at width $width',
          );
        }
      }
      addTearDown(tester.view.resetPhysicalSize);
    });
  });
}

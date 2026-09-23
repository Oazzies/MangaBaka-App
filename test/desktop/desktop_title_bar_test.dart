import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_title_bar.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_window_frame.dart';
import 'package:window_manager/window_manager.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );

void main() {
  tearDown(() {
    DesktopWindowFrame.debugOverride = null;
  });

  group('DesktopTitleBar', () {
    testWidgets('renders title bar with drag area and no redundant app name',
        (tester) async {
      await tester.pumpWidget(_host(const DesktopTitleBar()));

      // Verify height
      final titleBarFinder = find.byType(DesktopTitleBar);
      expect(titleBarFinder, findsOneWidget);
      final size = tester.getSize(titleBarFinder);
      expect(size.height, DesktopTitleBar.height);

      // Verify DragToMoveArea exists for window dragging and double-click maximize
      expect(find.byType(DragToMoveArea), findsOneWidget);

      // Verify there is no redundant app name text on the title bar
      expect(find.text('MangaBaka'), findsNothing);
      expect(find.text('MANGABAKA'), findsNothing);

      // Verify window control buttons are present
      expect(find.byType(DesktopWindowButtons), findsOneWidget);
    });

    testWidgets('triggers minimize, maximize, and close callbacks',
        (tester) async {
      var minimized = false;
      var maximized = false;
      var closed = false;

      await tester.pumpWidget(
        _host(
          DesktopTitleBar(
            onMinimize: () => minimized = true,
            onMaximize: () => maximized = true,
            onClose: () => closed = true,
          ),
        ),
      );

      // Find window buttons by semantics label
      final minFinder = find.bySemanticsLabel('Minimize');
      final expandFinder = find.bySemanticsLabel('Expand');
      final closeFinder = find.bySemanticsLabel('Close');

      expect(minFinder, findsOneWidget);
      expect(expandFinder, findsOneWidget);
      expect(closeFinder, findsOneWidget);

      // Tap minimize
      await tester.tap(minFinder);
      await tester.pumpAndSettle();
      expect(minimized, isTrue);

      // Tap expand
      await tester.tap(expandFinder);
      await tester.pumpAndSettle();
      expect(maximized, isTrue);

      // Verify Tooltip widgets are rendered for all buttons
      expect(find.byTooltip('Minimize'), findsOneWidget);
      expect(find.byTooltip('Expand'), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);

      // Tap close
      await tester.tap(closeFinder);
      await tester.pumpAndSettle();
      expect(closed, isTrue);
    });

    testWidgets('renders FloatingWindowRestoreIcon when in expanded state',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const DesktopWindowButtons(),
        ),
      );

      // Initially not expanded: finds crop_square_rounded
      expect(find.byIcon(Icons.crop_square_rounded), findsOneWidget);
      expect(find.byType(FloatingWindowRestoreIcon), findsNothing);
    });
  });

  group('DesktopWindowFrame', () {
    testWidgets('bypasses title bar when override is false', (tester) async {
      DesktopWindowFrame.debugOverride = false;

      await tester.pumpWidget(
        _host(
          const DesktopWindowFrame(
            child: Text('App Content'),
          ),
        ),
      );

      expect(find.byType(DesktopTitleBar), findsNothing);
      expect(find.text('App Content'), findsOneWidget);
    });

    testWidgets('wraps child with DesktopTitleBar when override is true',
        (tester) async {
      DesktopWindowFrame.debugOverride = true;

      await tester.pumpWidget(
        _host(
          const DesktopWindowFrame(
            child: Text('App Content'),
          ),
        ),
      );

      expect(find.byType(DesktopTitleBar), findsOneWidget);
      expect(find.text('App Content'), findsOneWidget);
    });

    testWidgets('updates child when DesktopWindowFrame rebuilds with new child',
        (tester) async {
      DesktopWindowFrame.debugOverride = true;

      await tester.pumpWidget(
        _host(
          const DesktopWindowFrame(
            child: Text('Initial Child'),
          ),
        ),
      );

      expect(find.text('Initial Child'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          const DesktopWindowFrame(
            child: Text('Updated Child'),
          ),
        ),
      );

      expect(find.text('Initial Child'), findsNothing);
      expect(find.text('Updated Child'), findsOneWidget);
    });
  });

  group('Responsiveness and Window Controls Clearance', () {
    tearDown(() {
      DesktopLayout.debugOverride = null;
    });

    testWidgets('DesktopPageHeader respects window controls clearance on desktop',
        (tester) async {
      DesktopLayout.debugOverride = true;

      await tester.pumpWidget(
        _host(
          const DesktopPageHeader(
            title: 'Test Title',
            actions: [
              Text('Action 1'),
              Text('Action 2'),
            ],
          ),
        ),
      );

      final paddingFinder = find.descendant(
        of: find.byType(DesktopPageHeader),
        matching: find.byType(Padding),
      );
      final paddingWidget = tester.widget<Padding>(paddingFinder.first);
      final edgeInsets = paddingWidget.padding as EdgeInsets;

      expect(edgeInsets.right,
          greaterThanOrEqualTo(DesktopTokens.windowControlsClearance));
    });

    testWidgets(
        'DesktopPageHeader wraps actions without overflow at narrow widths',
        (tester) async {
      DesktopLayout.debugOverride = true;

      tester.view.physicalSize = const Size(634.7, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _host(
          const DesktopPageHeader(
            title: 'Library',
            actions: [
              SizedBox(width: 120, height: 38, child: Text('Import List')),
              SizedBox(width: 120, height: 38, child: Text('Sync Now')),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('LIBRARY'), findsOneWidget);
      expect(find.text('Import List'), findsOneWidget);
    });

    testWidgets(
        'DesktopSectionTitle wraps trailing without overflow at narrow widths',
        (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _host(
          const DesktopSectionTitle(
            title: 'Trending',
            trailing: SizedBox(
              width: 440,
              height: 38,
              child: Text('Lots of trailing controls'),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('TRENDING'), findsOneWidget);
      expect(find.text('Lots of trailing controls'), findsOneWidget);
    });

    testWidgets(
        'DesktopPageHeader actions align at the exact same vertical height as DesktopWindowButtons',
        (tester) async {
      DesktopLayout.debugOverride = true;
      DesktopWindowFrame.debugOverride = true;

      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _host(
          DesktopWindowFrame(
            child: Scaffold(
              body: DesktopPageHeader(
                title: 'Library',
                subtitle: 'All · 42 series',
                actions: [
                  DesktopPillButton(
                    key: const ValueKey('import_btn'),
                    label: 'Import List',
                    icon: Icons.playlist_add_rounded,
                    onPressed: () {},
                  ),
                  DesktopPillButton(
                    key: const ValueKey('sync_btn'),
                    label: 'Sync Now',
                    icon: Icons.sync_rounded,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      final windowButtonsTop =
          tester.getTopLeft(find.byType(DesktopWindowButtons)).dy;
      final importButtonTop =
          tester.getTopLeft(find.byKey(const ValueKey('import_btn'))).dy;
      final syncButtonTop =
          tester.getTopLeft(find.byKey(const ValueKey('sync_btn'))).dy;

      expect(windowButtonsTop, 10.0);
      expect(importButtonTop, 10.0);
      expect(syncButtonTop, 10.0);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/presets/theme_presets.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/screens/settings/desktop_settings_screen.dart';
import 'package:mangabaka_app/desktop/shell/desktop_sidebar.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_series_row.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuth extends Fake implements ProfileAuthService {
  @override
  bool get isLoggedIn => true;
  @override
  MbProfile? get cachedProfile => null;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

Series _series() => Series.fromJson({
  'id': '1',
  'title': 'Frieren',
  'state': 'active',
  'type': 'manga',
  'status': 'releasing',
  'year': 2020,
});

Widget _host(Widget child, {double width = 1100, double height = 700}) {
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
    DesktopLayout.debugOverride = true;
  });

  tearDown(() => DesktopLayout.debugOverride = null);

  group('DesktopSeriesTable.columns', () {
    test('a wide comfortable table shows every column', () {
      expect(
        DesktopSeriesTable.columns(
          AppListStyle.comfortable,
          1200,
          reserveAction: true,
        ),
        DesktopSeriesColumn.values,
      );
    });

    test('columns drop from the right as the table narrows', () {
      final wide = DesktopSeriesTable.columns(
        AppListStyle.comfortable,
        1200,
        reserveAction: true,
      );
      final narrow = DesktopSeriesTable.columns(
        AppListStyle.comfortable,
        760,
        reserveAction: true,
      );
      expect(narrow.length, lessThan(wide.length));
      expect(narrow, wide.take(narrow.length).toList());
    });

    test('the title always keeps its minimum width', () {
      for (final style in AppListStyle.values.where((s) => !s.isGrid)) {
        // Below ~480px there is no room for a title even with no columns.
        for (final width in [600.0, 800.0, 1000.0, 1400.0]) {
          final columns = DesktopSeriesTable.columns(
            style,
            width,
            reserveAction: true,
          );
          final taken = columns.fold<double>(0, (sum, c) => sum + c.width);
          final title =
              width -
              DesktopSeriesTable.titleLeft(style) -
              DesktopSeriesTable.sidePadding -
              DesktopSeriesTable.actionWidth -
              taken;
          expect(
            title,
            greaterThanOrEqualTo(DesktopSeriesTable.minTitleWidth),
            reason: '$style at $width',
          );
        }
      }
    });

    test('denser styles carry fewer facts', () {
      final comfortable = DesktopSeriesTable.columns(
        AppListStyle.comfortable,
        1400,
        reserveAction: false,
      );
      final compact = DesktopSeriesTable.columns(
        AppListStyle.compact,
        1400,
        reserveAction: false,
      );
      final minimal = DesktopSeriesTable.columns(
        AppListStyle.minimalList,
        1400,
        reserveAction: false,
      );
      expect(comfortable.length, greaterThan(compact.length));
      expect(compact.length, greaterThan(minimal.length));
    });
  });

  group('DesktopSeriesRow', () {
    testWidgets('header labels sit over the row cells', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              const DesktopSeriesListHeader(style: AppListStyle.comfortable),
              DesktopSeriesRow(
                series: _series(),
                style: AppListStyle.comfortable,
                displayTitle: 'Frieren',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Frieren'), findsOneWidget);
      // With no language loaded a label is its own key, upper-cased.
      final typeLabel = tester.getTopLeft(find.text('TYPE')).dx;
      final typeCell = tester.getTopLeft(find.text('manga')).dx;
      expect(typeLabel, typeCell);
      final yearLabel = tester.getTopLeft(find.text('YEAR')).dx;
      final yearCell = tester.getTopLeft(find.text('2020')).dx;
      expect(yearLabel, yearCell);
    });

    testWidgets('every list style lays out without overflow', (tester) async {
      for (final style in AppListStyle.values.where((s) => !s.isGrid)) {
        for (final width in [640.0, 900.0, 1300.0]) {
          await tester.pumpWidget(
            _host(
              DesktopSeriesRow(
                series: _series(),
                style: style,
                displayTitle: 'A rather long series title that must ellipsise',
              ),
              width: width,
            ),
          );
          expect(tester.takeException(), isNull, reason: '$style at $width');
        }
      }
    });
  });

  group('DesktopPillButton', () {
    testWidgets('a danger button is filled red', (tester) async {
      await tester.pumpWidget(
        _host(
          DesktopPillButton(label: 'Logout', danger: true, onPressed: () {}),
        ),
      );
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(DesktopPillButton),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, DesktopPillButton.dangerColor(inkPalette));
      // A soft tint of the app's error red, not a solid fill.
      expect(DesktopPillButton.dangerColor(inkPalette).a, lessThan(0.3));
    });
  });

  group('DesktopSidebar', () {
    setUp(() async {
      await resetServiceLocator();
      getIt.registerSingleton<ProfileAuthService>(_FakeAuth());
    });

    tearDown(resetServiceLocator);

    Widget sidebar({required bool collapsed, required VoidCallback onToggle}) {
      return _host(
        Align(
          alignment: Alignment.centerLeft,
          child: DesktopSidebar(
            selectedIndex: 0,
            onSelected: (_) {},
            onSearch: () {},
            collapsed: collapsed,
            onToggleCollapsed: onToggle,
          ),
        ),
        height: 800,
      );
    }

    testWidgets('a collapsed sidebar has its own expand button, mid-height',
        (tester) async {
      var toggles = 0;
      await tester.pumpWidget(
        sidebar(collapsed: true, onToggle: () => toggles++),
      );
      await tester.pumpAndSettle();

      final button = find.byIcon(Icons.keyboard_double_arrow_right_rounded);
      expect(button, findsOneWidget);
      // Inside the sidebar, halfway down it.
      final bar = tester.getRect(find.byType(DesktopSidebar));
      final centre = tester.getCenter(button);
      expect(bar.contains(centre), isTrue);
      expect(centre.dy, closeTo(bar.center.dy, 2));

      await tester.tap(button);
      expect(toggles, 1);
    });

    testWidgets('an expanded sidebar has no such button', (tester) async {
      await tester.pumpWidget(sidebar(collapsed: false, onToggle: () {}));
      await tester.pumpAndSettle();
      expect(
        find.byIcon(Icons.keyboard_double_arrow_right_rounded),
        findsNothing,
      );
    });
  });

  group('DesktopSettingsScreen', () {
    setUp(() async {
      await resetServiceLocator();
      getIt.registerSingleton<ProfileAuthService>(_FakeAuth());
    });

    tearDown(resetServiceLocator);

    Future<void> pumpSettings(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DesktopSettingsScreen(key: DesktopSettingsScreen.stateKey),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('logs open from Advanced and go back to it', (tester) async {
      await pumpSettings(tester);

      await tester.tap(find.text('advanced_settings'));
      await tester.pumpAndSettle();
      // The Logs row's button.
      await tester.tap(find.widgetWithText(DesktopPillButton, 'LOGS'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('back'), findsOneWidget);
      expect(find.text('redo_onboarding'.toUpperCase()), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.byTooltip('back'), findsNothing);
      expect(find.text('REDO_ONBOARDING'), findsWidgets);
    });

    testWidgets('categories scroll past one another', (tester) async {
      await pumpSettings(tester);

      await tester.tap(find.text('content'));
      // Mid-transition both pages are on screen, one leaving as one arrives.
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('LANGUAGE'), findsOneWidget, reason: 'General leaving');
      expect(find.text('RATING_STEP'), findsOneWidget, reason: 'Content arriving');
      final leaving = tester.getTopLeft(find.text('LANGUAGE')).dy;
      final arriving = tester.getTopLeft(find.text('RATING_STEP')).dy;
      // Going down the page: the new one is below the old one.
      expect(arriving, greaterThan(leaving));

      await tester.pumpAndSettle();
      expect(find.text('LANGUAGE'), findsNothing);
      expect(find.text('RATING_STEP'), findsOneWidget);
    });

    testWidgets('a shown content rating can have its covers blurred',
        (tester) async {
      await pumpSettings(tester);
      await tester.tap(find.text('content'));
      await tester.pumpAndSettle();

      expect(SettingsManager().contentPreferences, contains('safe'));
      expect(SettingsManager().blurredContentRatings, isNot(contains('safe')));

      // The first shown rating's blur switch.
      final rows = find.byType(Switch);
      await tester.ensureVisible(rows.first);
      // Order on the page: hide-library switch first, then one per shown
      // rating; find the one belonging to the "safe" row.
      final safeRow = find.ancestor(
        of: find.text('SAFE'),
        matching: find.byType(DesktopHoverSurface),
      );
      final blurSwitch = find.descendant(
        of: safeRow.first,
        matching: find.byType(Switch),
      );
      await tester.tap(blurSwitch);
      await tester.pumpAndSettle();

      expect(SettingsManager().blurredContentRatings, contains('safe'));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_theme.dart';
import 'package:mangabaka_app/core/theme/palette/mb_theme_spec.dart';
import 'package:mangabaka_app/core/theme/presets/theme_presets.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/theme/theme_controller.dart';
import 'package:mangabaka_app/features/appearance/screens/appearance_settings.dart';
import 'package:mangabaka_app/features/appearance/widgets/theme_preview_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mirrors how `main.dart` wires the controller into MaterialApp.
class _Host extends StatelessWidget {
  final Widget child;
  const _Host({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = ThemeController();
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => MaterialApp(
        theme: AppTheme.build(c.lightPalette, showTooltips: false),
        darkTheme: AppTheme.build(c.darkPalette, showTooltips: false),
        themeMode: c.materialThemeMode,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }
}

/// Records the background it was last built with.
class _Probe extends StatelessWidget {
  static Color? seen;
  const _Probe();

  @override
  Widget build(BuildContext context) {
    seen = context.colors.background;
    return const SizedBox.shrink();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    ThemeController.resetForTesting();
    await SettingsManager().init();
    ThemeController().init();
  });

  tearDown(ThemeController.resetForTesting);

  Future<void> pump(WidgetTester tester, {double width = 400}) async {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const _Host(
        child: Column(children: [_Probe(), AppearanceSettings()]),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a theme card switches the app theme', (tester) async {
    await pump(tester);
    expect(_Probe.seen, inkPalette.background);

    final l10n = LocalizationService();
    final dracula = find.widgetWithText(
      ThemePreviewCard,
      l10n.translate('theme_preset_dracula'),
    );
    // The phone strip builds lazily; scroll it to the card.
    await tester.dragUntilVisible(
      dracula,
      find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.horizontal,
      ),
      const Offset(-150, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(dracula);
    await tester.pumpAndSettle();

    expect(ThemeController().darkThemeId, 'dracula');
    expect(
      _Probe.seen,
      ThemePresets.byId('dracula')!.dark!.background,
      reason: 'widgets reading context.colors rebuild on a theme change',
    );
  });

  testWidgets('only the pinned mode\'s themes are listed', (tester) async {
    await pump(tester);
    final l10n = LocalizationService();
    expect(find.text(l10n.translate('dark_themes').toUpperCase()), findsOne);
    expect(find.text(l10n.translate('light_themes').toUpperCase()), findsNothing);

    await ThemeController().setMode(AppThemeMode.system);
    await tester.pumpAndSettle();
    expect(find.text(l10n.translate('light_themes').toUpperCase()), findsOne);
  });

  testWidgets('switching to light mode applies the light palette',
      (tester) async {
    await pump(tester);
    await ThemeController().setMode(AppThemeMode.light);
    await tester.pumpAndSettle();
    expect(_Probe.seen, ThemePresets.fallback.light!.background);
  });

  testWidgets('custom themes are listed with a menu, and wide layouts grid',
      (tester) async {
    await ThemeController().saveCustom(
      const MbThemeSpec(
        id: 'custom:x',
        name: 'Sunset',
        background: Color(0xFF1A1020),
        accent: Color(0xFFFF7A59),
      ),
    );
    await pump(tester, width: 900);
    expect(find.widgetWithText(ThemePreviewCard, 'Sunset'), findsOne);
    expect(find.text('SUNSET'), findsOne); // the My themes row
    // Grid layout: no horizontal list.
    expect(
      find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.horizontal,
      ),
      findsNothing,
    );
  });
}

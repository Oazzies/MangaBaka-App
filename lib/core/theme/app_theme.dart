import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/theme/app_component_themes.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/mb_colors.dart';
import 'package:mangabaka_app/core/theme/palette/mb_palette.dart';

/// Builds [ThemeData] from an [MbPalette].
class AppTheme {
  AppTheme._();

  static SystemUiOverlayStyle overlayFor(MbPalette p) {
    final icons = p.isDark ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: icons,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
      statusBarBrightness: p.brightness,
    );
  }

  static void applySystemOverlay(MbPalette p) =>
      SystemChrome.setSystemUIOverlayStyle(overlayFor(p));

  static ThemeData build(MbPalette p, {required bool showTooltips}) {
    final base = p.isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    final typography = Typography.material2021(
      platform: TargetPlatform.android,
    );
    final textBase = (p.isDark ? typography.white : typography.black).apply(
      bodyColor: p.text,
      displayColor: p.text,
    );

    return base.copyWith(
      extensions: [MbColors(p)],
      textTheme: AppTypography.textTheme(textBase),
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.accent,
        brightness: p.brightness,
        surface: p.background,
        onSurface: p.text,
        onSurfaceVariant: p.textMuted,
        surfaceContainerLowest: p.background,
        surfaceContainerLow: p.surface,
        surfaceContainer: p.surface,
        surfaceContainerHigh: p.surfaceRaised,
        surfaceContainerHighest: p.surfaceRaised,
        primary: p.accent,
        onPrimary: p.onAccent,
        secondary: p.accent,
        onSecondary: p.onAccent,
        outline: p.border,
        outlineVariant: p.border,
        error: p.error,
        shadow: p.shadow,
        scrim: p.scrim,
      ),
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      cardColor: p.surface,
      iconTheme: IconThemeData(color: p.text),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.accent.withValues(alpha: 0.35),
        selectionHandleColor: p.accent,
      ),
      dividerColor: Colors.transparent,
      tooltipTheme: AppComponentThemes.tooltip(p, showTooltips),
      dialogTheme: AppComponentThemes.dialog(p),
      bottomSheetTheme: AppComponentThemes.bottomSheet(p),
      appBarTheme: AppComponentThemes.appBar(p),
      inputDecorationTheme: AppComponentThemes.inputDecoration(p),
      chipTheme: AppComponentThemes.chip(p),
      cardTheme: AppComponentThemes.card(p),
      textButtonTheme: AppComponentThemes.textButton(p),
      elevatedButtonTheme: AppComponentThemes.elevatedButton(p),
      outlinedButtonTheme: AppComponentThemes.outlinedButton(p),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: p.text),
      ),
      switchTheme: AppComponentThemes.switchTheme(p),
      checkboxTheme: AppComponentThemes.checkbox(p),
      radioTheme: AppComponentThemes.radio(p),
      sliderTheme: AppComponentThemes.slider(p),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.surfaceRaised,
        circularTrackColor: Colors.transparent,
      ),
      tabBarTheme: AppComponentThemes.tabBar(p),
      snackBarTheme: AppComponentThemes.snackBar(p),
      popupMenuTheme: AppComponentThemes.popupMenu(p),
      listTileTheme: AppComponentThemes.listTile(p),
      pageTransitionsTheme: _pageTransitions,
    );
  }

  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeOnlyPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeOnlyPageTransitionsBuilder(),
      TargetPlatform.linux: FadeOnlyPageTransitionsBuilder(),
    },
  );
}

/// A page transition that only fades — no slide, no scale.
class FadeOnlyPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeOnlyPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}

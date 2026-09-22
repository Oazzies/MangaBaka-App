import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/mb_colors.dart';
import 'package:mangabaka_app/core/theme/palette/mb_palette.dart';

/// Builds [ThemeData] from an [MbPalette]: every component theme takes its
/// colours from the palette, and the palette itself rides along as the
/// [MbColors] extension that `context.colors` reads.
///
/// The type scale lives in [AppTypography]; radii in [AppConstants].
class AppTheme {
  AppTheme._();

  /// Overlay style for the status and navigation bars: transparent bars with
  /// icons that contrast with the palette's background.
  ///
  /// Applied both at startup (before any widget exists) and by an
  /// `AnnotatedRegion` around the app, which is what keeps it after a route
  /// or platform change resets it. Shared so the two cannot disagree.
  static SystemUiOverlayStyle overlayFor(MbPalette p) {
    final icons = p.isDark ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: icons,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
      // iOS reads the bar's brightness, not the icons'.
      statusBarBrightness: p.brightness,
    );
  }

  static void applySystemOverlay(MbPalette p) =>
      SystemChrome.setSystemUIOverlayStyle(overlayFor(p));

  /// Builds the theme for [p].
  ///
  /// [showTooltips] is baked in rather than read at each call site: Flutter
  /// has no "off" for tooltips, so disabling them means switching every
  /// tooltip to manual triggering — a theme-level change, and the reason the
  /// caller caches the result and rebuilds it only when an input changes.
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
      // Dividers are drawn deliberately where they are wanted; the implicit
      // ones Material adds inside tab bars and dialogs are noise here.
      dividerColor: Colors.transparent,
      tooltipTheme: _tooltip(p, showTooltips),
      dialogTheme: _dialog(p),
      bottomSheetTheme: _bottomSheet(p),
      appBarTheme: _appBar(p),
      inputDecorationTheme: _inputDecoration(p),
      chipTheme: _chip(p),
      cardTheme: _card(p),
      textButtonTheme: _textButton(p),
      elevatedButtonTheme: _elevatedButton(p),
      outlinedButtonTheme: _outlinedButton(p),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: p.text),
      ),
      switchTheme: _switch(p),
      checkboxTheme: _checkbox(p),
      radioTheme: _radio(p),
      sliderTheme: _slider(p),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.surfaceRaised,
        circularTrackColor: Colors.transparent,
      ),
      tabBarTheme: _tabBar(p),
      snackBarTheme: _snackBar(p),
      popupMenuTheme: _popupMenu(p),
      listTileTheme: _listTile(p),
      pageTransitionsTheme: _pageTransitions,
    );
  }

  /// Flutter cannot disable tooltips outright, so "off" is manual triggering
  /// plus a wait long enough never to elapse. When enabled, snappy 350ms wait duration
  /// with desktop styling.
  static TooltipThemeData _tooltip(MbPalette p, bool showTooltips) =>
      TooltipThemeData(
        triggerMode: showTooltips ? null : TooltipTriggerMode.manual,
        waitDuration: showTooltips
            ? const Duration(milliseconds: 350)
            : const Duration(days: 365),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(
              color: p.shadow,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        textStyle: AppTypography.sans(
          color: p.text,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      );

  static DialogThemeData _dialog(MbPalette p) => DialogThemeData(
    backgroundColor: p.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.largeRadius),
    ),
    titleTextStyle: AppTypography.display(color: p.text, fontSize: 18),
    contentTextStyle: AppTypography.sans(
      color: p.textMuted,
      fontSize: 15,
      height: 1.45,
    ),
  );

  static BottomSheetThemeData _bottomSheet(MbPalette p) => BottomSheetThemeData(
    backgroundColor: p.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppConstants.largeRadius),
      ),
    ),
  );

  static AppBarTheme _appBar(MbPalette p) => AppBarTheme(
    backgroundColor: p.background,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    // Material tints the bar as content scrolls under it; on a near-black
    // surface that reads as the bar changing colour at random.
    scrolledUnderElevation: 0,
    iconTheme: IconThemeData(color: p.text),
    titleTextStyle: AppTypography.display(color: p.text, fontSize: 20),
  );

  static InputDecorationTheme _inputDecoration(MbPalette p) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      borderSide: BorderSide.none,
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: p.surfaceRaised,
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }

  static ChipThemeData _chip(MbPalette p) => ChipThemeData(
    backgroundColor: p.surfaceRaised,
    selectedColor: p.accent,
    side: BorderSide.none,
    labelStyle: AppTypography.display(color: p.text, fontSize: 12),
    secondaryLabelStyle: AppTypography.display(color: p.onAccent, fontSize: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.pillRadius),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  );

  static CardThemeData _card(MbPalette p) => CardThemeData(
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    ),
    color: p.surface,
  );

  // Buttons: amber caps for affirmative actions, muted caps for the rest.

  static TextButtonThemeData _textButton(MbPalette p) => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: p.accent,
      textStyle: AppTypography.display(fontSize: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    ),
  );

  static ElevatedButtonThemeData _elevatedButton(MbPalette p) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          elevation: 0,
          textStyle: AppTypography.display(fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
      );

  static OutlinedButtonThemeData _outlinedButton(MbPalette p) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          side: BorderSide(color: p.border),
          textStyle: AppTypography.display(fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
      );

  // Amber is the "on" state everywhere a control has one.

  static WidgetStateProperty<Color> _whenSelected(Color on, Color off) =>
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? on : off,
      );

  static SwitchThemeData _switch(MbPalette p) => SwitchThemeData(
    thumbColor: _whenSelected(p.onAccent, p.textMuted),
    trackColor: _whenSelected(p.accent, p.surfaceRaised),
    trackOutlineColor: WidgetStateProperty.all(p.border),
    // The default hover/press halo around the thumb reads as a glow.
    overlayColor: WidgetStateProperty.all(Colors.transparent),
  );

  static CheckboxThemeData _checkbox(MbPalette p) => CheckboxThemeData(
    fillColor: _whenSelected(p.accent, Colors.transparent),
    checkColor: WidgetStateProperty.all(p.onAccent),
    side: BorderSide(color: p.border, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
  );

  static RadioThemeData _radio(MbPalette p) =>
      RadioThemeData(fillColor: _whenSelected(p.accent, p.textMuted));

  static SliderThemeData _slider(MbPalette p) => SliderThemeData(
    activeTrackColor: p.accent,
    inactiveTrackColor: p.surfaceRaised,
    thumbColor: p.accent,
    overlayColor: Colors.transparent,
    valueIndicatorColor: p.accent,
    valueIndicatorTextStyle: AppTypography.display(
      color: p.onAccent,
      fontSize: 13,
    ),
    trackHeight: 4,
  );

  static TabBarThemeData _tabBar(MbPalette p) => TabBarThemeData(
    labelColor: p.text,
    unselectedLabelColor: p.textMuted,
    labelStyle: AppTypography.display(fontSize: 13),
    unselectedLabelStyle: AppTypography.display(fontSize: 13),
    indicatorColor: p.accent,
    dividerColor: Colors.transparent,
    overlayColor: WidgetStateProperty.all(Colors.transparent),
  );

  static SnackBarThemeData _snackBar(MbPalette p) => SnackBarThemeData(
    backgroundColor: p.surfaceRaised,
    contentTextStyle: AppTypography.sans(color: p.text, fontSize: 14),
    actionTextColor: p.accent,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.denseRadius),
      side: BorderSide(color: p.border),
    ),
  );

  static PopupMenuThemeData _popupMenu(MbPalette p) => PopupMenuThemeData(
    color: p.surface,
    surfaceTintColor: Colors.transparent,
    textStyle: AppTypography.sans(color: p.text, fontSize: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.denseRadius),
    ),
  );

  static ListTileThemeData _listTile(MbPalette p) => ListTileThemeData(
    iconColor: p.textMuted,
    textColor: p.text,
    titleTextStyle: AppTypography.sans(
      color: p.text,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    subtitleTextStyle: AppTypography.sans(color: p.textMuted, fontSize: 13),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.denseRadius),
    ),
  );

  /// Page transitions match `AppTransitions` so system-pushed routes agree
  /// with the ones the app pushes itself.
  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
    },
  );
}

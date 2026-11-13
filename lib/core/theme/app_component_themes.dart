import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/palette/mb_palette.dart';

/// Component [ThemeData] builders derived from an [MbPalette].
abstract final class AppComponentThemes {
  static TooltipThemeData tooltip(MbPalette p, bool showTooltips) =>
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

  static DialogThemeData dialog(MbPalette p) => DialogThemeData(
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

  static BottomSheetThemeData bottomSheet(MbPalette p) => BottomSheetThemeData(
    backgroundColor: p.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppConstants.largeRadius),
      ),
    ),
  );

  static AppBarTheme appBar(MbPalette p) => AppBarTheme(
    backgroundColor: p.background,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    iconTheme: IconThemeData(color: p.text),
    titleTextStyle: AppTypography.display(color: p.text, fontSize: 20),
  );

  static InputDecorationTheme inputDecoration(MbPalette p) {
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

  static ChipThemeData chip(MbPalette p) => ChipThemeData(
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

  static CardThemeData card(MbPalette p) => CardThemeData(
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    ),
    color: p.surface,
  );

  static TextButtonThemeData textButton(MbPalette p) => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: p.accent,
      textStyle: AppTypography.display(fontSize: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    ),
  );

  static ElevatedButtonThemeData elevatedButton(MbPalette p) =>
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

  static OutlinedButtonThemeData outlinedButton(MbPalette p) =>
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

  static WidgetStateProperty<Color> _whenSelected(Color on, Color off) =>
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? on : off,
      );

  static SwitchThemeData switchTheme(MbPalette p) => SwitchThemeData(
    thumbColor: _whenSelected(p.onAccent, p.textMuted),
    trackColor: _whenSelected(p.accent, p.surfaceRaised),
    trackOutlineColor: WidgetStateProperty.all(p.border),
    overlayColor: WidgetStateProperty.all(Colors.transparent),
  );

  static CheckboxThemeData checkbox(MbPalette p) => CheckboxThemeData(
    fillColor: _whenSelected(p.accent, Colors.transparent),
    checkColor: WidgetStateProperty.all(p.onAccent),
    side: BorderSide(color: p.border, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
  );

  static RadioThemeData radio(MbPalette p) =>
      RadioThemeData(fillColor: _whenSelected(p.accent, p.textMuted));

  static SliderThemeData slider(MbPalette p) => SliderThemeData(
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

  static TabBarThemeData tabBar(MbPalette p) => TabBarThemeData(
    labelColor: p.text,
    unselectedLabelColor: p.textMuted,
    labelStyle: AppTypography.display(fontSize: 13),
    unselectedLabelStyle: AppTypography.display(fontSize: 13),
    indicatorColor: p.accent,
    dividerColor: Colors.transparent,
    overlayColor: WidgetStateProperty.all(Colors.transparent),
  );

  static SnackBarThemeData snackBar(MbPalette p) => SnackBarThemeData(
    backgroundColor: p.surfaceRaised,
    contentTextStyle: AppTypography.sans(color: p.text, fontSize: 14),
    actionTextColor: p.accent,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.denseRadius),
      side: BorderSide(color: p.border),
    ),
  );

  static PopupMenuThemeData popupMenu(MbPalette p) => PopupMenuThemeData(
    color: p.surface,
    surfaceTintColor: Colors.transparent,
    textStyle: AppTypography.sans(color: p.text, fontSize: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.denseRadius),
    ),
  );

  static ListTileThemeData listTile(MbPalette p) => ListTileThemeData(
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
}

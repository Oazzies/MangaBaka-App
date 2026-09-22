import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/mb_colors.dart';
import 'package:mangabaka_app/core/theme/palette/mb_palette.dart';
import 'package:mangabaka_app/core/theme/presets/theme_presets.dart';

export 'package:mangabaka_app/core/theme/palette/mb_palette.dart';

/// The one way widgets read colour: `context.colors.accent`.
///
/// Goes through [Theme.of], so the widget rebuilds when the theme changes.
/// Falls back to the default palette when there is no app theme above (bare
/// widget tests).
extension ThemeColorsContext on BuildContext {
  MbPalette get colors =>
      Theme.of(this).extension<MbColors>()?.palette ?? inkPalette;
}

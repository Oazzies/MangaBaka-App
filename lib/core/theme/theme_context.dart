import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/mb_colors.dart';
import 'package:mangabaka_app/core/theme/palette/mb_palette.dart';
import 'package:mangabaka_app/core/theme/presets/theme_presets.dart';

export 'package:mangabaka_app/core/theme/palette/mb_palette.dart';

extension ThemeColorsContext on BuildContext {
  MbPalette get colors =>
      Theme.of(this).extension<MbColors>()?.palette ?? inkPalette;
}

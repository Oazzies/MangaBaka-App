import 'package:flutter/foundation.dart';
import 'package:mangabaka_app/core/theme/palette/mb_palette.dart';

/// Stored by [id], never list position, so presets can be reordered or retired.
@immutable
class MbThemePreset {
  final String id;

  final String nameKey;

  final MbPalette? dark;
  final MbPalette? light;

  const MbThemePreset({
    required this.id,
    required this.nameKey,
    this.dark,
    this.light,
  }) : assert(dark != null || light != null);

  bool get hasDark => dark != null;
  bool get hasLight => light != null;
}

import 'package:flutter/foundation.dart';
import 'package:mangabaka_app/core/theme/palette/mb_palette.dart';

/// A curated theme: a stable id, a localised name, and a dark and/or light
/// palette.
///
/// Stored preferences reference presets by [id], never by list position, so
/// presets can be reordered, added or retired without corrupting anyone's
/// saved choice (an unknown id falls back to the default).
@immutable
class MbThemePreset {
  final String id;

  /// Key into `assets/lang/*.json`.
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

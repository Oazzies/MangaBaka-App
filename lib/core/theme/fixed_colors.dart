import 'package:flutter/painting.dart';

/// Colours that must *not* follow the theme.
///
/// Anything drawn over cover art, banners or photos sits on arbitrary image
/// content, so it keeps the classic white-on-dark-scrim treatment whether the
/// app is in a dark or a light theme. Platform chrome that has a fixed
/// convention (the Windows close-button red) lives here too.
class FixedColors {
  const FixedColors._();

  /// Text and icons laid over imagery.
  static const Color onImage = Color(0xFFFFFFFF);

  /// Scrims, gradients and viewer backgrounds behind or over imagery.
  static const Color imageScrim = Color(0xFF000000);

  /// Dark pill behind text laid over a cover (progress badges).
  static const Color imageBadge = Color(0xFF121214);

  /// Soft shadow under [imageBadge].
  static const Color imageBadgeShadow = Color(0x4D000000);

  /// Modal dimming. Black reads as "dimmed" over light and dark themes
  /// alike, which is why Material's own barriers are black in both.
  static const Color dim = Color(0xFF000000);

  /// Brand colours of third-party services, shown as-is.
  static const Color discord = Color(0xFF5865F2);

  /// Windows caption-button close hover.
  static const Color windowsClose = Color(0xFFC42B1C);
}

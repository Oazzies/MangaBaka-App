import 'package:flutter/painting.dart';

/// Never themed: drawn over arbitrary imagery or a fixed platform convention.
class FixedColors {
  const FixedColors._();

  static const Color onImage = Color(0xFFFFFFFF);

  static const Color imageScrim = Color(0xFF000000);

  static const Color imageBadge = Color(0xFF121214);

  static const Color imageBadgeShadow = Color(0x4D000000);

  /// Black in light themes too, as Material's own barriers are.
  static const Color dim = Color(0xFF000000);

  static const Color discord = Color(0xFF5865F2);

  static const Color windowsClose = Color(0xFFC42B1C);
}

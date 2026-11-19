import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/palette/mb_palette.dart';

/// Lives in [ThemeData] so MaterialApp's theme animation cross-fades tokens.
@immutable
class MbColors extends ThemeExtension<MbColors> {
  final MbPalette palette;

  const MbColors(this.palette);

  @override
  MbColors copyWith({MbPalette? palette}) => MbColors(palette ?? this.palette);

  @override
  MbColors lerp(covariant MbColors? other, double t) {
    if (other == null) return this;
    return MbColors(MbPalette.lerp(palette, other.palette, t));
  }
}

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/palette/mb_palette.dart';

/// The app's original dark palette, spelled out token by token.
const MbPalette inkPalette = MbPalette(
  brightness: Brightness.dark,
  background: Color(0xFF0B0B0B),
  surface: Color(0xFF151515),
  surfaceRaised: Color(0xFF1F1F1F),
  border: Color(0xFF262626),
  accent: Color(0xFF5BBD74),
  onAccent: Color(0xFF0B140D),
  star: Color(0xFFFBD24B),
  success: Color(0xFF4ADE80),
  warning: Color(0xFFFBD24B),
  error: Color(0xFFF87171),
  info: Color(0xFF60A5FA),
  text: Color(0xFFFFFFFF),
  textMuted: Color(0xFF8E8E8E),
  shadow: Color(0x66000000),
  scrim: Color(0x99000000),
);

/// Accent swatches offered by the accent picker, on top of "theme default".
const List<Color> presetAccentSwatches = [
  Color(0xFF5BBD74),
  Color(0xFFFBD24B),
  Color(0xFFFB923C),
  Color(0xFFF43F5E),
  Color(0xFFF472B6),
  Color(0xFFA78BFA),
  Color(0xFF60A5FA),
  Color(0xFF22D3EE),
  Color(0xFF2DD4BF),
  Color(0xFFA3E635),
];

import 'package:flutter/widgets.dart';

/// Subset Phosphor fonts (MIT): `phosphor_flutter` fails on final `IconData`.
abstract final class MbIcons {
  static const String _regular = 'PhosphorRegular';
  static const String _fill = 'PhosphorFill';

  static const IconData house = IconData(0xe2c6, fontFamily: _regular);
  static const IconData bookmark = IconData(0xe0ea, fontFamily: _regular);
  static const IconData compass = IconData(0xe1c8, fontFamily: _regular);
  static const IconData newspaper = IconData(0xe344, fontFamily: _regular);
  static const IconData user = IconData(0xe4c2, fontFamily: _regular);

  static const IconData houseFill = IconData(0xe2c6, fontFamily: _fill);
  static const IconData bookmarkFill = IconData(0xe0ea, fontFamily: _fill);
  static const IconData compassFill = IconData(0xe1c8, fontFamily: _fill);
  static const IconData newspaperFill = IconData(0xe344, fontFamily: _fill);
  static const IconData userFill = IconData(0xe4c2, fontFamily: _fill);
}

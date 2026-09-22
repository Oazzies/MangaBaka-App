import 'package:flutter/painting.dart';
import 'package:mangabaka_app/core/theme/palette/mb_palette.dart';

/// Fixed categorical hues for data that is not part of the palette (series
/// types). Always read through [forSeriesType], which adjusts the hue to stay
/// legible on the active theme's surfaces.
class CategoryColors {
  const CategoryColors._();

  static const Map<String, Color> _seriesTypes = {
    'manga': Color(0xFF4A90D9),
    'manhwa': Color(0xFF7B68EE),
    'manhua': Color(0xFFE8A838),
    'novel': Color(0xFF50C878),
    'oel': Color(0xFFFF6B6B),
  };

  static Color forSeriesType(String type, MbPalette p) {
    final c = _seriesTypes[type.toLowerCase()];
    return c == null ? p.textMuted : p.legibleOnSurface(c);
  }
}

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/palette/mb_palette.dart';
import 'package:mangabaka_app/core/theme/palette/palette_derivation.dart';
import 'package:mangabaka_app/core/theme/presets/theme_preset.dart';

/// The app's original palette, spelled out token by token rather than derived
/// so the default theme stays pixel-identical to the pre-theming design.
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

/// Every built-in theme, in display order.
///
/// Adding one: append an entry here and its `nameKey` to `assets/lang/en.json`.
/// The theme tests hold every palette to the [PaletteContrast] floors.
class ThemePresets {
  const ThemePresets._();

  static const String defaultId = 'default';

  static MbThemePreset get fallback => all.first;

  static MbThemePreset? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  static final List<MbThemePreset> all = [
    MbThemePreset(
      id: defaultId,
      nameKey: 'theme_preset_default',
      dark: inkPalette,
      light: derivePalette(
        brightness: Brightness.light,
        background: const Color(0xFFF4F3EF),
        surface: const Color(0xFFFFFFFF),
        // Deep enough that white ink wins on it; mid greens pick near-black
        // ink, which reads muddy on a light canvas.
        accent: const Color(0xFF16713A),
        text: const Color(0xFF141414),
      ),
    ),
    MbThemePreset(
      id: 'amoled',
      nameKey: 'theme_preset_amoled',
      dark: derivePalette(
        brightness: Brightness.dark,
        background: const Color(0xFF000000),
        surface: const Color(0xFF0C0C0C),
        surfaceRaised: const Color(0xFF171717),
        border: const Color(0xFF222222),
        accent: const Color(0xFF5BBD74),
        text: const Color(0xFFFFFFFF),
        textMuted: const Color(0xFF8E8E8E),
      ),
    ),
    MbThemePreset(
      id: 'monochrome',
      nameKey: 'theme_preset_monochrome',
      dark: derivePalette(
        brightness: Brightness.dark,
        background: const Color(0xFF0A0A0A),
        accent: const Color(0xFFE5E5E5),
      ),
      light: derivePalette(
        brightness: Brightness.light,
        background: const Color(0xFFF5F5F5),
        surface: const Color(0xFFFFFFFF),
        accent: const Color(0xFF171717),
      ),
    ),
    MbThemePreset(
      id: 'catppuccin',
      nameKey: 'theme_preset_catppuccin',
      // Mocha / Latte.
      dark: derivePalette(
        brightness: Brightness.dark,
        background: const Color(0xFF1E1E2E),
        surface: const Color(0xFF262637),
        surfaceRaised: const Color(0xFF313244),
        border: const Color(0xFF45475A),
        accent: const Color(0xFFCBA6F7),
        text: const Color(0xFFCDD6F4),
        textMuted: const Color(0xFFA6ADC8),
        star: const Color(0xFFF9E2AF),
        success: const Color(0xFFA6E3A1),
        warning: const Color(0xFFFAB387),
        error: const Color(0xFFF38BA8),
        info: const Color(0xFF89B4FA),
      ),
      light: derivePalette(
        brightness: Brightness.light,
        background: const Color(0xFFEFF1F5),
        surface: const Color(0xFFFFFFFF),
        surfaceRaised: const Color(0xFFE6E9EF),
        border: const Color(0xFFCCD0DA),
        accent: const Color(0xFF8839EF),
        text: const Color(0xFF4C4F69),
        textMuted: const Color(0xFF6C6F85),
        star: const Color(0xFFDF8E1D),
        success: const Color(0xFF40A02B),
        warning: const Color(0xFFFE640B),
        error: const Color(0xFFD20F39),
        info: const Color(0xFF1E66F5),
      ),
    ),
    MbThemePreset(
      id: 'dracula',
      nameKey: 'theme_preset_dracula',
      dark: derivePalette(
        brightness: Brightness.dark,
        background: const Color(0xFF21222C),
        surface: const Color(0xFF282A36),
        surfaceRaised: const Color(0xFF343746),
        border: const Color(0xFF44475A),
        accent: const Color(0xFFBD93F9),
        text: const Color(0xFFF8F8F2),
        textMuted: const Color(0xFFA0A7C8),
        star: const Color(0xFFF1FA8C),
        success: const Color(0xFF50FA7B),
        warning: const Color(0xFFFFB86C),
        error: const Color(0xFFFF5555),
        info: const Color(0xFF8BE9FD),
      ),
    ),
    MbThemePreset(
      id: 'nord',
      nameKey: 'theme_preset_nord',
      dark: derivePalette(
        brightness: Brightness.dark,
        background: const Color(0xFF2E3440),
        surface: const Color(0xFF3B4252),
        surfaceRaised: const Color(0xFF434C5E),
        border: const Color(0xFF4C566A),
        accent: const Color(0xFF88C0D0),
        text: const Color(0xFFECEFF4),
        star: const Color(0xFFEBCB8B),
        success: const Color(0xFFA3BE8C),
        warning: const Color(0xFFD08770),
        error: const Color(0xFFBF616A),
        info: const Color(0xFF81A1C1),
      ),
      light: derivePalette(
        brightness: Brightness.light,
        background: const Color(0xFFE5E9F0),
        surface: const Color(0xFFF4F6F9),
        surfaceRaised: const Color(0xFFD8DEE9),
        border: const Color(0xFFC3CBD8),
        accent: const Color(0xFF5E81AC),
        text: const Color(0xFF2E3440),
        textMuted: const Color(0xFF4C566A),
        error: const Color(0xFFBF616A),
      ),
    ),
    MbThemePreset(
      id: 'midnight_dusk',
      nameKey: 'theme_preset_midnight_dusk',
      dark: derivePalette(
        brightness: Brightness.dark,
        background: const Color(0xFF0B0F19),
        accent: const Color(0xFFF43F5E),
      ),
      light: derivePalette(
        brightness: Brightness.light,
        background: const Color(0xFFF3F4F6),
        surface: const Color(0xFFFFFFFF),
        accent: const Color(0xFFE11D48),
        text: const Color(0xFF030712),
      ),
    ),
    MbThemePreset(
      id: 'strawberry',
      nameKey: 'theme_preset_strawberry',
      dark: derivePalette(
        brightness: Brightness.dark,
        background: const Color(0xFF1A0B11),
        accent: const Color(0xFFFB7185),
        text: const Color(0xFFFFF1F2),
      ),
      light: derivePalette(
        brightness: Brightness.light,
        background: const Color(0xFFFFF1F2),
        surface: const Color(0xFFFFFFFF),
        accent: const Color(0xFFE11D48),
        text: const Color(0xFF4C0519),
      ),
    ),
    MbThemePreset(
      id: 'tako',
      nameKey: 'theme_preset_tako',
      dark: derivePalette(
        brightness: Brightness.dark,
        background: const Color(0xFF17131C),
        accent: const Color(0xFFF3B375),
        text: const Color(0xFFF3EEF8),
      ),
      light: derivePalette(
        brightness: Brightness.light,
        background: const Color(0xFFF7F4FB),
        surface: const Color(0xFFFFFFFF),
        accent: const Color(0xFF66577E),
        text: const Color(0xFF221A2C),
      ),
    ),
    MbThemePreset(
      id: 'yotsuba',
      nameKey: 'theme_preset_yotsuba',
      dark: derivePalette(
        brightness: Brightness.dark,
        background: const Color(0xFF17110E),
        accent: const Color(0xFFFB923C),
        text: const Color(0xFFFFF7ED),
      ),
      light: derivePalette(
        brightness: Brightness.light,
        background: const Color(0xFFFFF7ED),
        surface: const Color(0xFFFFFFFF),
        accent: const Color(0xFFC2410C),
        text: const Color(0xFF2A140A),
      ),
    ),
    MbThemePreset(
      id: 'green_apple',
      nameKey: 'theme_preset_green_apple',
      dark: derivePalette(
        brightness: Brightness.dark,
        background: const Color(0xFF0B1220),
        accent: const Color(0xFF84CC16),
        text: const Color(0xFFF1F5F9),
      ),
      light: derivePalette(
        brightness: Brightness.light,
        background: const Color(0xFFF1F5F9),
        surface: const Color(0xFFFFFFFF),
        accent: const Color(0xFF4D7C0F),
        text: const Color(0xFF020617),
      ),
    ),
    MbThemePreset(
      id: 'teal',
      nameKey: 'theme_preset_teal',
      dark: derivePalette(
        brightness: Brightness.dark,
        background: const Color(0xFF071A1A),
        accent: const Color(0xFF2DD4BF),
        text: const Color(0xFFF0FDFA),
      ),
      light: derivePalette(
        brightness: Brightness.light,
        background: const Color(0xFFF0FDFA),
        surface: const Color(0xFFFFFFFF),
        accent: const Color(0xFF0F766E),
        text: const Color(0xFF042F2E),
      ),
    ),
    MbThemePreset(
      id: 'tidal_wave',
      nameKey: 'theme_preset_tidal_wave',
      dark: derivePalette(
        brightness: Brightness.dark,
        background: const Color(0xFF071826),
        accent: const Color(0xFF38BDF8),
        text: const Color(0xFFF0F9FF),
      ),
      light: derivePalette(
        brightness: Brightness.light,
        background: const Color(0xFFF0F9FF),
        surface: const Color(0xFFFFFFFF),
        accent: const Color(0xFF0369A1),
        text: const Color(0xFF082F49),
      ),
    ),
    MbThemePreset(
      id: 'lavender',
      nameKey: 'theme_preset_lavender',
      dark: derivePalette(
        brightness: Brightness.dark,
        background: const Color(0xFF130F1E),
        accent: const Color(0xFFA78BFA),
        text: const Color(0xFFF5F3FF),
      ),
      light: derivePalette(
        brightness: Brightness.light,
        background: const Color(0xFFF5F3FF),
        surface: const Color(0xFFFFFFFF),
        accent: const Color(0xFF6D28D9),
        text: const Color(0xFF2E1065),
      ),
    ),
  ];

  /// Accent swatches offered by the accent picker, on top of "theme default".
  static const List<Color> accentSwatches = [
    Color(0xFF5BBD74), // emerald
    Color(0xFFFBD24B), // amber
    Color(0xFFFB923C), // orange
    Color(0xFFF43F5E), // rose
    Color(0xFFF472B6), // pink
    Color(0xFFA78BFA), // violet
    Color(0xFF60A5FA), // blue
    Color(0xFF22D3EE), // cyan
    Color(0xFF2DD4BF), // teal
    Color(0xFFA3E635), // lime
  ];
}

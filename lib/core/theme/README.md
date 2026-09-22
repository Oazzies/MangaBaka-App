# Theming

Every colour in the app comes from the active **`MbPalette`**. Themes change
colours only; fonts (`AppTypography`) and radii (`AppConstants`) are fixed.

## Reading colours

```dart
import 'package:mangabaka_app/core/theme/theme_context.dart';

Container(color: context.colors.surface)
Text('Hi', style: AppTypography.sans(color: context.colors.textMuted))
```

- `context.colors` goes through `Theme.of`, so the widget rebuilds (and
  cross-fades) when the theme changes. It is the **only** way to read colour.
- No `Color(0x…)`, `Colors.white/black` or cached colours outside
  `lib/core/theme/`. `test/core/theme/theme_guard_test.dart` fails the build
  on any.
- Don't read colours in `initState` or store them in fields; read them in
  `build`.
- Code without a `BuildContext` (painters, static helpers) takes a `Color` or
  an `MbPalette` parameter from its caller.

## Choosing a token

| Need | Token |
|---|---|
| Page canvas | `background` |
| Cards, sheets, dialogs, menus | `surface` |
| Inputs, chips, tracks, pressed rows | `surfaceRaised` |
| Hairlines | `border` |
| The "on" state and primary action | `accent`; ink on it is `onAccent` |
| Body text / secondary text | `text` / `textMuted` |
| Ratings | `star` |
| Status | `success`, `warning`, `error`, `info` |
| Library state (`reading`, …) | `forState(key)`; ink on it is `onForState(key)` |
| Ink on any other fill | `on(fill)` |
| Hover or pressed step of a filled control | `hoverOf(color)` |
| Drop shadows | `shadowAt(alpha)` (softer automatically on light themes) or `softShadow` |
| Chrome that recedes behind the page | `backgroundDeep` |
| Categorical hue (series type) | `CategoryColors.forSeriesType(type, palette)` |

Light themes exist, so never assume the background is dark. Something that
"lightens on hover" should use `hoverOf`, not a blend toward white.

**Over cover art or photos**, colour must *not* follow the theme. Use
`FixedColors.onImage` for text and icons, and `FixedColors.imageScrim` or
`FixedColors.imageBadge` for backgrounds. Modal dimming is `FixedColors.dim`.

## Layout of this folder

| File | Role |
|---|---|
| `palette/mb_palette.dart` | The token set, plus helpers (`lerp`, JSON, `forState`, …) |
| `palette/palette_derivation.dart` | `derivePalette()` turns a few seeds into a full palette that meets the contrast floors (`PaletteContrast`) |
| `palette/mb_theme_spec.dart` | A user-made theme: seeds, a name, and the share-code format |
| `palette/color_math.dart` | Contrast, hex, and legible-ink helpers |
| `presets/theme_presets.dart` | The built-in themes, looked up by stable string id |
| `theme_controller.dart` | Resolves settings (mode, dark/light theme ids, accent, custom themes) into palettes. It is the only API for changing them |
| `mb_colors.dart` / `theme_context.dart` | Put the palette into `ThemeData` and read it back out |
| `app_theme.dart` | Builds `ThemeData` (every Material component theme) from a palette |
| `fixed_colors.dart` | The few colours that deliberately ignore the theme |

## Adding a token

1. Add the field to `MbPalette`: the constructor, `copyWith`, `lerp` and
   `tokens`.
2. Derive it in `derivePalette()`, with a contrast floor if it carries text or
   state.
3. If it needs a Material component default, set that in `AppTheme.build`.
4. `palette_test.dart` covers it across every preset; add it to
   `expectLegible` if it has a legibility requirement.

## Adding a preset

1. Append an `MbThemePreset` to `ThemePresets.all`. Give it a new, stable
   `id`, and a `dark` palette, a `light` palette, or both, built with
   `derivePalette`.
2. Add its `nameKey` to `assets/lang/en.json`.
3. Run `flutter test test/core/theme`. The contrast tests must pass.

The settings UI (`lib/features/appearance/`,
`lib/desktop/screens/settings/desktop_appearance_page.dart`) lists presets
automatically.

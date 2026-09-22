import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/palette/mb_palette.dart';
import 'package:mangabaka_app/core/theme/palette/mb_theme_spec.dart';
import 'package:mangabaka_app/core/theme/palette/palette_derivation.dart';
import 'package:mangabaka_app/core/theme/presets/theme_preset.dart';
import 'package:mangabaka_app/core/theme/presets/theme_presets.dart';

/// One entry in a theme picker: a preset or a custom theme, reduced to what
/// the picker shows.
@immutable
class ThemeChoice {
  final String id;

  /// Localisation key for presets; null for custom themes.
  final String? nameKey;

  /// Display name for custom themes; null for presets.
  final String? customName;
  final MbPalette palette;

  const ThemeChoice({
    required this.id,
    required this.palette,
    this.nameKey,
    this.customName,
  });

  bool get isCustom => id.startsWith(MbThemeSpec.idPrefix);
}

/// Resolves the stored appearance preferences into the palettes the app
/// paints with, and is the only API the UI uses to change them.
///
/// Persistence stays in [SettingsManager] with every other preference; this
/// class listens to it, re-resolves, and notifies only when a resolved
/// palette (or the mode) actually changed — so an unrelated setting toggle
/// never rebuilds the theme. It also follows the OS light/dark switch.
class ThemeController extends ChangeNotifier with WidgetsBindingObserver {
  static final ThemeController _instance = ThemeController._internal();
  factory ThemeController() => _instance;
  ThemeController._internal();

  final SettingsManager _settings = SettingsManager();
  bool _initialised = false;

  MbPalette _dark = inkPalette;
  MbPalette _light = ThemePresets.fallback.light!;
  AppThemeMode _mode = AppThemeMode.dark;
  List<MbThemeSpec> _custom = const [];
  List<String>? _lastEncodedCustom;

  /// Call once after [SettingsManager.init].
  void init() {
    if (_initialised) return;
    _initialised = true;
    WidgetsBinding.instance.addObserver(this);
    _settings.addListener(_resolve);
    _resolve(notify: false);
  }

  @visibleForTesting
  static void resetForTesting() {
    final c = _instance;
    if (c._initialised) {
      WidgetsBinding.instance.removeObserver(c);
      c._settings.removeListener(c._resolve);
    }
    c._initialised = false;
    c._dark = inkPalette;
    c._light = ThemePresets.fallback.light!;
    c._mode = AppThemeMode.dark;
    c._custom = const [];
    c._lastEncodedCustom = null;
  }

  // ─── Resolved state ──────────────────────────────────────────────────────

  AppThemeMode get mode => _mode;

  MbPalette get darkPalette => _dark;
  MbPalette get lightPalette => _light;

  ThemeMode get materialThemeMode => switch (_mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  /// The palette on screen right now.
  MbPalette get current => switch (_mode) {
    AppThemeMode.light => _light,
    AppThemeMode.dark => _dark,
    AppThemeMode.system =>
      _platformBrightness == Brightness.light ? _light : _dark,
  };

  Brightness get _platformBrightness =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  String get darkThemeId => _settings.darkThemeId;
  String get lightThemeId => _settings.lightThemeId;

  /// The accent override, or null when the theme's own accent is used.
  Color? get accentOverride {
    final v = _settings.accentOverride;
    return v == 0 ? null : Color(v);
  }

  List<MbThemeSpec> get customThemes => _custom;

  /// Everything selectable for the dark (or light) slot: presets with that
  /// variant, then custom themes of that brightness. Palettes are shown
  /// *without* the accent override, so the cards show each theme as designed.
  List<ThemeChoice> choicesFor(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return [
      for (final p in ThemePresets.all)
        if (dark ? p.hasDark : p.hasLight)
          ThemeChoice(
            id: p.id,
            nameKey: p.nameKey,
            palette: dark ? p.dark! : p.light!,
          ),
      for (final c in _custom)
        if (c.brightness == brightness)
          ThemeChoice(id: c.id, customName: c.name, palette: c.palette),
    ];
  }

  MbThemeSpec? customById(String id) {
    for (final c in _custom) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ─── Mutations ───────────────────────────────────────────────────────────

  Future<void> setMode(AppThemeMode mode) => _settings.setThemeMode(mode);

  /// Selects [id] for the slot matching [brightness].
  Future<void> select(String id, Brightness brightness) =>
      brightness == Brightness.dark
      ? _settings.setDarkThemeId(id)
      : _settings.setLightThemeId(id);

  /// Picking a theme from a single combined list: switches the pinned mode
  /// to that theme's brightness too, unless the app is following the system.
  Future<void> apply(String id, Brightness brightness) async {
    await select(id, brightness);
    if (_mode != AppThemeMode.system) {
      await setMode(
        brightness == Brightness.dark ? AppThemeMode.dark : AppThemeMode.light,
      );
    }
  }

  Future<void> setAccentOverride(Color? color) =>
      _settings.setAccentOverride(color == null ? 0 : color.toARGB32());

  /// Adds or replaces (by id) a custom theme.
  Future<void> saveCustom(MbThemeSpec spec) {
    final next = [
      for (final c in _custom)
        if (c.id != spec.id) c,
    ];
    final existing = _custom.indexWhere((c) => c.id == spec.id);
    if (existing >= 0) {
      next.insert(existing, spec);
    } else {
      next.add(spec);
    }
    return _settings.setCustomThemes([for (final c in next) c.encode()]);
  }

  /// Removes a custom theme; any slot pointing at it falls back to default.
  Future<void> deleteCustom(String id) async {
    if (_settings.darkThemeId == id) {
      await _settings.setDarkThemeId(ThemePresets.defaultId);
    }
    if (_settings.lightThemeId == id) {
      await _settings.setLightThemeId(ThemePresets.defaultId);
    }
    await _settings.setCustomThemes([
      for (final c in _custom)
        if (c.id != id) c.encode(),
    ]);
  }

  /// Parses a share code and saves it. Returns the saved theme, or null if
  /// the code was not a valid theme.
  Future<MbThemeSpec?> importShareCode(String code) async {
    final spec = MbThemeSpec.fromShareCode(code);
    if (spec == null) return null;
    await saveCustom(spec);
    return spec;
  }

  // ─── Resolution ──────────────────────────────────────────────────────────

  @override
  void didChangePlatformBrightness() {
    if (_mode == AppThemeMode.system) notifyListeners();
  }

  void _resolve({bool notify = true}) {
    final encoded = _settings.customThemes;
    if (!identical(encoded, _lastEncodedCustom)) {
      _lastEncodedCustom = encoded;
      _custom = [for (final e in encoded) ?MbThemeSpec.decode(e)];
    }

    final accent = accentOverride;
    MbPalette withOverride(MbPalette p) =>
        accent == null ? p : withAccent(p, accent);

    final dark = withOverride(
      _paletteFor(_settings.darkThemeId, Brightness.dark),
    );
    final light = withOverride(
      _paletteFor(_settings.lightThemeId, Brightness.light),
    );
    final mode = _settings.themeMode;

    final changed = dark != _dark || light != _light || mode != _mode;
    _dark = dark;
    _light = light;
    _mode = mode;
    if (changed && notify) notifyListeners();
  }

  /// Unknown ids (a deleted custom theme, a retired preset) and presets
  /// lacking the requested variant fall back to the default theme.
  MbPalette _paletteFor(String id, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final custom = customById(id);
    if (custom != null && custom.brightness == brightness) {
      return custom.palette;
    }
    final MbThemePreset preset = ThemePresets.byId(id) ?? ThemePresets.fallback;
    final p = dark ? preset.dark : preset.light;
    if (p != null) return p;
    return dark ? ThemePresets.fallback.dark! : ThemePresets.fallback.light!;
  }
}

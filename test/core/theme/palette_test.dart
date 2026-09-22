import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/theme/palette/color_math.dart';
import 'package:mangabaka_app/core/theme/palette/mb_palette.dart';
import 'package:mangabaka_app/core/theme/palette/mb_theme_spec.dart';
import 'package:mangabaka_app/core/theme/palette/palette_derivation.dart';
import 'package:mangabaka_app/core/theme/presets/theme_presets.dart';

/// The legibility bar every palette — preset, accent-overridden or custom —
/// has to clear. A new token that carries text or UI state belongs here.
void expectLegible(MbPalette p, String name) {
  double c(Color a, Color b) => ColorMath.contrast(a, b);
  final surfaces = {
    'background': p.background,
    'surface': p.surface,
    'surfaceRaised': p.surfaceRaised,
  };
  for (final s in surfaces.entries) {
    expect(c(p.text, s.value), greaterThanOrEqualTo(4.5),
        reason: '$name: text on ${s.key}');
    expect(c(p.textMuted, s.value), greaterThanOrEqualTo(PaletteContrast.textMuted - 0.01),
        reason: '$name: textMuted on ${s.key}');
  }
  expect(c(p.text, p.background), greaterThanOrEqualTo(PaletteContrast.text),
      reason: '$name: text on background');
  expect(c(p.onAccent, p.accent), greaterThanOrEqualTo(PaletteContrast.onAccent),
      reason: '$name: onAccent on accent');
  for (final t in {
    'accent': p.accent,
    'star': p.star,
    'success': p.success,
    'warning': p.warning,
    'error': p.error,
    'info': p.info,
  }.entries) {
    expect(c(t.value, p.surface), greaterThanOrEqualTo(PaletteContrast.ui - 0.01),
        reason: '$name: ${t.key} on surface');
  }
  // Layers must be distinguishable from each other, however subtly.
  expect(p.surfaceRaised, isNot(p.background), reason: '$name: layers');
  expect(p.border, isNot(p.surface), reason: '$name: border');
  for (final state in const [
    'reading', 'completed', 'paused', 'dropped', 'plan_to_read', 'considering',
  ]) {
    expect(c(p.onForState(state), p.forState(state)), greaterThanOrEqualTo(4.5),
        reason: '$name: on-$state');
  }
}

void main() {
  group('presets', () {
    test('ids are unique and the default comes first', () {
      final ids = ThemePresets.all.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids.first, ThemePresets.defaultId);
    });

    test('default dark is the original palette, untouched', () {
      final p = ThemePresets.fallback.dark!;
      expect(p.background, const Color(0xFF0B0B0B));
      expect(p.surface, const Color(0xFF151515));
      expect(p.surfaceRaised, const Color(0xFF1F1F1F));
      expect(p.border, const Color(0xFF262626));
      expect(p.accent, const Color(0xFF5BBD74));
      expect(p.onAccent, const Color(0xFF0B140D));
      expect(p.text, const Color(0xFFFFFFFF));
      expect(p.textMuted, const Color(0xFF8E8E8E));
    });

    for (final preset in ThemePresets.all) {
      if (preset.dark != null) {
        test('${preset.id} dark is legible', () {
          expect(preset.dark!.brightness, Brightness.dark);
          expectLegible(preset.dark!, '${preset.id}/dark');
        });
      }
      if (preset.light != null) {
        test('${preset.id} light is legible', () {
          expect(preset.light!.brightness, Brightness.light);
          expectLegible(preset.light!, '${preset.id}/light');
        });
      }
    }
  });

  group('derivation', () {
    test('any accent on any preset stays legible', () {
      final rng = math.Random(7);
      for (final preset in ThemePresets.all) {
        for (final base in [preset.dark, preset.light].whereType<MbPalette>()) {
          for (var i = 0; i < 40; i++) {
            final accent = Color(0xFF000000 | rng.nextInt(0xFFFFFF));
            expectLegible(withAccent(base, accent), '${preset.id}+$accent');
          }
        }
      }
    });

    test('random custom seeds produce legible palettes', () {
      final rng = math.Random(11);
      for (var i = 0; i < 300; i++) {
        final spec = MbThemeSpec(
          id: '${MbThemeSpec.idPrefix}$i',
          name: 't$i',
          background: Color(0xFF000000 | rng.nextInt(0xFFFFFF)),
          accent: Color(0xFF000000 | rng.nextInt(0xFFFFFF)),
          text: i % 3 == 0 ? Color(0xFF000000 | rng.nextInt(0xFFFFFF)) : null,
        );
        final p = spec.palette;
        expect(p.brightness, spec.brightness);
        final c = ColorMath.contrast;
        expect(c(p.text, p.background), greaterThanOrEqualTo(4.5),
            reason: 'spec $i text');
        expect(c(p.onAccent, p.accent), greaterThanOrEqualTo(4.5),
            reason: 'spec $i onAccent');
      }
    });
  });

  group('serialisation', () {
    const spec = MbThemeSpec(
      id: 'custom:abc',
      name: 'Night Shift',
      background: Color(0xFF101418),
      accent: Color(0xFFFF8800),
      surface: Color(0xFF182028),
    );

    test('spec JSON round-trips', () {
      expect(MbThemeSpec.decode(spec.encode()), spec);
    });

    test('share code round-trips with a fresh id', () {
      final imported = MbThemeSpec.fromShareCode(spec.toShareCode())!;
      expect(imported.id, isNot(spec.id));
      expect(imported.copyWith(id: spec.id), spec);
    });

    test('garbage is rejected, not thrown', () {
      expect(MbThemeSpec.fromShareCode('hello'), isNull);
      expect(MbThemeSpec.fromShareCode('mbtheme1:%%%'), isNull);
      expect(MbThemeSpec.decode('{"id":"preset"}'), isNull);
    });

    test('palette JSON round-trips', () {
      final p = ThemePresets.all[3].light!;
      expect(MbPalette.fromJson(p.toJson()), p);
    });

    test('hex parse and format', () {
      expect(ColorMath.parseHex('#5bbd74'), const Color(0xFF5BBD74));
      expect(ColorMath.parseHex('fff'), const Color(0xFFFFFFFF));
      expect(ColorMath.parseHex('nope'), isNull);
      expect(ColorMath.toHex(const Color(0xFF5BBD74)), '#5BBD74');
    });
  });
}

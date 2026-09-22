import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/palette/color_math.dart';
import 'package:mangabaka_app/core/theme/palette/mb_palette.dart';
import 'package:mangabaka_app/core/theme/palette/palette_derivation.dart';

/// A user-made theme: a name plus the few seeds a person actually picks. The
/// full palette is always derived, so custom themes pick up new tokens and
/// contrast fixes for free and can never be saved in an illegible state.
@immutable
class MbThemeSpec {
  /// Stable id, prefixed `custom:` so it can share the id space with presets.
  final String id;
  final String name;
  final Color background;
  final Color accent;
  final Color? surface;
  final Color? text;

  const MbThemeSpec({
    required this.id,
    required this.name,
    required this.background,
    required this.accent,
    this.surface,
    this.text,
  });

  static const String idPrefix = 'custom:';
  static const String _exportPrefix = 'mbtheme1:';
  static const int maxNameLength = 32;

  /// Follows the background, so a theme can never be a "dark" theme with a
  /// pale canvas (which would flip status-bar icons and Material defaults the
  /// wrong way).
  Brightness get brightness =>
      ColorMath.isDark(background) ? Brightness.dark : Brightness.light;

  static String newId() =>
      '$idPrefix${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  MbPalette get palette => derivePalette(
    brightness: brightness,
    background: background,
    accent: accent,
    surface: surface,
    text: text,
  );

  MbThemeSpec copyWith({
    String? id,
    String? name,
    Color? background,
    Color? accent,
    Color? surface,
    Color? text,
    bool clearSurface = false,
    bool clearText = false,
  }) {
    return MbThemeSpec(
      id: id ?? this.id,
      name: name ?? this.name,
      background: background ?? this.background,
      accent: accent ?? this.accent,
      surface: clearSurface ? null : (surface ?? this.surface),
      text: clearText ? null : (text ?? this.text),
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'background': background.toARGB32(),
    'accent': accent.toARGB32(),
    if (surface != null) 'surface': surface!.toARGB32(),
    if (text != null) 'text': text!.toARGB32(),
  };

  /// Returns null for anything malformed — stored or imported data is never
  /// trusted to be well-formed.
  static MbThemeSpec? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final name = raw['name'];
    final bg = raw['background'];
    final accent = raw['accent'];
    if (id is! String || !id.startsWith(idPrefix)) return null;
    if (name is! String || bg is! int || accent is! int) return null;
    final surface = raw['surface'];
    final text = raw['text'];
    return MbThemeSpec(
      id: id,
      name: _cleanName(name),
      background: Color(0xFF000000 | (bg & 0xFFFFFF)),
      accent: Color(0xFF000000 | (accent & 0xFFFFFF)),
      surface: surface is int ? Color(0xFF000000 | (surface & 0xFFFFFF)) : null,
      text: text is int ? Color(0xFF000000 | (text & 0xFFFFFF)) : null,
    );
  }

  String encode() => jsonEncode(toJson());

  static MbThemeSpec? decode(String stored) {
    try {
      return fromJson(jsonDecode(stored));
    } catch (_) {
      return null;
    }
  }

  /// Shareable one-line code: `mbtheme1:<base64url json>`.
  String toShareCode() =>
      '$_exportPrefix${base64Url.encode(utf8.encode(encode()))}';

  /// Parses a share code. The imported theme gets a fresh id so importing the
  /// same code twice, or a code made from one of your own themes, never
  /// overwrites anything.
  static MbThemeSpec? fromShareCode(String code) {
    final trimmed = code.trim();
    if (!trimmed.startsWith(_exportPrefix)) return null;
    try {
      final json = utf8.decode(
        base64Url.decode(
          base64Url.normalize(trimmed.substring(_exportPrefix.length)),
        ),
      );
      return decode(json)?.copyWith(id: newId());
    } catch (_) {
      return null;
    }
  }

  static String _cleanName(String name) {
    final t = name.trim();
    if (t.isEmpty) return 'Custom';
    return t.length > maxNameLength ? t.substring(0, maxNameLength) : t;
  }

  @override
  bool operator ==(Object other) =>
      other is MbThemeSpec &&
      other.id == id &&
      other.name == name &&
      other.background == background &&
      other.accent == accent &&
      other.surface == surface &&
      other.text == text;

  @override
  int get hashCode => Object.hash(id, name, background, accent, surface, text);
}

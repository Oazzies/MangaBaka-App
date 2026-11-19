import 'dart:collection';

import 'package:mangabaka_app/core/settings/settings_enums.dart';

part 'series_titles_parser.dart';

/// v1 sends an editorial (canonical) `title`; v2 sends only `titles[]`, all `is_primary`, so main is guessed.
/// Canonical titles are remembered ([remember]) so a v2 guess never contradicts a v1 title seen earlier.
class SeriesTitles {
  final String main;

  final String native;

  final String romanized;

  final List<String> secondary;

  final bool canonical;

  const SeriesTitles({
    this.main = '',
    this.native = '',
    this.romanized = '',
    this.secondary = const [],
    this.canonical = false,
  });

  static const SeriesTitles empty = SeriesTitles();

  String display(TitleLanguage preference) {
    final t = choose(
      preference,
      main: main,
      native: native,
      romanized: romanized,
    );
    if (t.isNotEmpty) return t;
    return secondary.isNotEmpty ? secondary.first : '';
  }

  /// [display] without building a [SeriesTitles]: list rows call this on every build.
  static String choose(
    TitleLanguage preference, {
    required String main,
    required String native,
    required String romanized,
  }) {
    final order = switch (preference) {
      TitleLanguage.defaultLang => [main, romanized, native],
      TitleLanguage.native => [native, romanized, main],
      TitleLanguage.romanized => [romanized, main, native],
    };
    for (final t in order) {
      if (t.isNotEmpty) return t;
    }
    return '';
  }

  List<String> alternatives(TitleLanguage preference) {
    final shown = display(preference);
    final seen = <String>{_key(shown)};
    final out = <String>[];
    for (final t in [main, native, romanized]) {
      if (t.isEmpty) continue;
      if (seen.add(_key(t))) out.add(t);
    }
    return out;
  }

  factory SeriesTitles.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final flatMain = _str(json['title']);
    final flatNative = _str(json['native_title']);
    final flatRomanized = _str(json['romanized_title']);
    final entries = _entries(json['titles']);
    final originalLanguage = _baseLanguage(_str(json['original_language']));

    final flatSecondary = _flattenSecondary(json['secondary_titles']);

    if (flatMain.isNotEmpty) {
      var native = flatNative;
      var romanized = flatRomanized;
      // The v1 batch also sends `titles[]`; it only fills what the flat fields leave out.
      if (entries.isNotEmpty) {
        if (native.isEmpty) {
          native = _deriveNative(entries, originalLanguage);
        }
        if (romanized.isEmpty) {
          romanized = _deriveRomanized(entries, originalLanguage);
        }
      }
      final titles = _assemble(
        main: flatMain,
        native: native,
        romanized: romanized,
        extra: [...flatSecondary, ...entries.map((e) => e.title)],
        canonical: true,
      );
      remember(id, titles);
      return titles;
    }

    final known = lookup(id);
    final derivedNative = flatNative.isNotEmpty
        ? flatNative
        : _deriveNative(entries, originalLanguage);
    final derivedRomanized = flatRomanized.isNotEmpty
        ? flatRomanized
        : _deriveRomanized(entries, originalLanguage);

    if (known != null) {
      return _assemble(
        main: known.main,
        native: known.native.isNotEmpty ? known.native : derivedNative,
        romanized: known.romanized.isNotEmpty
            ? known.romanized
            : derivedRomanized,
        extra: [...flatSecondary, ...entries.map((e) => e.title)],
        canonical: true,
      );
    }

    return _assemble(
      main: _deriveMain(entries, originalLanguage),
      native: derivedNative,
      romanized: derivedRomanized,
      extra: [...flatSecondary, ...entries.map((e) => e.title)],
      canonical: false,
    );
  }

  /// Canonical: stored rows come from v1 or were repaired by the refresh that replaced old guesses.
  factory SeriesTitles.stored({
    required String main,
    String native = '',
    String romanized = '',
    List<String> secondary = const [],
  }) {
    return _assemble(
      main: main,
      native: native,
      romanized: romanized,
      extra: secondary,
      canonical: true,
    );
  }

  static SeriesTitles _assemble({
    required String main,
    required String native,
    required String romanized,
    required List<String> extra,
    required bool canonical,
  }) {
    var m = main;
    if (m.isEmpty) m = romanized.isNotEmpty ? romanized : native;

    // native and romanized stay in secondary on purpose: search and the hero's title chips use them.
    final taken = <String>{if (m.isNotEmpty) _key(m)};
    final secondary = <String>[];
    for (final t in extra) {
      final trimmed = t.trim();
      if (trimmed.isEmpty) continue;
      if (taken.add(_key(trimmed))) secondary.add(trimmed);
    }
    return SeriesTitles(
      main: m,
      native: native,
      romanized: romanized,
      secondary: List.unmodifiable(secondary),
      canonical: canonical,
    );
  }

  static String _deriveMain(List<_Entry> entries, String originalLanguage) =>
      _deriveMainTitle(entries, originalLanguage);

  static String _deriveNative(List<_Entry> entries, String originalLanguage) =>
      _deriveNativeTitle(entries, originalLanguage);

  static String _deriveRomanized(
    List<_Entry> entries,
    String originalLanguage,
  ) => _deriveRomanizedTitle(entries, originalLanguage);

  static String _str(Object? v) => v?.toString().trim() ?? '';

  static String _key(String t) => t.trim().toLowerCase();

  static String _baseLanguage(String language) =>
      language.toLowerCase().split(RegExp('[-_]')).first;

  static List<_Entry> _entries(Object? raw) => _parseTitleEntries(raw, _str);

  /// v1 sends `{type: [{title, note, type}, …]}`; other endpoints a list of strings or such objects.
  static List<String> _flattenSecondary(Object? raw) =>
      _flattenSecondaryTitles(raw, _str);

  static const int _maxRemembered = 6000;
  static final LinkedHashMap<String, SeriesTitles> _canonical =
      LinkedHashMap<String, SeriesTitles>();

  static void remember(String id, SeriesTitles titles) {
    if (id.isEmpty || !titles.canonical || titles.main.isEmpty) return;
    _canonical.remove(id); // re-insert to refresh recency
    _canonical[id] = titles;
    while (_canonical.length > _maxRemembered) {
      _canonical.remove(_canonical.keys.first);
    }
  }

  static SeriesTitles? lookup(String id) => _canonical[id];

  /// Tests only.
  static void clearRemembered() => _canonical.clear();
}

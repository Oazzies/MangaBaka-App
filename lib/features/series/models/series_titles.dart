import 'dart:collection';

import 'package:mangabaka_app/core/settings/settings_enums.dart';

part 'series_titles_parser.dart';

/// Every title a series goes by, and the one rule for which to show.
///
/// This is the single place that understands the API's title payloads:
///
/// * **v1** (`/v1/series/{id}`, `/v1/series/batch`, v1 search/library) sends
///   the server-chosen `title` / `native_title` / `romanized_title` and a
///   `secondary_titles` map. That `title` is *canonical*: it is an editorial
///   choice that cannot be rebuilt from the per-language list.
/// * **v2** (`/v2/series/search`, `/v2/series/batch`, discover rails,
///   `/similar`) sends only `titles[]` (`language`, `traits`, `title`), with
///   every entry flagged `is_primary`. The best that can be done is an
///   approximation of the server's choice, see [_deriveMain].
///
/// Because a v2 guess can disagree with the canonical v1 title, every
/// canonical title that is seen is remembered ([remember]) and wins over a
/// later v2 guess for the same series. Without that, a series would show one
/// title in a rail and another once its detail page (v1) loaded.
class SeriesTitles {
  /// The default title (usually English, else the romanized original).
  final String main;

  /// The title in the original script (Japanese, Korean, Chinese).
  final String native;

  /// The original title in Latin script (romaji and friends).
  final String romanized;

  /// Every other known title, deduplicated and without the three above.
  final List<String> secondary;

  /// Whether [main] came from the server's own `title` rather than a guess.
  final bool canonical;

  const SeriesTitles({
    this.main = '',
    this.native = '',
    this.romanized = '',
    this.secondary = const [],
    this.canonical = false,
  });

  static const SeriesTitles empty = SeriesTitles();

  // ── Display ──────────────────────────────────────────────────────────────

  /// The title to show for [preference]. Never falls through to an empty
  /// string while any title is known: the preferred kind is tried first, then
  /// the closest alternatives.
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

  /// [display] without building a [SeriesTitles]: list rows call this on
  /// every build.
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

  /// The titles worth listing next to the displayed one: main, native and
  /// romanized, minus whatever [display] already shows, compared without
  /// regard to case or surrounding space.
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

  // ── Parsing ──────────────────────────────────────────────────────────────

  /// Reads the title fields of any series payload (v1, v2, `/similar`).
  ///
  /// A canonical v1 `title` is kept as is and remembered. Otherwise the main
  /// title is derived from `titles[]`, unless a canonical one for the same
  /// series id was seen before.
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
      // A v1 payload may carry `titles[]` too (the batch does); it only fills
      // what the flat fields leave out.
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

    // No canonical title in this payload.
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

  /// Builds titles from already-stored values (database rows, exports).
  /// Canonical, because stored rows come from a v1 payload or were repaired
  /// by the refresh that replaced the old guesses.
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
    // A series always has something to show.
    if (m.isEmpty) m = romanized.isNotEmpty ? romanized : native;

    // Only the main title is excluded: native and romanized stay listed as
    // secondary titles too, for search and for the hero's title chips.
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

  // ── Derivation from titles[] (v2) ────────────────────────────────────────

  static String _deriveMain(List<_Entry> entries, String originalLanguage) =>
      _deriveMainTitle(entries, originalLanguage);

  static String _deriveNative(List<_Entry> entries, String originalLanguage) =>
      _deriveNativeTitle(entries, originalLanguage);

  static String _deriveRomanized(
    List<_Entry> entries,
    String originalLanguage,
  ) => _deriveRomanizedTitle(entries, originalLanguage);

  // ── Payload helpers ──────────────────────────────────────────────────────

  static String _str(Object? v) => v?.toString().trim() ?? '';

  /// Case- and whitespace-insensitive identity of a title.
  static String _key(String t) => t.trim().toLowerCase();

  /// `ja-Latn` → `ja`, `zh-Hans-CN` → `zh`.
  static String _baseLanguage(String language) =>
      language.toLowerCase().split(RegExp('[-_]')).first;

  static List<_Entry> _entries(Object? raw) => _parseTitleEntries(raw, _str);

  /// v1 sends `secondary_titles` as `{type: [{title, note, type}, …]}`; other
  /// endpoints send a plain list of strings or of such objects.
  static List<String> _flattenSecondary(Object? raw) =>
      _flattenSecondaryTitles(raw, _str);

  // ── Canonical memory ─────────────────────────────────────────────────────

  static const int _maxRemembered = 6000;
  static final LinkedHashMap<String, SeriesTitles> _canonical =
      LinkedHashMap<String, SeriesTitles>();

  /// Notes the canonical titles of series [id] so later, less reliable
  /// payloads for it agree with them. Non-canonical titles are ignored.
  static void remember(String id, SeriesTitles titles) {
    if (id.isEmpty || !titles.canonical || titles.main.isEmpty) return;
    _canonical.remove(id); // re-insert to refresh recency
    _canonical[id] = titles;
    while (_canonical.length > _maxRemembered) {
      _canonical.remove(_canonical.keys.first);
    }
  }

  /// The canonical titles last seen for [id], if any.
  static SeriesTitles? lookup(String id) => _canonical[id];

  /// For tests: forget everything remembered.
  static void clearRemembered() => _canonical.clear();
}

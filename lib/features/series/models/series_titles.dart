import 'dart:collection';

import 'package:mangabaka_app/core/settings/settings_enums.dart';

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

  /// The best guess at the server's main title:
  ///
  /// 1. an official English title,
  /// 2. else the original's romanization (what the server uses when there is
  ///    no official English release — an unofficial English entry is a fan
  ///    translation and loses to it),
  /// 3. else any romanization, 4. else any English entry, 5. else the first.
  ///
  /// Measured against v1 on 345 random series this matches the server's
  /// choice for roughly four titles in five; the rest are editorial.
  static String _deriveMain(List<_Entry> entries, String originalLanguage) {
    if (entries.isEmpty) return '';

    final officialEnglish = entries.where(
      (e) => e.language == 'en' && e.traits.contains('official'),
    );
    if (officialEnglish.isNotEmpty) return officialEnglish.first.title;

    final romanized = _deriveRomanized(entries, originalLanguage);
    if (romanized.isNotEmpty) return romanized;

    final english = entries.where((e) => e.language == 'en').toList();
    final plainEnglish = english.where(
      (e) => !e.traits.contains('alternative'),
    );
    if (plainEnglish.isNotEmpty) return plainEnglish.first.title;
    if (english.isNotEmpty) return english.first.title;
    return entries.first.title;
  }

  /// The original-script title: a non-Latin entry in the series' original
  /// language, preferring ones flagged `native`. Translations into
  /// Japanese/Korean/Chinese of a series from elsewhere do not count.
  static String _deriveNative(List<_Entry> entries, String originalLanguage) {
    bool inOriginal(_Entry e) => originalLanguage.isEmpty
        ? const {'ja', 'ko', 'zh'}.contains(e.base)
        : e.base == originalLanguage;

    final candidates = entries.where((e) => !e.isLatin && inOriginal(e));
    for (final e in candidates) {
      if (e.traits.contains('native')) return e.title;
    }
    return candidates.isEmpty ? '' : candidates.first.title;
  }

  /// The original title in Latin script: a `…-Latn` entry, preferring ones
  /// flagged `native` in the original language.
  static String _deriveRomanized(
    List<_Entry> entries,
    String originalLanguage,
  ) {
    final latin = entries.where((e) => e.isLatin).toList();
    if (latin.isEmpty) return '';

    bool inOriginal(_Entry e) =>
        originalLanguage.isEmpty || e.base == originalLanguage;
    final tiers = <bool Function(_Entry)>[
      (e) => e.traits.contains('native') && inOriginal(e),
      (e) => e.traits.contains('native'),
      inOriginal,
    ];
    for (final tier in tiers) {
      for (final e in latin) {
        if (tier(e)) return e.title;
      }
    }
    return latin.first.title;
  }

  // ── Payload helpers ──────────────────────────────────────────────────────

  static String _str(Object? v) => v?.toString().trim() ?? '';

  /// Case- and whitespace-insensitive identity of a title.
  static String _key(String t) => t.trim().toLowerCase();

  /// `ja-Latn` → `ja`, `zh-Hans-CN` → `zh`.
  static String _baseLanguage(String language) =>
      language.toLowerCase().split(RegExp('[-_]')).first;

  static List<_Entry> _entries(Object? raw) {
    if (raw is! List) return const [];
    final out = <_Entry>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final title = _str(item['title']);
      if (title.isEmpty) continue;
      final traits = item['traits'];
      out.add(
        _Entry(
          language: _str(item['language']).toLowerCase(),
          traits: traits is List
              ? {for (final t in traits) t.toString().toLowerCase()}
              : const {},
          title: title,
        ),
      );
    }
    return out;
  }

  /// v1 sends `secondary_titles` as `{type: [{title, note, type}, …]}`; other
  /// endpoints send a plain list of strings or of such objects.
  static List<String> _flattenSecondary(Object? raw) {
    String? one(Object? item) {
      if (item is Map) return _str(item['title']);
      if (item is String) return item.trim();
      return null;
    }

    final out = <String>[];
    void visit(Object? node) {
      if (node is Map) {
        if (node.containsKey('title')) {
          final t = one(node);
          if (t != null && t.isNotEmpty) out.add(t);
        } else {
          node.values.forEach(visit);
        }
      } else if (node is List) {
        node.forEach(visit);
      } else {
        final t = one(node);
        if (t != null && t.isNotEmpty) out.add(t);
      }
    }

    visit(raw);
    return out;
  }

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

class _Entry {
  final String language;
  final Set<String> traits;
  final String title;

  const _Entry({
    required this.language,
    required this.traits,
    required this.title,
  });

  String get base => SeriesTitles._baseLanguage(language);

  /// Latin-script entry: `ja-Latn`, and the older spellings `ja-ro`,
  /// `ja-hepburn`, `ja-romaji` or an explicit `romanized` trait.
  bool get isLatin =>
      language.endsWith('-latn') ||
      language.endsWith('-ro') ||
      language.contains('hepburn') ||
      language.contains('romaji') ||
      traits.contains('romanized');
}

part of 'series_titles.dart';

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

List<_Entry> _parseTitleEntries(Object? raw, String Function(Object?) str) {
  if (raw is! List) return const [];
  final out = <_Entry>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final title = str(item['title']);
    if (title.isEmpty) continue;
    final traits = item['traits'];
    out.add(
      _Entry(
        language: str(item['language']).toLowerCase(),
        traits: traits is List
            ? {for (final t in traits) t.toString().toLowerCase()}
            : const {},
        title: title,
      ),
    );
  }
  return out;
}

List<String> _flattenSecondaryTitles(
  Object? raw,
  String Function(Object?) str,
) {
  String? one(Object? item) {
    if (item is Map) return str(item['title']);
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

String _deriveMainTitle(List<_Entry> entries, String originalLanguage) {
  if (entries.isEmpty) return '';

  final officialEnglish = entries.where(
    (e) => e.language == 'en' && e.traits.contains('official'),
  );
  if (officialEnglish.isNotEmpty) return officialEnglish.first.title;

  final romanized = _deriveRomanizedTitle(entries, originalLanguage);
  if (romanized.isNotEmpty) return romanized;

  final english = entries.where((e) => e.language == 'en').toList();
  final plainEnglish = english.where(
    (e) => !e.traits.contains('alternative'),
  );
  if (plainEnglish.isNotEmpty) return plainEnglish.first.title;
  if (english.isNotEmpty) return english.first.title;
  return entries.first.title;
}

String _deriveNativeTitle(List<_Entry> entries, String originalLanguage) {
  bool inOriginal(_Entry e) => originalLanguage.isEmpty
      ? const {'ja', 'ko', 'zh'}.contains(e.base)
      : e.base == originalLanguage;

  final candidates = entries.where((e) => !e.isLatin && inOriginal(e));
  for (final e in candidates) {
    if (e.traits.contains('native')) return e.title;
  }
  return candidates.isEmpty ? '' : candidates.first.title;
}

String _deriveRomanizedTitle(
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

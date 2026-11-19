/// The mix endpoint returns the v2 shape (`*_v2` arrays split by `is_genre`, year under
/// `published.start_date`); this flattens it to the shape `Series.fromJson` reads.
Map<String, dynamic> normalizeMixSeriesJson(Map<String, dynamic> json) {
  final normalized = Map<String, dynamic>.from(json);

  normalized['genres'] ??= _namesFrom(json['genres_v2'], isGenre: true);
  normalized['tags'] ??= _namesFrom(json['tags_v2'], isGenre: false);
  normalized['year'] ??= _yearFrom(json['published']);

  // The key must exist so the model's own cover fallback runs.
  normalized.putIfAbsent('cover', () => null);

  return normalized;
}

/// Null rather than empty when absent, so the `??=` above keeps an existing flat value.
List<String>? _namesFrom(dynamic v2List, {required bool isGenre}) {
  if (v2List is! List) return null;
  return v2List
      .whereType<Map>()
      .where((e) => (e['is_genre'] == true) == isGenre)
      .map((e) => e['name']?.toString() ?? '')
      .where((name) => name.isNotEmpty)
      .toList();
}

/// The API formats `published.start_date` as `YYYY-MM-DD`.
int? _yearFrom(dynamic published) {
  if (published is! Map) return null;
  final startDate = published['start_date']?.toString() ?? '';
  if (startDate.length < 4) return null;
  return int.tryParse(startDate.substring(0, 4));
}

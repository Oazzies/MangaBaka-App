class JsonUtils {
  static T? getField<T>(Map? map, List<String> path) {
    dynamic value = map;
    for (final key in path) {
      if (value is Map && value.containsKey(key)) {
        value = value[key];
      } else {
        return null;
      }
    }
    return value as T?;
  }

  /// [value] as a double when it is a number or a numeric string, else null.
  ///
  /// For fields the API documents as numbers: a hard `as num` cast would turn
  /// one oddly-typed value into a failure of the whole payload around it.
  static double? toDouble(Object? value) => switch (value) {
        final num n => n.toDouble(),
        final String s => double.tryParse(s.trim()),
        _ => null,
      };

  /// The `rating_normalized` of one entry of a series' `source` map, or null
  /// when the entry is not a map or carries no usable rating.
  static double? normalizedRating(Object? sourceEntry) =>
      sourceEntry is Map ? toDouble(sourceEntry['rating_normalized']) : null;

  /// v1 nests each cover size as `{x1, x2}` or `{url, ...}` and the original
  /// as `raw: {url, ...}`; the v2 endpoints flatten both to plain URL strings.
  /// Both `cover` and `cover_image` shapes are accepted.
  static String getCover(Map<String, dynamic> map) {
    final cover = map['cover'] ?? map['cover_image'];
    if (cover is! Map) return '';
    final sized = cover['x350'] ?? cover['x250'] ?? cover['x150'];
    if (sized is Map) {
      if (sized['url'] is String) return sized['url'] as String;
      if (sized['x1'] is String) return sized['x1'] as String;
    }
    if (sized is String) return sized;
    final fallback = cover['x250'] ?? cover['x150'];
    if (fallback is Map && fallback['url'] is String) {
      return fallback['url'] as String;
    }
    if (fallback is String) return fallback;
    return getRawCover(map);
  }

  static String getRawCover(Map<String, dynamic> map) {
    final cover = map['cover'] ?? map['cover_image'];
    if (cover is! Map) return '';
    final raw = cover['raw'];
    if (raw is Map && raw['url'] is String) return raw['url'] as String;
    if (raw is String) return raw;
    return '';
  }
}

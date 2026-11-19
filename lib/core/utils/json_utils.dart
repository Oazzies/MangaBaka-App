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

  /// A hard `as num` cast would fail the whole payload over one oddly-typed value.
  static double? toDouble(Object? value) => switch (value) {
    final num n => n.toDouble(),
    final String s => double.tryParse(s.trim()),
    _ => null,
  };

  static double? normalizedRating(Object? sourceEntry) {
    if (sourceEntry is! Map) return null;
    final value = toDouble(sourceEntry['rating_normalized']);
    // "NaN" and "Infinity" parse as doubles and would poison an average.
    return value != null && value.isFinite ? value : null;
  }

  /// Not `cast<String>()`: it is lazy, so a bad element throws later, outside the parse's try/catch.
  static List<String> stringList(Object? value) =>
      value is List ? value.whereType<String>().toList() : <String>[];

  /// Stringifies a number or bool where `json['k'] ?? ''` would throw a TypeError.
  static String stringOr(Object? value, [String fallback = '']) =>
      value?.toString() ?? fallback;

  /// v1 nests each size as `{x1, x2}` or `{url, ...}` and the original as `raw: {url, ...}`;
  /// v2 flattens both to URL strings. Takes both `cover` and `cover_image`.
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

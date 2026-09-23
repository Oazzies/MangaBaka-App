/// Helpers for the `{data, total, ...}` envelope every MangaBaka endpoint
/// wraps its payload in.
///
/// Each service used to unwrap it inline with its own mix of `as` casts and
/// `??` fallbacks — shapes that differ just enough between call sites that a
/// null `data` threw in some services and yielded an empty list in others.
/// These helpers make the tolerant reading the single behaviour: a missing or
/// wrongly-typed field degrades to empty rather than throwing, and a genuinely
/// malformed body still fails at [ApiClient.decode].
library;

/// The `data` array of a list response, as raw JSON maps.
///
/// Returns an empty list when `data` is absent or not a list, so a caller
/// never has to null-check before mapping.
List<Map<String, dynamic>> dataList(dynamic json) {
  if (json is! Map) return const [];
  final data = json['data'];
  if (data is! List) return const [];
  return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
}

/// The `data` object of a single-resource response.
///
/// Returns null when `data` is absent or not an object, letting the caller
/// decide whether that is an error or an expected empty result.
Map<String, dynamic>? dataObject(dynamic json) {
  if (json is! Map) return null;
  final data = json['data'];
  if (data is! Map) return null;
  return data.cast<String, dynamic>();
}

/// The `total` count of a paginated response, defaulting to 0.
int totalCount(dynamic json) {
  if (json is! Map) return 0;
  return (json['total'] as num?)?.toInt() ?? 0;
}

/// Maps the `data` array through [fromJson], skipping any element that fails
/// to parse.
///
/// One bad row in a page of search results should cost that row, not the whole
/// page — several list endpoints previously threw a [ParseException] for the
/// entire response when a single item was malformed.
List<T> parseDataList<T>(
  dynamic json,
  T? Function(Map<String, dynamic> item) fromJson,
) {
  final out = <T>[];
  for (final item in dataList(json)) {
    final T? parsed;
    try {
      parsed = fromJson(item);
    } catch (_) {
      continue;
    }
    if (parsed != null) out.add(parsed);
  }
  return out;
}

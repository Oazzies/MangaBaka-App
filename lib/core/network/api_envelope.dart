/// A missing or mistyped envelope field degrades to empty instead of throwing.
library;

import 'package:mangabaka_app/core/logging/logging_service.dart';

List<Map<String, dynamic>> dataList(dynamic json) {
  if (json is! Map) return const [];
  final data = json['data'];
  if (data is! List) return const [];
  return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
}

Map<String, dynamic>? dataObject(dynamic json) {
  if (json is! Map) return null;
  final data = json['data'];
  if (data is! Map) return null;
  return data.cast<String, dynamic>();
}

/// v1 reports `total` at the top level; v2 reports `pagination.count`.
int totalCount(dynamic json) {
  if (json is! Map) return 0;
  final top = (json['total'] as num?)?.toInt();
  if (top != null) return top;
  final pagination = json['pagination'];
  if (pagination is Map) return (pagination['count'] as num?)?.toInt() ?? 0;
  return 0;
}

/// Skips rows that fail to parse: one bad row costs that row, not the page.
List<T> parseDataList<T>(
  dynamic json,
  T? Function(Map<String, dynamic> item) fromJson,
) {
  final out = <T>[];
  for (final item in dataList(json)) {
    final T? parsed;
    try {
      parsed = fromJson(item);
    } catch (e, st) {
      LoggingService.logger.warning(
        'Skipping malformed item in list response',
        e,
        st,
      );
      continue;
    }
    if (parsed != null) out.add(parsed);
  }
  return out;
}

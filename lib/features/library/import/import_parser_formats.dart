part of 'import_parser.dart';

List<ImportEntry> _parseMangaUpdatesEntries(String text, {String? fileName}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    return const [];
  }
  if (decoded is! List) return const [];

  String? stateFromFile;
  if (fileName != null) {
    final name = fileName.toLowerCase();
    if (name.contains('_id0_')) {
      stateFromFile = 'reading';
    } else if (name.contains('_id1_')) {
      stateFromFile = 'plan_to_read';
    } else if (name.contains('_id2_')) {
      stateFromFile = 'completed';
    } else if (name.contains('_id3_')) {
      stateFromFile = 'dropped';
    } else if (name.contains('_id4_')) {
      stateFromFile = 'paused';
    }
  }

  final entries = <ImportEntry>[];
  for (final item in decoded) {
    if (item is! Map) continue;
    final title = item['title']?.toString();
    if (title == null || title.trim().isEmpty) continue;
    final status = item['status']?.toString();
    final state =
        stateFromFile ?? (status != null ? _mapImportStatus(status) : null);
    entries.add(ImportEntry(title, state: state));
  }
  return entries;
}

List<ImportEntry> _parseMangaBakaEntries(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    return const [];
  }
  final List<dynamic> rawEntries;
  if (decoded is Map && decoded['entries'] is List) {
    rawEntries = decoded['entries'] as List;
  } else if (decoded is List) {
    rawEntries = decoded;
  } else {
    return const [];
  }

  final entries = <ImportEntry>[];
  for (final item in rawEntries) {
    if (item is! Map) continue;
    String? title;
    final titles = item['titles'];
    if (titles is Map) {
      title = (titles['primary'] ?? titles['romanized'] ?? titles['native'])
          ?.toString();
    }
    title ??= item['title']?.toString() ?? item['name']?.toString();
    if (title == null || title.trim().isEmpty) continue;

    String? state;
    final entryObj = item['entry'];
    if (entryObj is Map && entryObj['state'] != null) {
      state = ImportParser.mapStatus(entryObj['state'].toString());
    }
    state ??= item['state'] != null
        ? ImportParser.mapStatus(item['state'].toString())
        : null;

    entries.add(ImportEntry(title, state: state));
  }
  return entries;
}

List<ImportEntry> _parseMyAnimeListEntries(String text) {
  final block = RegExp(r'<manga>(.*?)</manga>', dotAll: true);
  final entries = <ImportEntry>[];
  for (final match in block.allMatches(text)) {
    final body = match.group(1) ?? '';
    final title = _xmlField(body, 'manga_title');
    if (title == null) continue;
    final status = _xmlField(body, 'my_status');
    entries.add(
      ImportEntry(
        title,
        state: status == null ? null : ImportParser.mapStatus(status),
      ),
    );
  }
  return entries;
}

String? _xmlField(String body, String tag) {
  final match = RegExp(
    '<$tag>\\s*(?:<!\\[CDATA\\[(.*?)\\]\\]>|(.*?))\\s*</$tag>',
    dotAll: true,
  ).firstMatch(body);
  if (match == null) return null;
  final raw = match.group(1) ?? match.group(2);
  return raw == null ? null : _unescapeXml(raw.trim());
}

String _unescapeXml(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');

String? _mapImportStatus(String status) {
  switch (status.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '')) {
    case 'reading':
    case 'current':
    case 'currentlyreading':
      return 'reading';
    case 'completed':
    case 'complete':
    case 'finished':
      return 'completed';
    case 'onhold':
    case 'paused':
      return 'paused';
    case 'dropped':
      return 'dropped';
    case 'plantoread':
    case 'planned':
    case 'planning':
      return 'plan_to_read';
    case 'rereading':
    case 'repeating':
      return 'rereading';
    case 'considering':
      return 'considering';
  }
  return null;
}

import 'dart:convert';

/// The shapes of list the importer understands.
enum ImportFormat {
  /// Work out the format from the text itself.
  auto,

  /// One title per line.
  plain,

  /// Rows with a title column, and optionally a status column.
  csv,

  /// A JSON array of titles or of objects carrying one.
  json,

  /// A MyAnimeList manga export (`<myanimelist><manga>…`).
  myAnimeList,

  /// A Manga-Updates JSON list export.
  mangaUpdates,

  /// A MangaBaka JSON backup file.
  mangaBaka,
}

/// One title read from an import source, with the state its source gave it, if
/// any.
class ImportEntry {
  final String title;

  /// A MangaBaka library state (`reading`, `completed`, …), or null when the
  /// source did not say or said something unrecognisable.
  final String? state;

  const ImportEntry(this.title, {this.state});

  @override
  bool operator ==(Object other) =>
      other is ImportEntry && other.title == title && other.state == state;

  @override
  int get hashCode => Object.hash(title, state);

  @override
  String toString() => 'ImportEntry($title, $state)';
}

/// Reads import text in any [ImportFormat] into titles.
///
/// Parsing never throws: text that does not fit the chosen format yields
/// whatever titles could be read, usually none, and the caller shows "0 titles
/// found". A wrong guess is better shown than raised.
abstract final class ImportParser {
  /// Longest list accepted. Each title is a request, so an accidental paste of
  /// a whole document should not become hundreds of them.
  static const int maxTitles = 200;

  /// Guesses the format of [text].
  static ImportFormat detect(String text, {String? fileName}) {
    final trimmed = text.trimLeft();
    if (trimmed.isEmpty) return ImportFormat.plain;

    if (trimmed.startsWith('<') && trimmed.contains('<manga')) {
      return ImportFormat.myAnimeList;
    }
    // Only if it actually parses: "[Oshi no Ko]" is a title, not a JSON array.
    if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          if (decoded.containsKey('schema_version') ||
              (decoded.containsKey('entries') && decoded['entries'] is List)) {
            return ImportFormat.mangaBaka;
          }
        } else if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          if (first is Map) {
            if (first.containsKey('titles') ||
                (first.containsKey('entry') && first.containsKey('source'))) {
              return ImportFormat.mangaBaka;
            }
            if (first.containsKey('id') && first.containsKey('title')) {
              return ImportFormat.mangaUpdates;
            }
          }
        }
        return ImportFormat.json;
      } catch (_) {}
    }

    // CSV only when the first line looks like a header naming a title column;
    // a plain list whose titles happen to contain commas must stay plain.
    final header = _splitCsvLine(trimmed.split(RegExp(r'\r?\n')).first)
        .map((c) => c.trim().toLowerCase())
        .toList();
    if (header.length > 1 && header.any(_titleColumns.contains)) {
      return ImportFormat.csv;
    }
    return ImportFormat.plain;
  }

  /// Whether [format] can carry a per-title state.
  static bool carriesStates(ImportFormat format) =>
      format != ImportFormat.plain;

  static List<ImportEntry> parse(
    String text, {
    ImportFormat format = ImportFormat.auto,
    bool useStates = true,
    String? fileName,
  }) {
    final resolved = format == ImportFormat.auto
        ? detect(text, fileName: fileName)
        : format;
    final entries = switch (resolved) {
      ImportFormat.myAnimeList => _parseMyAnimeList(text),
      ImportFormat.mangaUpdates => _parseMangaUpdates(text, fileName: fileName),
      ImportFormat.mangaBaka => _parseMangaBaka(text),
      ImportFormat.json => _parseJson(text),
      ImportFormat.csv => _parseCsv(text),
      _ => _parsePlain(text),
    };
    return _clean(entries, useStates: useStates);
  }

  /// Drops blanks and repeats (case-insensitively, keeping the first), strips
  /// the states when they are not wanted, and applies [maxTitles].
  static List<ImportEntry> _clean(
    List<ImportEntry> entries, {
    required bool useStates,
  }) {
    final seen = <String>{};
    final result = <ImportEntry>[];
    for (final entry in entries) {
      final title = entry.title.trim();
      if (title.isEmpty) continue;
      if (!seen.add(title.toLowerCase())) continue;
      result.add(ImportEntry(title, state: useStates ? entry.state : null));
      if (result.length >= maxTitles) break;
    }
    return result;
  }

  // ─── Plain ───────────────────────────────────────────────────────────────

  /// One per line, list markers ("1.", "-", "*") removed.
  static List<ImportEntry> _parsePlain(String text) {
    final marker = RegExp(r'^\s*(?:[-*•]+|\d+[.)])\s+');
    return [
      for (final line in text.split(RegExp(r'\r?\n')))
        ImportEntry(line.replaceFirst(marker, '')),
    ];
  }

  // ─── CSV ─────────────────────────────────────────────────────────────────

  static const _titleColumns = {
    'title',
    'name',
    'series',
    'series_title',
    'manga',
    'manga_title',
  };
  static const _stateColumns = {'status', 'state', 'my_status', 'list'};

  static List<ImportEntry> _parseCsv(String text) {
    final lines = _splitCsvRecords(text)
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return const [];

    final header = _splitCsvLine(lines.first)
        .map((c) => c.trim().toLowerCase())
        .toList();
    var titleIndex = header.indexWhere(_titleColumns.contains);
    final stateIndex = header.indexWhere(_stateColumns.contains);

    // No recognisable header: the whole file is data, titles in column one.
    final hasHeader = titleIndex != -1;
    if (!hasHeader) titleIndex = 0;

    final entries = <ImportEntry>[];
    for (final line in lines.skip(hasHeader ? 1 : 0)) {
      final cells = _splitCsvLine(line);
      if (titleIndex >= cells.length) continue;
      entries.add(
        ImportEntry(
          cells[titleIndex],
          state: stateIndex != -1 && stateIndex < cells.length
              ? mapStatus(cells[stateIndex])
              : null,
        ),
      );
    }
    return entries;
  }

  /// Splits [text] into records at line breaks that are not inside a quoted
  /// cell, so a note containing a newline (which the exporter quotes) stays
  /// part of its own row instead of becoming bogus extra titles.
  static List<String> _splitCsvRecords(String text) {
    final records = <String>[];
    final buffer = StringBuffer();
    var quoted = false;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (ch == '"') {
        quoted = !quoted; // an escaped "" toggles twice and nets out
        buffer.write(ch);
      } else if (ch == '\n' && !quoted) {
        records.add(buffer.toString());
        buffer.clear();
      } else if (ch == '\r' && !quoted) {
        // Dropped: part of a CRLF break (or a stray bare CR).
      } else {
        buffer.write(ch);
      }
    }
    records.add(buffer.toString());
    return records;
  }

  /// Splits one CSV line, honouring double-quoted cells and `""` escapes.
  static List<String> _splitCsvLine(String line) {
    final cells = <String>[];
    final buffer = StringBuffer();
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (quoted) {
        if (ch == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            buffer.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          buffer.write(ch);
        }
      } else if (ch == '"') {
        quoted = true;
      } else if (ch == ',') {
        cells.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    cells.add(buffer.toString());
    return cells;
  }

  // ─── JSON ────────────────────────────────────────────────────────────────

  static const _jsonTitleKeys = [
    'title',
    'name',
    'series_title',
    'manga_title',
    'series',
  ];
  static const _jsonStateKeys = ['status', 'state', 'my_status', 'list'];

  static List<ImportEntry> _parseJson(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      return const [];
    }

    // An object wrapping the list: {"list": [...]}, {"entries": [...]}.
    final Object? root = decoded is Map
        ? decoded.values.firstWhere((v) => v is List, orElse: () => null)
        : decoded;
    if (root is! List) return const [];

    final entries = <ImportEntry>[];
    for (final item in root) {
      if (item is String) {
        entries.add(ImportEntry(item));
      } else if (item is Map) {
        final title = _firstString(item, _jsonTitleKeys);
        if (title == null) continue;
        final status = _firstString(item, _jsonStateKeys);
        entries.add(
          ImportEntry(title, state: status == null ? null : mapStatus(status)),
        );
      }
    }
    return entries;
  }

  static String? _firstString(Map<dynamic, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  // ─── Manga-Updates ───────────────────────────────────────────────────────

  static List<ImportEntry> _parseMangaUpdates(
    String text, {
    String? fileName,
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
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
      final state = stateFromFile ?? (status != null ? mapStatus(status) : null);
      entries.add(ImportEntry(title, state: state));
    }
    return entries;
  }

  // ─── MangaBaka Backup ─────────────────────────────────────────────────────

  static List<ImportEntry> _parseMangaBaka(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      return const [];
    }

    final List<dynamic> rawEntries;
    if (decoded is Map && decoded['entries'] is List) {
      rawEntries = decoded['entries'] as List<dynamic>;
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
        state = mapStatus(entryObj['state'].toString());
      }
      state ??= item['state'] != null ? mapStatus(item['state'].toString()) : null;

      entries.add(ImportEntry(title, state: state));
    }
    return entries;
  }

  // ─── MyAnimeList ─────────────────────────────────────────────────────────

  static List<ImportEntry> _parseMyAnimeList(String text) {
    final block = RegExp(r'<manga>(.*?)</manga>', dotAll: true);
    final entries = <ImportEntry>[];
    for (final match in block.allMatches(text)) {
      final body = match.group(1) ?? '';
      final title = _xmlField(body, 'manga_title');
      if (title == null) continue;
      final status = _xmlField(body, 'my_status');
      entries.add(
        ImportEntry(title, state: status == null ? null : mapStatus(status)),
      );
    }
    return entries;
  }

  static String? _xmlField(String body, String tag) {
    final match = RegExp(
      '<$tag>\\s*(?:<!\\[CDATA\\[(.*?)\\]\\]>|(.*?))\\s*</$tag>',
      dotAll: true,
    ).firstMatch(body);
    if (match == null) return null;
    final raw = match.group(1) ?? match.group(2);
    return raw == null ? null : _unescapeXml(raw.trim());
  }

  static String _unescapeXml(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');

  // ─── Status mapping ──────────────────────────────────────────────────────

  /// Maps a status as other trackers write it to a MangaBaka library state, or
  /// null when it is not one we recognise (the row then takes the state the
  /// user picked).
  static String? mapStatus(String status) {
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
}

import 'dart:convert';
import 'package:mangabaka_app/features/library/import/import_models.dart';

export 'package:mangabaka_app/features/library/import/import_models.dart';

part 'import_parser_formats.dart';

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
      } on FormatException {
        // Looked like JSON but is not; fall through to the CSV / text sniff.
      }
    }

    // CSV only when the first line looks like a header naming a title column;
    // a plain list whose titles happen to contain commas must stay plain.
    final header = _splitCsvLine(
      trimmed.split(RegExp(r'\r?\n')).first,
    ).map((c) => c.trim().toLowerCase()).toList();
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
    final lines = _splitCsvRecords(
      text,
    ).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return const [];

    final header = _splitCsvLine(
      lines.first,
    ).map((c) => c.trim().toLowerCase()).toList();
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
    } on FormatException {
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

  static List<ImportEntry> _parseMangaUpdates(String text, {String? fileName}) =>
      _parseMangaUpdatesEntries(text, fileName: fileName);

  // ─── MangaBaka Backup ─────────────────────────────────────────────────────

  static List<ImportEntry> _parseMangaBaka(String text) =>
      _parseMangaBakaEntries(text);

  // ─── MyAnimeList ─────────────────────────────────────────────────────────

  static List<ImportEntry> _parseMyAnimeList(String text) =>
      _parseMyAnimeListEntries(text);

  // ─── Status mapping ──────────────────────────────────────────────────────

  /// Maps a status as other trackers write it to a MangaBaka library state, or
  /// null when it is not one we recognise (the row then takes the state the
  /// user picked).
  static String? mapStatus(String status) => _mapImportStatus(status);
}

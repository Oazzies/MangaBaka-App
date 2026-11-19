import 'dart:convert';

import 'package:mangabaka_app/features/library/models/library_entry.dart';

enum ExportFormat {
  mangaBaka,

  csv,

  plain,
}

abstract final class ExportService {
  static String build(List<LibraryEntry> entries, ExportFormat format) {
    return switch (format) {
      ExportFormat.mangaBaka => _buildMangaBaka(entries),
      ExportFormat.csv => _buildCsv(entries),
      ExportFormat.plain => _buildPlain(entries),
    };
  }

  static String suggestedFileName(ExportFormat format) {
    final date = DateTime.now().toIso8601String().split('T').first;
    final extension = switch (format) {
      ExportFormat.mangaBaka => 'json',
      ExportFormat.csv => 'csv',
      ExportFormat.plain => 'txt',
    };
    return 'mangabaka-library-$date.$extension';
  }

  static String _buildMangaBaka(List<LibraryEntry> entries) {
    final out = {
      'schema_version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'entries': [
        for (final e in entries)
          if (e.series.title.trim().isNotEmpty ||
              e.series.nativeTitle.trim().isNotEmpty)
            {
              'id': e.series.id,
              'titles': {
                'primary': e.series.title,
                'romanized': e.series.romanizedTitle,
                'native': e.series.nativeTitle,
              },
              'entry': {
                'state': e.state,
                if (e.progressChapter != null)
                  'progress_chapter': e.progressChapter,
                if (e.progressVolume != null)
                  'progress_volume': e.progressVolume,
                if (e.rating != null) 'rating': e.rating,
                if (e.note != null && e.note!.isNotEmpty) 'note': e.note,
              },
            },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(out);
  }

  static String _buildCsv(List<LibraryEntry> entries) {
    final rows = StringBuffer(
      'title,state,progress_chapter,progress_volume,rating,note\n',
    );
    for (final e in entries) {
      final title = e.series.title.isNotEmpty
          ? e.series.title
          : e.series.nativeTitle;
      if (title.trim().isEmpty) continue;
      rows.writeAll([
        _cell(title),
        _cell(e.state),
        e.progressChapter?.toString() ?? '',
        e.progressVolume?.toString() ?? '',
        e.rating?.toString() ?? '',
        _cell(e.note ?? ''),
      ], ',');
      rows.write('\n');
    }
    return rows.toString();
  }

  /// The inverse of `ImportParser._splitCsvLine`.
  static String _cell(String value) {
    if (!value.contains(RegExp(r'[,"\n]'))) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  static String _buildPlain(List<LibraryEntry> entries) {
    return entries
        .map(
          (e) =>
              e.series.title.isNotEmpty ? e.series.title : e.series.nativeTitle,
        )
        .where((t) => t.trim().isNotEmpty)
        .join('\n');
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/library/export/export_service.dart';
import 'package:mangabaka_app/features/library/import/import_parser.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

LibraryEntry _entry(
  String id,
  String title, {
  String state = 'reading',
  int? progressChapter,
  int? progressVolume,
  int? rating,
  String? note,
}) => LibraryEntry(
  id: id,
  state: state,
  progressChapter: progressChapter,
  progressVolume: progressVolume,
  rating: rating,
  note: note,
  series: Series.fromJson({'id': id, 'title': title}),
);

void main() {
  group('ExportService.build', () {
    test('mangaBaka round-trips through ImportParser', () {
      final entries = [
        _entry('1', 'Frieren', state: 'reading', progressChapter: 80, rating: 9),
        _entry('2', 'Berserk', state: 'paused', note: 'waiting for more'),
      ];

      final json = ExportService.build(entries, ExportFormat.mangaBaka);
      final parsed = ImportParser.parse(json, format: ImportFormat.mangaBaka);

      expect(parsed, const [
        ImportEntry('Frieren', state: 'reading'),
        ImportEntry('Berserk', state: 'paused'),
      ]);
    });

    test('an entry with no title is left out of every format', () {
      final entries = [_entry('1', '')];

      expect(
        ImportParser.parse(
          ExportService.build(entries, ExportFormat.mangaBaka),
          format: ImportFormat.mangaBaka,
        ),
        isEmpty,
      );
      expect(ExportService.build(entries, ExportFormat.csv).trim(), 'title,state,progress_chapter,progress_volume,rating,note');
      expect(ExportService.build(entries, ExportFormat.plain), '');
    });

    test('csv quotes a title holding a comma', () {
      final entries = [_entry('1', 'Kaguya-sama: Love is War, sort of')];

      final csv = ExportService.build(entries, ExportFormat.csv);

      expect(
        csv,
        'title,state,progress_chapter,progress_volume,rating,note\n'
        '"Kaguya-sama: Love is War, sort of",reading,,,,\n',
      );
    });

    test('plain is one title per line, blanks dropped', () {
      final entries = [
        _entry('1', 'Frieren'),
        _entry('2', ''),
        _entry('3', 'Berserk'),
      ];

      expect(ExportService.build(entries, ExportFormat.plain), 'Frieren\nBerserk');
    });
  });

  group('ExportService.suggestedFileName', () {
    test('names each format with its extension', () {
      expect(
        ExportService.suggestedFileName(ExportFormat.mangaBaka),
        endsWith('.json'),
      );
      expect(ExportService.suggestedFileName(ExportFormat.csv), endsWith('.csv'));
      expect(ExportService.suggestedFileName(ExportFormat.plain), endsWith('.txt'));
    });
  });
}

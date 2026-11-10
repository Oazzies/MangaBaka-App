import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/database/database.dart' as db;
import 'package:mangabaka_app/features/library/services/mappers/db_to_api_mapper.dart';

void main() {
  group('DbToApiMapper', () {
    test('seriesFromDb maps basic fields correctly', () {
      final dbSeries = db.SeriesTableData(
        id: '1',
        title: 'Manga Title',
        state: 'published',
        coverUrl: 'https://example.com/cover.jpg',
        year: '2023',
        status: 'ongoing',
        secondaryTitles: '[]',
        authors: '[]',
        artists: '[]',
        description: 'Description',
        links: '[]',
        publishers: '[]',
        genres: '[]',
        tags: '[]',
      );

      final series = DbToApiMapper.seriesFromDb(dbSeries);

      expect(series.id, '1');
      expect(series.title, 'Manga Title');
      expect(series.state, 'published');
      expect(series.coverUrl, 'https://example.com/cover.jpg');
      expect(series.year, '2023');
      expect(series.status, 'ongoing');
    });

    test('seriesFromDb reuses the mapping only for an unchanged row', () {
      db.SeriesTableData row(String genres) => db.SeriesTableData(
        id: 'memo-1',
        title: 'Memo',
        coverUrl: '',
        description: '',
        secondaryTitles: '[]',
        authors: '[]',
        artists: '[]',
        links: '[]',
        publishers: '[]',
        genres: genres,
        tags: '[]',
      );

      final first = DbToApiMapper.seriesFromDb(row('["Action"]'));
      final same = DbToApiMapper.seriesFromDb(row('["Action"]'));
      final changed = DbToApiMapper.seriesFromDb(row('["Drama"]'));

      expect(identical(first, same), isTrue);
      expect(identical(first, changed), isFalse);
      expect(changed.genres, ['Drama']);
    });

    test('seriesFromDb decodes JSON fields correctly', () {
      final dbSeries = db.SeriesTableData(
        id: '1',
        title: 'Manga Title',
        secondaryTitles: jsonEncode(['Title 2', 'Title 3']),
        authors: jsonEncode(['Author 1']),
        genres: jsonEncode(['Action', 'Adventure']),
        published: jsonEncode({'from': '2023-01-01'}),
        coverUrl: '',
        artists: '[]',
        description: '',
        links: '[]',
        publishers: '[]',
        tags: '[]',
      );

      final series = DbToApiMapper.seriesFromDb(dbSeries);

      expect(series.secondaryTitles, ['Title 2', 'Title 3']);
      expect(series.authors, ['Author 1']);
      expect(series.genres, ['Action', 'Adventure']);
      expect(series.published?['from'], '2023-01-01');
    });

    test('seriesFromDb handles null and invalid JSON fields', () {
      final dbSeries = db.SeriesTableData(
        id: '1',
        title: 'Manga Title',
        secondaryTitles: '[]',
        authors: 'invalid json',
        genres: '',
        coverUrl: '',
        artists: '[]',
        description: '',
        links: '[]',
        publishers: '[]',
        tags: '[]',
      );

      final series = DbToApiMapper.seriesFromDb(dbSeries);

      expect(series.secondaryTitles, []);
      expect(series.authors, []);
      expect(series.genres, []);
    });

    test('libraryEntryFromDb maps library entry correctly', () {
      final dbSeries = db.SeriesTableData(
        id: '1',
        title: 'Manga Title',
        coverUrl: '',
        secondaryTitles: '[]',
        authors: '[]',
        artists: '[]',
        description: '',
        links: '[]',
        publishers: '[]',
        genres: '[]',
        tags: '[]',
      );
      final dbEntry = db.LibraryEntriesTableData(
        id: 'entry-1',
        seriesId: '1',
        state: 'reading',
        progressChapter: 5,
        progressVolume: 1,
        numberOfRereads: 0,
      );

      final combined = db.LibraryEntryWithSeries(
        libraryEntry: dbEntry,
        series: dbSeries,
      );

      final apiEntry = DbToApiMapper.libraryEntryFromDb(combined);

      expect(apiEntry.id, 'entry-1');
      expect(apiEntry.state, 'reading');
      expect(apiEntry.progressChapter, 5);
      expect(apiEntry.progressVolume, 1);
      expect(apiEntry.series.id, '1');
    });
  });
}

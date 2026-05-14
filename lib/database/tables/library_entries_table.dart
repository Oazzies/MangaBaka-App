import 'package:drift/drift.dart';
import 'series_table.dart';

class LibraryEntriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get state => text()();
  TextColumn get note => text().nullable()();
  IntColumn get progressChapter => integer().nullable()();
  IntColumn get progressVolume => integer().nullable()();
  IntColumn get numberOfRereads => integer().nullable()();
  IntColumn get rating => integer().nullable()();
  TextColumn get seriesId => text().references(SeriesTable, #id)();

  @override
  Set<Column> get primaryKey => {id};

  List<Index> get indexes => [Index('library_series_idx', 'CREATE INDEX IF NOT EXISTS library_series_idx ON library_entries_table (series_id)'), Index('library_state_idx', 'CREATE INDEX IF NOT EXISTS library_state_idx ON library_entries_table (state)')];
}

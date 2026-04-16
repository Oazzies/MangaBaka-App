import 'package:drift/drift.dart';

class SeriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get state => text().nullable()();
  TextColumn get title => text()();
  TextColumn get nativeTitle => text().nullable()();
  TextColumn get romanizedTitle => text().nullable()();
  TextColumn get coverUrl => text()();
  TextColumn get description => text()();
  TextColumn get year => text().nullable()();
  TextColumn get status => text().nullable()();
  TextColumn get contentRating => text().nullable()();
  TextColumn get type => text().nullable()();
  TextColumn get rating => text().nullable()();
  TextColumn get finalVolume => text().nullable()();
  TextColumn get totalChapters => text().nullable()();
  TextColumn get lastUpdated => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LibraryEntriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get state => text()();
  TextColumn get note => text().nullable()();
  IntColumn get progressChapter => integer().nullable()();
  IntColumn get progressVolume => integer().nullable()();
  IntColumn get numberOfRereads => integer().nullable()();
  TextColumn get seriesId => text().references(SeriesTable, #id)();

  @override
  Set<Column> get primaryKey => {id};
}
import 'package:drift/drift.dart';

class SeriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get state => text().nullable()();
  TextColumn get mergedWith => text().nullable()();
  TextColumn get title => text()();
  TextColumn get nativeTitle => text().nullable()();
  TextColumn get romanizedTitle => text().nullable()();
  TextColumn get secondaryTitles =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get coverUrl => text()();
  TextColumn get authors =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get artists =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get description => text()();
  TextColumn get year => text().nullable()();
  TextColumn get published => text().nullable()(); // JSON
  TextColumn get status => text().nullable()();
  TextColumn get isLicensed => text().nullable()();
  TextColumn get hasAnime => text().nullable()();
  TextColumn get anime => text().nullable()(); // JSON
  TextColumn get contentRating => text().nullable()();
  TextColumn get type => text().nullable()();
  TextColumn get rating => text().nullable()();
  TextColumn get finalVolume => text().nullable()();
  TextColumn get totalChapters => text().nullable()();
  TextColumn get links =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get publishers =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get genres =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get tags =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get lastUpdated => text().nullable()();
  TextColumn get relationships => text().nullable()(); // JSON
  TextColumn get source => text().nullable()(); // JSON

  @override
  Set<Column> get primaryKey => {id};

  List<Index> get indexes => [Index('series_title_idx', 'CREATE INDEX IF NOT EXISTS series_title_idx ON series_table (title)')];
}

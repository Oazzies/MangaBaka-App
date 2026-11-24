import 'package:drift/drift.dart';

class LibraryListsTable extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  BoolColumn get isPrivate => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// No foreign keys: the feed may name a list or series before it has delivered it.
class LibraryListEntriesTable extends Table {
  IntColumn get listId => integer()();
  TextColumn get seriesId => text()();

  @override
  Set<Column> get primaryKey => {listId, seriesId};
}

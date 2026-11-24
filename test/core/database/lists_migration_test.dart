import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mangabaka_app/core/database/database.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  setUp(() {
    if (!GetIt.I.isRegistered<LoggingService>()) {
      GetIt.I.registerSingleton<LoggingService>(LoggingService());
    }
  });

  test('a v3 database gains the list tables and keeps its library', () async {
    final raw = sqlite3.openInMemory();
    raw.execute('''
      CREATE TABLE series_table (
        id TEXT PRIMARY KEY, title TEXT, cover_url TEXT, description TEXT
      );
    ''');
    raw.execute('''
      CREATE TABLE library_entries_table (
        id TEXT PRIMARY KEY, series_id TEXT, state TEXT
      );
    ''');
    raw.execute(
      "INSERT INTO series_table (id, title, cover_url, description) "
      "VALUES ('42', 'Series 42', 'u', 'd');",
    );
    raw.execute(
      "INSERT INTO library_entries_table (id, series_id, state) "
      "VALUES ('e42', '42', 'reading');",
    );
    raw.execute('PRAGMA user_version = 3;');

    final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
    addTearDown(db.close);

    final entry = await db.libraryEntriesDao.getEntryBySeriesId('42');
    expect(entry?.libraryEntry.state, 'reading');

    await db.libraryListsDao.upsertLists([
      const LibraryListsTableCompanion(id: Value(1), name: Value('A')),
    ]);
    await db.libraryListsDao.setMemberships({
      '42': {1},
    });
    final lists = await db.libraryListsDao.getLists();
    expect(lists.single.name, 'A');
    expect(lists.single.isPrivate, isFalse);

    final indexes = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type='index'")
        .get();
    expect(
      indexes.map((r) => r.read<String>('name')),
      contains('library_list_entries_series_idx'),
    );
  });

  test('a feed upsert keeps the stored created_at', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.libraryListsDao.upsertLists([
      const LibraryListsTableCompanion(
        id: Value(1),
        name: Value('A'),
        createdAt: Value('2026-01-01T00:00:00.000Z'),
      ),
    ]);
    await db.libraryListsDao.upsertLists([
      const LibraryListsTableCompanion(
        id: Value(1),
        name: Value('B'),
        isPrivate: Value(true),
      ),
    ]);
    final row = (await db.libraryListsDao.getLists()).single;
    expect(row.name, 'B');
    expect(row.isPrivate, isTrue);
    expect(row.createdAt, '2026-01-01T00:00:00.000Z');
  });

  test('memberships without a library entry are pruned', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.libraryListsDao.setMemberships({
      '7': {1, 2},
    });
    await db.libraryListsDao.pruneMembershipsWithoutEntry();
    expect(await db.select(db.libraryListEntriesTable).get(), isEmpty);
  });
}

import 'package:bakahyou/database/database.dart';
import 'package:drift/drift.dart' as drift;

class StatisticsService {
  final AppDatabase _db;

  StatisticsService(this._db);

  Future<int> getTotalSeries() async {
    final count = drift.countAll();
    final query = _db.selectOnly(_db.libraryEntriesTable)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> getChaptersRead() async {
    final sum = _db.libraryEntriesTable.progressChapter.sum();
    final query = _db.selectOnly(_db.libraryEntriesTable)..addColumns([sum]);
    final result = await query.getSingle();
    return result.read(sum) ?? 0;
  }

  Future<int> getVolumesRead() async {
    final sum = _db.libraryEntriesTable.progressVolume.sum();
    final query = _db.selectOnly(_db.libraryEntriesTable)..addColumns([sum]);
    final result = await query.getSingle();
    return result.read(sum) ?? 0;
  }

  Future<double> getCompletionRate() async {
    final totalCount = drift.countAll();
    final completedCount = drift.countAll(filter: _db.libraryEntriesTable.state.equals('completed'));
    
    final queryTotal = _db.selectOnly(_db.libraryEntriesTable)..addColumns([totalCount]);
    final totalResult = await queryTotal.getSingle();
    final total = totalResult.read(totalCount) ?? 0;

    if (total == 0) return 0.0;

    final queryCompleted = _db.selectOnly(_db.libraryEntriesTable)
      ..addColumns([completedCount])
      ..where(_db.libraryEntriesTable.state.equals('completed'));
    final completedResult = await queryCompleted.getSingle();
    final completed = completedResult.read(completedCount) ?? 0;

    return (completed / total) * 100;
  }

  Future<int> getTotalRereads() async {
    final sum = _db.libraryEntriesTable.numberOfRereads.sum();
    final query = _db.selectOnly(_db.libraryEntriesTable)..addColumns([sum]);
    final result = await query.getSingle();
    return result.read(sum) ?? 0;
  }
}
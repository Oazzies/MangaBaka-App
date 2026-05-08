import 'package:bakahyou/database/database.dart';
import 'package:bakahyou/utils/services/logging_service.dart';
import 'package:bakahyou/utils/exceptions/app_exceptions.dart';
import 'package:drift/drift.dart' as drift;

class StatisticsService {
  final _logger = LoggingService.logger;
  final AppDatabase _db;

  StatisticsService(this._db);

  Future<int> getTotalSeries() async {
    try {
      final count = drift.countAll();
      final query = _db.selectOnly(_db.libraryEntriesTable)
        ..addColumns([count]);
      final result = await query.getSingle();
      return result.read(count) ?? 0;
    } catch (e, st) {
      _logger.severe('Failed to get total series: $e\n$st');
      throw DatabaseException(message: 'Failed to get total series', originalError: e, stackTrace: st);
    }
  }

  Future<int> getChaptersRead() async {
    try {
      final sum = _db.libraryEntriesTable.progressChapter.sum();
      final query = _db.selectOnly(_db.libraryEntriesTable)..addColumns([sum]);
      final result = await query.getSingle();
      return result.read(sum) ?? 0;
    } catch (e, st) {
      _logger.severe('Failed to get chapters read: $e\n$st');
      throw DatabaseException(message: 'Failed to get chapters read', originalError: e, stackTrace: st);
    }
  }

  Future<int> getVolumesRead() async {
    try {
      final sum = _db.libraryEntriesTable.progressVolume.sum();
      final query = _db.selectOnly(_db.libraryEntriesTable)..addColumns([sum]);
      final result = await query.getSingle();
      return result.read(sum) ?? 0;
    } catch (e, st) {
      _logger.severe('Failed to get volumes read: $e\n$st');
      throw DatabaseException(message: 'Failed to get volumes read', originalError: e, stackTrace: st);
    }
  }

  Future<double> getCompletionRate() async {
    try {
      final totalCount = drift.countAll();
      final completedCount = drift.countAll(
        filter: _db.libraryEntriesTable.state.equals('completed'),
      );

      final queryTotal = _db.selectOnly(_db.libraryEntriesTable)
        ..addColumns([totalCount]);
      final totalResult = await queryTotal.getSingle();
      final total = totalResult.read(totalCount) ?? 0;

      if (total == 0) return 0.0;

      final queryCompleted = _db.selectOnly(_db.libraryEntriesTable)
        ..addColumns([completedCount])
        ..where(_db.libraryEntriesTable.state.equals('completed'));
      final completedResult = await queryCompleted.getSingle();
      final completed = completedResult.read(completedCount) ?? 0;

      return (completed / total) * 100;
    } catch (e, st) {
      _logger.severe('Failed to get completion rate: $e\n$st');
      throw DatabaseException(message: 'Failed to get completion rate', originalError: e, stackTrace: st);
    }
  }

  Future<int> getTotalRereads() async {
    try {
      final sum = _db.libraryEntriesTable.numberOfRereads.sum();
      final query = _db.selectOnly(_db.libraryEntriesTable)..addColumns([sum]);
      final result = await query.getSingle();
      return result.read(sum) ?? 0;
    } catch (e, st) {
      _logger.severe('Failed to get total rereads: $e\n$st');
      throw DatabaseException(message: 'Failed to get total rereads', originalError: e, stackTrace: st);
    }
  }

  Future<double> getMeanScore() async {
    try {
      final avg = _db.libraryEntriesTable.rating.avg();
      final query = _db.selectOnly(_db.libraryEntriesTable)
        ..addColumns([avg])
        ..where(_db.libraryEntriesTable.rating.isNotNull());
      final result = await query.getSingle();
      return result.read(avg) ?? 0.0;
    } catch (e, st) {
      _logger.severe('Failed to get mean score: $e\n$st');
      throw DatabaseException(message: 'Failed to get mean score', originalError: e, stackTrace: st);
    }
  }

  Future<double> getFinishRate() async {
    try {
      final completedExpr = _db.libraryEntriesTable.state.equals('completed');
      final droppedExpr = _db.libraryEntriesTable.state.equals('dropped');
      
      final completedCount = drift.countAll(filter: completedExpr);
      final droppedCount = drift.countAll(filter: droppedExpr);

      final query = _db.selectOnly(_db.libraryEntriesTable)
        ..addColumns([completedCount, droppedCount]);
      
      final result = await query.getSingle();
      final completed = result.read(completedCount) ?? 0;
      final dropped = result.read(droppedCount) ?? 0;

      final total = completed + dropped;
      if (total == 0) return 0.0;

      return (completed / total) * 100;
    } catch (e, st) {
      _logger.severe('Failed to get finish rate: $e\n$st');
      throw DatabaseException(message: 'Failed to get finish rate', originalError: e, stackTrace: st);
    }
  }

  Future<LibraryEntryWithSeries?> getHighestRatedSeries() async {
    try {
      final query = _db.select(_db.libraryEntriesTable).join([
        drift.innerJoin(
          _db.seriesTable,
          _db.seriesTable.id.equalsExp(_db.libraryEntriesTable.seriesId),
        ),
      ])
        ..where(_db.libraryEntriesTable.rating.isNotNull())
        ..orderBy([
          drift.OrderingTerm(
            expression: _db.libraryEntriesTable.rating,
            mode: drift.OrderingMode.desc,
          ),
          drift.OrderingTerm(
            expression: _db.seriesTable.title,
            mode: drift.OrderingMode.asc,
          ),
        ])
        ..limit(1);

      final row = await query.getSingleOrNull();
      if (row == null) return null;

      return LibraryEntryWithSeries(
        libraryEntry: row.readTable(_db.libraryEntriesTable),
        series: row.readTable(_db.seriesTable),
      );
    } catch (e, st) {
      _logger.severe('Failed to get highest rated series: $e\n$st');
      throw DatabaseException(message: 'Failed to get highest rated series', originalError: e, stackTrace: st);
    }
  }

  Future<LibraryEntryWithSeries?> getMostRereadSeries() async {
    try {
      final query = _db.select(_db.libraryEntriesTable).join([
        drift.innerJoin(
          _db.seriesTable,
          _db.seriesTable.id.equalsExp(_db.libraryEntriesTable.seriesId),
        ),
      ])
        ..where(_db.libraryEntriesTable.numberOfRereads.isNotNull())
        ..where(_db.libraryEntriesTable.numberOfRereads.isBiggerThan(const drift.Constant(0)))
        ..orderBy([
          drift.OrderingTerm(
            expression: _db.libraryEntriesTable.numberOfRereads,
            mode: drift.OrderingMode.desc,
          ),
          drift.OrderingTerm(
            expression: _db.seriesTable.title,
            mode: drift.OrderingMode.asc,
          ),
        ])
        ..limit(1);

      final row = await query.getSingleOrNull();
      if (row == null) return null;

      return LibraryEntryWithSeries(
        libraryEntry: row.readTable(_db.libraryEntriesTable),
        series: row.readTable(_db.seriesTable),
      );
    } catch (e, st) {
      _logger.severe('Failed to get most reread series: $e\n$st');
      throw DatabaseException(message: 'Failed to get most reread series', originalError: e, stackTrace: st);
    }
  }
}

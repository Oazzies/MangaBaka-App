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
}

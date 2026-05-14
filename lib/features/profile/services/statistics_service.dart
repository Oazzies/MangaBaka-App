import 'package:mangabaka_app/database/database.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/exceptions/app_exceptions.dart';
import 'package:drift/drift.dart' as drift;

class StatisticsService {
  final _logger = LoggingService.logger;
  final AppDatabase _db;

  StatisticsService(this._db);

  Future<int> getTotalSeries({List<String>? contentPreferences}) async {
    try {
      final count = drift.countAll();
      final query = _db.selectOnly(_db.libraryEntriesTable).join([
        drift.innerJoin(
          _db.seriesTable,
          _db.seriesTable.id.equalsExp(_db.libraryEntriesTable.seriesId),
        ),
      ])..addColumns([count]);

      if (contentPreferences != null && contentPreferences.isNotEmpty) {
        query.where(_db.seriesTable.contentRating.isIn(contentPreferences.map((e) => e.toLowerCase()).toList()));
      }

      final result = await query.getSingle();
      final val = result.read(count) ?? 0;
      _logger.fine('Total series count: $val');
      return val;
    } catch (e, st) {
      _logger.severe('Failed to get total series from DB: $e\n$st');
      throw DatabaseException(message: 'Failed to get total series', originalError: e, stackTrace: st);
    }
  }

  Future<int> getChaptersRead({List<String>? contentPreferences}) async {
    try {
      final sum = _db.libraryEntriesTable.progressChapter.sum();
      final query = _db.selectOnly(_db.libraryEntriesTable).join([
        drift.innerJoin(
          _db.seriesTable,
          _db.seriesTable.id.equalsExp(_db.libraryEntriesTable.seriesId),
        ),
      ])..addColumns([sum]);

      if (contentPreferences != null && contentPreferences.isNotEmpty) {
        query.where(_db.seriesTable.contentRating.isIn(contentPreferences.map((e) => e.toLowerCase()).toList()));
      }

      final result = await query.getSingle();
      final val = result.read(sum) ?? 0;
      _logger.fine('Total chapters read: $val');
      return val;
    } catch (e, st) {
      _logger.severe('Failed to get chapters read from DB: $e\n$st');
      throw DatabaseException(message: 'Failed to get chapters read', originalError: e, stackTrace: st);
    }
  }

  Future<int> getVolumesRead({List<String>? contentPreferences}) async {
    try {
      final sum = _db.libraryEntriesTable.progressVolume.sum();
      final query = _db.selectOnly(_db.libraryEntriesTable).join([
        drift.innerJoin(
          _db.seriesTable,
          _db.seriesTable.id.equalsExp(_db.libraryEntriesTable.seriesId),
        ),
      ])..addColumns([sum]);

      if (contentPreferences != null && contentPreferences.isNotEmpty) {
        query.where(_db.seriesTable.contentRating.isIn(contentPreferences.map((e) => e.toLowerCase()).toList()));
      }

      final result = await query.getSingle();
      final val = result.read(sum) ?? 0;
      _logger.fine('Total volumes read: $val');
      return val;
    } catch (e, st) {
      _logger.severe('Failed to get volumes read from DB: $e\n$st');
      throw DatabaseException(message: 'Failed to get volumes read', originalError: e, stackTrace: st);
    }
  }

  Future<double> getCompletionRate({List<String>? contentPreferences}) async {
    try {
      final totalCount = drift.countAll();
      final completedCount = drift.countAll(
        filter: _db.libraryEntriesTable.state.equals('completed'),
      );

      final queryTotal = _db.selectOnly(_db.libraryEntriesTable).join([
        drift.innerJoin(
          _db.seriesTable,
          _db.seriesTable.id.equalsExp(_db.libraryEntriesTable.seriesId),
        ),
      ])..addColumns([totalCount]);

      if (contentPreferences != null && contentPreferences.isNotEmpty) {
        queryTotal.where(_db.seriesTable.contentRating.isIn(contentPreferences.map((e) => e.toLowerCase()).toList()));
      }

      final totalResult = await queryTotal.getSingle();
      final total = totalResult.read(totalCount) ?? 0;

      if (total == 0) return 0.0;

      final queryCompleted = _db.selectOnly(_db.libraryEntriesTable).join([
        drift.innerJoin(
          _db.seriesTable,
          _db.seriesTable.id.equalsExp(_db.libraryEntriesTable.seriesId),
        ),
      ])
        ..addColumns([completedCount])
        ..where(_db.libraryEntriesTable.state.equals('completed'));

      if (contentPreferences != null && contentPreferences.isNotEmpty) {
        queryCompleted.where(_db.seriesTable.contentRating.isIn(contentPreferences.map((e) => e.toLowerCase()).toList()));
      }

      final completedResult = await queryCompleted.getSingle();
      final completed = completedResult.read(completedCount) ?? 0;

      final rate = (completed / total) * 100;
      _logger.fine('Completion rate: $rate% ($completed/$total)');
      return rate;
    } catch (e, st) {
      _logger.severe('Failed to calculate completion rate: $e\n$st');
      throw DatabaseException(message: 'Failed to get completion rate', originalError: e, stackTrace: st);
    }
  }

  Future<int> getTotalRereads({List<String>? contentPreferences}) async {
    try {
      final sum = _db.libraryEntriesTable.numberOfRereads.sum();
      final query = _db.selectOnly(_db.libraryEntriesTable).join([
        drift.innerJoin(
          _db.seriesTable,
          _db.seriesTable.id.equalsExp(_db.libraryEntriesTable.seriesId),
        ),
      ])..addColumns([sum]);

      if (contentPreferences != null && contentPreferences.isNotEmpty) {
        query.where(_db.seriesTable.contentRating.isIn(contentPreferences.map((e) => e.toLowerCase()).toList()));
      }

      final result = await query.getSingle();
      final val = result.read(sum) ?? 0;
      _logger.fine('Total rereads: $val');
      return val;
    } catch (e, st) {
      _logger.severe('Failed to get total rereads from DB: $e\n$st');
      throw DatabaseException(message: 'Failed to get total rereads', originalError: e, stackTrace: st);
    }
  }

  Future<double> getMeanScore({List<String>? contentPreferences}) async {
    try {
      final avg = _db.libraryEntriesTable.rating.avg();
      final query = _db.selectOnly(_db.libraryEntriesTable).join([
        drift.innerJoin(
          _db.seriesTable,
          _db.seriesTable.id.equalsExp(_db.libraryEntriesTable.seriesId),
        ),
      ])
        ..addColumns([avg])
        ..where(_db.libraryEntriesTable.rating.isNotNull());

      if (contentPreferences != null && contentPreferences.isNotEmpty) {
        query.where(_db.seriesTable.contentRating.isIn(contentPreferences.map((e) => e.toLowerCase()).toList()));
      }

      final result = await query.getSingle();
      final val = result.read(avg) ?? 0.0;
      _logger.fine('Mean score: $val');
      return val;
    } catch (e, st) {
      _logger.severe('Failed to calculate mean score: $e\n$st');
      throw DatabaseException(message: 'Failed to get mean score', originalError: e, stackTrace: st);
    }
  }

  Future<double> getFinishRate({List<String>? contentPreferences}) async {
    try {
      final completedExpr = _db.libraryEntriesTable.state.equals('completed');
      final droppedExpr = _db.libraryEntriesTable.state.equals('dropped');
      
      final completedCount = drift.countAll(filter: completedExpr);
      final droppedCount = drift.countAll(filter: droppedExpr);

      final query = _db.selectOnly(_db.libraryEntriesTable).join([
        drift.innerJoin(
          _db.seriesTable,
          _db.seriesTable.id.equalsExp(_db.libraryEntriesTable.seriesId),
        ),
      ])..addColumns([completedCount, droppedCount]);
      
      if (contentPreferences != null && contentPreferences.isNotEmpty) {
        query.where(_db.seriesTable.contentRating.isIn(contentPreferences.map((e) => e.toLowerCase()).toList()));
      }

      final result = await query.getSingle();
      final completed = result.read(completedCount) ?? 0;
      final dropped = result.read(droppedCount) ?? 0;

      final total = completed + dropped;
      if (total == 0) return 0.0;

      final rate = (completed / total) * 100;
      _logger.fine('Finish rate: $rate% ($completed completed, $dropped dropped)');
      return rate;
    } catch (e, st) {
      _logger.severe('Failed to calculate finish rate: $e\n$st');
      throw DatabaseException(message: 'Failed to get finish rate', originalError: e, stackTrace: st);
    }
  }

  Future<LibraryEntryWithSeries?> getHighestRatedSeries({List<String>? contentPreferences}) async {
    try {
      final query = _db.select(_db.libraryEntriesTable).join([
        drift.innerJoin(
          _db.seriesTable,
          _db.seriesTable.id.equalsExp(_db.libraryEntriesTable.seriesId),
        ),
      ])
        ..where(_db.libraryEntriesTable.rating.isNotNull());

      if (contentPreferences != null && contentPreferences.isNotEmpty) {
        query.where(_db.seriesTable.contentRating.isIn(contentPreferences.map((e) => e.toLowerCase()).toList()));
      }

      query
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
      if (row == null) {
        _logger.fine('No rated series found for highest rated check');
        return null;
      }

      final entry = LibraryEntryWithSeries(
        libraryEntry: row.readTable(_db.libraryEntriesTable),
        series: row.readTable(_db.seriesTable),
      );
      _logger.fine('Highest rated series found: ${entry.series.title}');
      return entry;
    } catch (e, st) {
      _logger.severe('Failed to get highest rated series from DB: $e\n$st');
      throw DatabaseException(message: 'Failed to get highest rated series', originalError: e, stackTrace: st);
    }
  }

  Future<LibraryEntryWithSeries?> getMostRereadSeries({List<String>? contentPreferences}) async {
    try {
      final query = _db.select(_db.libraryEntriesTable).join([
        drift.innerJoin(
          _db.seriesTable,
          _db.seriesTable.id.equalsExp(_db.libraryEntriesTable.seriesId),
        ),
      ])
        ..where(_db.libraryEntriesTable.numberOfRereads.isNotNull())
        ..where(_db.libraryEntriesTable.numberOfRereads.isBiggerThan(const drift.Constant(0)));

      if (contentPreferences != null && contentPreferences.isNotEmpty) {
        query.where(_db.seriesTable.contentRating.isIn(contentPreferences.map((e) => e.toLowerCase()).toList()));
      }

      query
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
      if (row == null) {
        _logger.fine('No reread series found for most reread check');
        return null;
      }

      final entry = LibraryEntryWithSeries(
        libraryEntry: row.readTable(_db.libraryEntriesTable),
        series: row.readTable(_db.seriesTable),
      );
      _logger.fine('Most reread series found: ${entry.series.title}');
      return entry;
    } catch (e, st) {
      _logger.severe('Failed to get most reread series from DB: $e\n$st');
      throw DatabaseException(message: 'Failed to get most reread series', originalError: e, stackTrace: st);
    }
  }
}

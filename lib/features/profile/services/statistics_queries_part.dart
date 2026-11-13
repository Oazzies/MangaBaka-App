part of 'statistics_service.dart';

mixin _StatisticsQueriesMixin {
  AppDatabase get _db;
  Logger get _logger;

  /// The publishers behind the most series in the library, biggest first.
  ///
  /// Counted by name: the local database stores publisher names only, not ids.
  Future<List<({String name, int count})>> getTopPublishers({
    List<String>? contentPreferences,
    int limit = 8,
  }) async {
    try {
      final query = _db.selectOnly(_db.libraryEntriesTable).join([
        drift.innerJoin(
          _db.seriesTable,
          _db.seriesTable.id.equalsExp(_db.libraryEntriesTable.seriesId),
        ),
      ])..addColumns([_db.seriesTable.publishers]);

      if (contentPreferences != null && contentPreferences.isNotEmpty) {
        query.where(
          _db.seriesTable.contentRating.isIn(
            contentPreferences.map((e) => e.toLowerCase()).toList(),
          ),
        );
      }

      final counts = <String, int>{};
      for (final row in await query.get()) {
        final raw = row.read(_db.seriesTable.publishers);
        if (raw == null || raw.isEmpty) continue;
        final Object? decoded;
        try {
          decoded = json.decode(raw);
        } on FormatException {
          continue;
        }
        if (decoded is! List) continue;
        // A series listing the same publisher twice (two regional editions)
        // still counts once toward that publisher.
        for (final name in {for (final p in decoded) p.toString()}) {
          if (name.isNotEmpty) counts[name] = (counts[name] ?? 0) + 1;
        }
      }

      final sorted = counts.entries.toList()
        ..sort((a, b) {
          final byCount = b.value.compareTo(a.value);
          return byCount != 0 ? byCount : a.key.compareTo(b.key);
        });
      return [
        for (final e in sorted.take(limit)) (name: e.key, count: e.value),
      ];
    } catch (e, st) {
      _logger.severe('Failed to get top publishers from DB', e, st);
      throw DatabaseException(
        message: 'Failed to get top publishers',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<LibraryEntryWithSeries?> getMostRereadSeries({
    List<String>? contentPreferences,
  }) async {
    try {
      final query =
          _db.select(_db.libraryEntriesTable).join([
              drift.innerJoin(
                _db.seriesTable,
                _db.seriesTable.id.equalsExp(_db.libraryEntriesTable.seriesId),
              ),
            ])
            ..where(_db.libraryEntriesTable.numberOfRereads.isNotNull())
            ..where(
              _db.libraryEntriesTable.numberOfRereads.isBiggerThan(
                const drift.Constant(0),
              ),
            );

      if (contentPreferences != null && contentPreferences.isNotEmpty) {
        query.where(
          _db.seriesTable.contentRating.isIn(
            contentPreferences.map((e) => e.toLowerCase()).toList(),
          ),
        );
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
      _logger.severe('Failed to get most reread series from DB', e, st);
      throw DatabaseException(
        message: 'Failed to get most reread series',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<LibraryEntryWithSeries?> getHighestRatedSeries({
    List<String>? contentPreferences,
  }) async {
    try {
      final query = _db.select(_db.libraryEntriesTable).join([
        drift.innerJoin(
          _db.seriesTable,
          _db.seriesTable.id.equalsExp(_db.libraryEntriesTable.seriesId),
        ),
      ])..where(_db.libraryEntriesTable.rating.isNotNull());

      if (contentPreferences != null && contentPreferences.isNotEmpty) {
        query.where(
          _db.seriesTable.contentRating.isIn(
            contentPreferences.map((e) => e.toLowerCase()).toList(),
          ),
        );
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
      _logger.severe('Failed to get highest rated series from DB', e, st);
      throw DatabaseException(
        message: 'Failed to get highest rated series',
        originalError: e,
        stackTrace: st,
      );
    }
  }
}

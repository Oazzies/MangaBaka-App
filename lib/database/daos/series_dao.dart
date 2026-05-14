part of '../database.dart';

@DriftAccessor(tables: [SeriesTable])
class SeriesDao extends DatabaseAccessor<AppDatabase> with _$SeriesDaoMixin {
  final _logger = LoggingService.logger;
  SeriesDao(super.db);

  Future<SeriesTableData?> getLatestUpdatedSeries() async {
    try {
      return await (select(seriesTable)
            ..orderBy([
              (t) => OrderingTerm(
                expression: t.lastUpdated,
                mode: OrderingMode.desc,
              ),
            ])
            ..limit(1))
          .getSingleOrNull();
    } catch (e) {
      _logger.severe('Failed to get latest updated series: $e');
      throw exc.DatabaseException(message: 'Failed to get latest updated series', originalError: e);
    }
  }

  Future<void> upsertSeries(List<api.Series> series) async {
    if (series.isEmpty) return;
    try {
      await db.batch((batch) {
        batch.insertAll(
          db.seriesTable,
          series.map(
            (s) => SeriesTableCompanion.insert(
              id: s.id,
              state: Value(s.state),
              mergedWith: Value(s.mergedWith),
              title: s.title,
              nativeTitle: Value(s.nativeTitle),
              romanizedTitle: Value(s.romanizedTitle),
              secondaryTitles: Value(json.encode(s.secondaryTitles)),
              coverUrl: s.coverUrl,
              authors: Value(json.encode(s.authors)),
              artists: Value(json.encode(s.artists)),
              description: s.description,
              year: Value(s.year),
              published: Value(
                s.published != null ? json.encode(s.published) : null,
              ),
              status: Value(s.status),
              isLicensed: Value(s.isLicensed),
              hasAnime: Value(s.hasAnime),
              anime: Value(s.anime != null ? json.encode(s.anime) : null),
              contentRating: Value(s.contentRating),
              type: Value(s.type),
              rating: Value(s.rating),
              finalVolume: Value(s.finalVolume),
              totalChapters: Value(s.totalChapters),
              links: Value(json.encode(s.links)),
              publishers: Value(json.encode(s.publishers)),
              genres: Value(json.encode(s.genres)),
              tags: Value(json.encode(s.tags)),
              lastUpdated: Value(s.lastUpdated),
              relationships: Value(
                s.relationships != null ? json.encode(s.relationships) : null,
              ),
              source: Value(s.source != null ? json.encode(s.source) : null),
            ),
          ),
          onConflict: DoUpdate(
            (old) => SeriesTableCompanion.custom(
              state: const CustomExpression<String>('excluded.state'),
              mergedWith: const CustomExpression<String>(
                'excluded.merged_with',
              ),
              title: const CustomExpression<String>('excluded.title'),
              nativeTitle: const CustomExpression<String>(
                'excluded.native_title',
              ),
              romanizedTitle: const CustomExpression<String>(
                'excluded.romanized_title',
              ),
              secondaryTitles: const CustomExpression<String>(
                'excluded.secondary_titles',
              ),
              coverUrl: const CustomExpression<String>('excluded.cover_url'),
              authors: const CustomExpression<String>('excluded.authors'),
              artists: const CustomExpression<String>('excluded.artists'),
              description: const CustomExpression<String>(
                'excluded.description',
              ),
              year: const CustomExpression<String>('excluded.year'),
              published: const CustomExpression<String>('excluded.published'),
              status: const CustomExpression<String>('excluded.status'),
              isLicensed: const CustomExpression<String>(
                'excluded.is_licensed',
              ),
              hasAnime: const CustomExpression<String>('excluded.has_anime'),
              anime: const CustomExpression<String>('excluded.anime'),
              contentRating: const CustomExpression<String>(
                'excluded.content_rating',
              ),
              type: const CustomExpression<String>('excluded.type'),
              rating: const CustomExpression<String>('excluded.rating'),
              finalVolume: const CustomExpression<String>(
                'excluded.final_volume',
              ),
              totalChapters: const CustomExpression<String>(
                'excluded.total_chapters',
              ),
              links: const CustomExpression<String>('excluded.links'),
              publishers: const CustomExpression<String>('excluded.publishers'),
              genres: const CustomExpression<String>('excluded.genres'),
              tags: const CustomExpression<String>('excluded.tags'),
              lastUpdated: const CustomExpression<String>(
                'excluded.last_updated',
              ),
              relationships: const CustomExpression<String>(
                'excluded.relationships',
              ),
              source: const CustomExpression<String>('excluded.source'),
            ),
          ),
        );
      });
    } catch (e) {
      _logger.severe('Failed to upsert series: $e');
      throw exc.DatabaseException(message: 'Failed to upsert series', originalError: e);
    }
  }

  Future<void> insertLibraryEntry(
    String id,
    String state,
    String seriesId,
  ) async {
    try {
      await into(db.libraryEntriesTable).insert(
        LibraryEntriesTableCompanion.insert(
          id: id,
          state: state,
          seriesId: seriesId,
        ),
      );
    } catch (e) {
      _logger.severe('Failed to insert library entry: $e');
      throw exc.DatabaseException(message: 'Failed to insert library entry', originalError: e);
    }
  }

  Future<LibraryEntryWithSeries?> getEntryWithSeries(String entryId) async {
    try {
      final query = select(db.libraryEntriesTable).join([
        innerJoin(
          db.seriesTable,
          db.seriesTable.id.equalsExp(db.libraryEntriesTable.seriesId),
        ),
      ])..where(db.libraryEntriesTable.id.equals(entryId));

      final result = await query.getSingleOrNull();
      if (result == null) return null;

      return LibraryEntryWithSeries(
        libraryEntry: result.readTable(db.libraryEntriesTable),
        series: result.readTable(db.seriesTable),
      );
    } catch (e) {
      _logger.severe('Failed to get entry with series: $e');
      throw exc.DatabaseException(message: 'Failed to get entry with series', originalError: e);
    }
  }

  Future<void> deleteStaleSeries() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      // Select series that are NOT in the library and were last updated > 7 days ago
      final query = delete(seriesTable)..where((t) {
        final isInLibrary = exists(
          select(db.libraryEntriesTable)..where((l) => l.seriesId.equalsExp(t.id)),
        );
        return isInLibrary.not() & t.lastUpdated.isSmallerThanValue(sevenDaysAgo);
      });

      final deletedCount = await query.go();
      _logger.info('Database Maintenance: Cleaned up $deletedCount stale series entries.');
    } catch (e) {
      _logger.warning('Failed to clean up stale series: $e');
    }
  }
}

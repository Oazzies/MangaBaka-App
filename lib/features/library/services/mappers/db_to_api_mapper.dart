import 'dart:convert';
import 'package:bakahyou/database/database.dart' as db;
import 'package:bakahyou/features/library/models/library_entry.dart' as api;
import 'package:bakahyou/features/series/models/series.dart' as api;

class DbToApiMapper {
  static api.LibraryEntry libraryEntryFromDb(db.LibraryEntryWithSeries dbEntry) {
    return api.LibraryEntry(
      id: dbEntry.libraryEntry.id,
      state: dbEntry.libraryEntry.state,
      note: dbEntry.libraryEntry.note,
      progressChapter: dbEntry.libraryEntry.progressChapter,
      progressVolume: dbEntry.libraryEntry.progressVolume,
      numberOfRereads: dbEntry.libraryEntry.numberOfRereads,
      series: _seriesFromDb(dbEntry.series),
    );
  }

  static api.Series _seriesFromDb(db.SeriesTableData dbSeries) {
    // Deserialize genres from JSON string
    List<String> genres = [];
    try {
      if (dbSeries.genres.isNotEmpty) {
        final decoded = jsonDecode(dbSeries.genres);
        if (decoded is List) {
          genres = decoded.cast<String>();
        }
      }
    } catch (e) {
      // If JSON decode fails, default to empty list
      genres = [];
    }

    return api.Series(
      id: dbSeries.id,
      state: dbSeries.state ?? '',
      title: dbSeries.title,
      nativeTitle: dbSeries.nativeTitle ?? '',
      romanizedTitle: dbSeries.romanizedTitle ?? '',
      coverUrl: dbSeries.coverUrl,
      description: dbSeries.description,
      year: dbSeries.year ?? '',
      status: dbSeries.status ?? '',
      contentRating: dbSeries.contentRating ?? '',
      type: dbSeries.type ?? '',
      rating: dbSeries.rating ?? '',
      finalVolume: dbSeries.finalVolume ?? '',
      totalChapters: dbSeries.totalChapters ?? '',
      lastUpdated: dbSeries.lastUpdated ?? '',
      genres: genres,
      // These fields are not stored in the DB
      secondaryTitles: [],
      authors: [],
      artists: [],
      published: null,
      isLicensed: '',
      hasAnime: '',
      anime: null,
      links: [],
      publishers: [],
      tags: [],
      relationships: null,
      source: null,
      mergedWith: null,
    );
  }
}
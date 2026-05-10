import 'dart:convert';
import 'package:mangabaka_app/database/database.dart' as db;
import 'package:mangabaka_app/features/library/models/library_entry.dart' as api;
import 'package:mangabaka_app/features/series/models/series.dart' as api;

class DbToApiMapper {
  static api.LibraryEntry libraryEntryFromDb(
    db.LibraryEntryWithSeries dbEntry,
  ) {
    return api.LibraryEntry(
      id: dbEntry.libraryEntry.id,
      state: dbEntry.libraryEntry.state,
      note: dbEntry.libraryEntry.note,
      progressChapter: dbEntry.libraryEntry.progressChapter,
      progressVolume: dbEntry.libraryEntry.progressVolume,
      numberOfRereads: dbEntry.libraryEntry.numberOfRereads,
      series: seriesFromDb(dbEntry.series),
    );
  }

  static api.Series seriesFromDb(db.SeriesTableData dbSeries) {
    List<String> decodeStringArray(String? jsonStr) {
      if (jsonStr == null || jsonStr.isEmpty) return [];
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          return decoded.cast<String>();
        }
      } catch (_) {}
      return [];
    }

    Map<String, dynamic>? decodeJsonObject(String? jsonStr) {
      if (jsonStr == null || jsonStr.isEmpty) return null;
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map) {
          return decoded.cast<String, dynamic>();
        }
      } catch (_) {}
      return null;
    }

    List<dynamic> decodeList(String? jsonStr) {
      if (jsonStr == null || jsonStr.isEmpty) return [];
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          return decoded;
        }
      } catch (_) {}
      return [];
    }

    return api.Series(
      id: dbSeries.id,
      state: dbSeries.state ?? '',
      mergedWith: dbSeries.mergedWith,
      title: dbSeries.title,
      nativeTitle: dbSeries.nativeTitle ?? '',
      romanizedTitle: dbSeries.romanizedTitle ?? '',
      secondaryTitles: decodeStringArray(dbSeries.secondaryTitles),
      coverUrl: dbSeries.coverUrl,
      rawCoverUrl: dbSeries.coverUrl,
      authors: decodeStringArray(dbSeries.authors),
      artists: decodeStringArray(dbSeries.artists),
      description: dbSeries.description,
      year: dbSeries.year ?? '',
      published: decodeJsonObject(dbSeries.published),
      status: dbSeries.status ?? '',
      isLicensed: dbSeries.isLicensed ?? '',
      hasAnime: dbSeries.hasAnime ?? '',
      anime: decodeJsonObject(dbSeries.anime),
      contentRating: dbSeries.contentRating ?? '',
      type: dbSeries.type ?? '',
      rating: dbSeries.rating ?? '',
      finalVolume: dbSeries.finalVolume ?? '',
      totalChapters: dbSeries.totalChapters ?? '',
      links: decodeList(dbSeries.links),
      publishers: decodeStringArray(dbSeries.publishers),
      genres: decodeStringArray(dbSeries.genres),
      tags: decodeStringArray(dbSeries.tags),
      lastUpdated: dbSeries.lastUpdated ?? '',
      relationships: decodeJsonObject(dbSeries.relationships),
      source: decodeJsonObject(dbSeries.source),
    );
  }
}

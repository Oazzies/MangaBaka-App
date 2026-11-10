import 'dart:convert';
import 'package:mangabaka_app/core/database/database.dart' as db;
import 'package:mangabaka_app/core/utils/json_utils.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart'
    as api;
import 'package:mangabaka_app/features/series/models/series.dart' as api;
import 'package:mangabaka_app/features/series/models/series_titles.dart';

class DbToApiMapper {
  // ── JSON decode helpers ───────────────────────────────────────────────────

  static List<String> _decodeStringArray(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) return decoded.whereType<String>().toList();
    } on FormatException {
      // A corrupt cached column reads as empty.
    }
    return [];
  }

  static Map<String, dynamic>? _decodeJsonObject(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } on FormatException {
      // A corrupt cached column reads as empty.
    }
    return null;
  }

  static List<dynamic> _decodeList(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) return decoded;
    } on FormatException {
      // A corrupt cached column reads as empty.
    }
    return [];
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

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
      rating: dbEntry.libraryEntry.rating,
      series: seriesFromDb(dbEntry.series),
    );
  }

  static api.Series seriesFromDb(db.SeriesTableData dbSeries) {
    final source = _decodeJsonObject(dbSeries.source);

    // Calculate combined average if source data is available
    String rating = dbSeries.rating ?? '';
    if (source != null && source.isNotEmpty) {
      final normalizedRatings = source.values
          .map(JsonUtils.normalizedRating)
          .whereType<double>()
          .toList();
      if (normalizedRatings.isNotEmpty) {
        final avg =
            normalizedRatings.reduce((a, b) => a + b) /
            normalizedRatings.length;
        rating = avg.toStringAsFixed(1);
      }
    }

    final secondaryTitles = _decodeStringArray(dbSeries.secondaryTitles);
    // Stored rows hold the server's canonical titles; remember them so a
    // later, less exact payload for the same series (a v2 rail) agrees.
    if (SeriesTitles.lookup(dbSeries.id)?.main != dbSeries.title) {
      SeriesTitles.remember(
        dbSeries.id,
        SeriesTitles.stored(
          main: dbSeries.title,
          native: dbSeries.nativeTitle ?? '',
          romanized: dbSeries.romanizedTitle ?? '',
          secondary: secondaryTitles,
        ),
      );
    }

    return api.Series(
      id: dbSeries.id,
      state: dbSeries.state ?? '',
      mergedWith: dbSeries.mergedWith,
      title: dbSeries.title,
      nativeTitle: dbSeries.nativeTitle ?? '',
      romanizedTitle: dbSeries.romanizedTitle ?? '',
      secondaryTitles: secondaryTitles,
      coverUrl: dbSeries.coverUrl,
      rawCoverUrl: dbSeries.coverUrl,
      authors: _decodeStringArray(dbSeries.authors),
      artists: _decodeStringArray(dbSeries.artists),
      description: dbSeries.description,
      year: dbSeries.year ?? '',
      published: _decodeJsonObject(dbSeries.published),
      status: dbSeries.status ?? '',
      isLicensed: dbSeries.isLicensed ?? '',
      hasAnime: dbSeries.hasAnime ?? '',
      anime: _decodeJsonObject(dbSeries.anime),
      contentRating: dbSeries.contentRating ?? '',
      type: dbSeries.type ?? '',
      rating: rating,
      finalVolume: dbSeries.finalVolume ?? '',
      totalChapters: dbSeries.totalChapters ?? '',
      links: _decodeList(dbSeries.links),
      publishers: _decodeStringArray(dbSeries.publishers),
      genres: _decodeStringArray(dbSeries.genres),
      tags: _decodeStringArray(dbSeries.tags),
      lastUpdated: dbSeries.lastUpdated ?? '',
      relationships: _decodeJsonObject(dbSeries.relationships),
      source: source,
    );
  }
}

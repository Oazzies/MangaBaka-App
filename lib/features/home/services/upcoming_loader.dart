import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/home/services/home_service.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/models/series_work.dart';

/// Upcoming releases plus what the phone UI needs to dress them: which of
/// them are in the user's library, and a cover for works that have none of
/// their own.
class UpcomingData {
  final List<SeriesWork> works;
  final Set<String> librarySeriesIds;
  final Map<String, String> libraryCovers;

  /// The last page of releases loaded; the API pages from today onward, so
  /// each further page reaches later into the future.
  final int page;

  /// False once a page came back short: nothing further is scheduled.
  final bool hasMore;

  const UpcomingData({
    required this.works,
    required this.librarySeriesIds,
    required this.libraryCovers,
    this.page = 1,
    this.hasMore = false,
  });

  static const empty = UpcomingData(
    works: [],
    librarySeriesIds: {},
    libraryCovers: {},
  );

  /// The API's fixed page size; a shorter page is the last one.
  static const int pageSize = 25;

  /// This data with the next page of releases appended.
  Future<UpcomingData> loadMore(HomeService home) async {
    final next = await home.fetchUpcomingWorks(page: page + 1);
    final known = {for (final w in works) w.id};
    return UpcomingData(
      works: [
        ...works,
        for (final w in next)
          if (!known.contains(w.id)) w,
      ],
      librarySeriesIds: librarySeriesIds,
      libraryCovers: libraryCovers,
      page: page + 1,
      hasMore: next.length >= pageSize,
    );
  }

  bool isInLibrary(SeriesWork work) =>
      work.seriesId != null && librarySeriesIds.contains('${work.seriesId}');

  String? coverFor(SeriesWork work) {
    final own = work.imageUrl;
    if (own != null && own.isNotEmpty) return own;
    return work.seriesId == null ? null : libraryCovers['${work.seriesId}'];
  }

  static Future<UpcomingData> load(HomeService home) async {
    final works = await home.fetchUpcomingWorks(page: 1);
    final hasMore = works.length >= pageSize;

    final ids = <String>{};
    final covers = <String, String>{};
    // Signed out means no library to mark.
    if (!getIt<ProfileAuthService>().isLoggedIn) {
      return UpcomingData(
        works: works,
        librarySeriesIds: ids,
        libraryCovers: covers,
        hasMore: hasMore,
      );
    }
    try {
      final entries = await getIt<LibraryService>().database.libraryEntriesDao
          .watchAllEntriesWithSeries()
          .first;
      for (final e in entries) {
        ids.add(e.series.id);
        if (e.series.coverUrl.isNotEmpty) covers[e.series.id] = e.series.coverUrl;
      }
    } catch (_) {
      // Signed out or no database yet: the list simply has no library marks.
    }
    return UpcomingData(
      works: works,
      librarySeriesIds: ids,
      libraryCovers: covers,
      hasMore: hasMore,
    );
  }

  /// The calendar day of a work's release, or null when it has none.
  static DateTime? dayOf(SeriesWork work) {
    final raw = work.releaseDate;
    if (raw.length < 10) return null;
    final d = DateTime.tryParse(raw.substring(0, 10));
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }
}

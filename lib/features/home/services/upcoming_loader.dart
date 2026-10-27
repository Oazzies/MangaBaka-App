import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/home/services/home_service.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/models/series_work.dart';

/// Upcoming releases plus what the phone UI needs to dress them: which of
/// them are in the user's library, and a cover for works that have none of
/// their own.
///
/// The releases arrive first; the library marks follow ([withLibrary]) and are
/// not there until [libraryReady]. Callers showing a library-only view wait for
/// that rather than presenting a half-known list as the answer.
class UpcomingData {
  final List<SeriesWork> works;
  final Set<String> librarySeriesIds;
  final Map<String, String> libraryCovers;

  /// Whether [librarySeriesIds] has been worked out for every work in [works].
  final bool libraryReady;

  /// The last page of releases loaded; the API pages from today onward, so
  /// each further page reaches later into the future.
  final int page;

  /// False once a page came back short: nothing further is scheduled.
  final bool hasMore;

  const UpcomingData({
    required this.works,
    required this.librarySeriesIds,
    required this.libraryCovers,
    this.libraryReady = true,
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

  /// This data with the next page of releases appended. The new works' library
  /// marks are not known yet: see [withLibrary].
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
      libraryReady: false,
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

  /// The first page of releases, without library marks yet.
  static Future<UpcomingData> load(HomeService home) async {
    final works = await home.fetchUpcomingWorks(page: 1);
    return UpcomingData(
      works: works,
      librarySeriesIds: const {},
      libraryCovers: const {},
      // Signed out means no library to mark.
      libraryReady: !_signedIn,
      hasMore: works.length >= pageSize,
    );
  }

  static bool get _signedIn => getIt<ProfileAuthService>().isLoggedIn;

  /// This data with the library marks filled in for every work. The database is
  /// asked only about these works' series, never for the whole library.
  Future<UpcomingData> withLibrary() async {
    if (libraryReady) return this;
    final ids = {
      for (final w in works)
        if (w.seriesId != null) '${w.seriesId}',
    };
    var covers = const <String, String>{};
    try {
      covers = await getIt<LibraryService>().database.libraryEntriesDao
          .libraryCoversFor(ids);
    } catch (_) {
      // No database yet: the list simply has no library marks.
    }
    return UpcomingData(
      works: works,
      librarySeriesIds: covers.keys.toSet(),
      libraryCovers: {
        for (final e in covers.entries)
          if (e.value.isNotEmpty) e.key: e.value,
      },
      page: page,
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

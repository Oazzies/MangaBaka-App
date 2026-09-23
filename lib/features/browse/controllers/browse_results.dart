import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/features/browse/services/browse_search_gateway.dart';
import 'package:mangabaka_app/features/browse/utils/staff_aggregator.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/staff/models/staff.dart';

/// The pages of browse results accumulated so far, and what is known about
/// how many more there are.
///
/// Split from `BrowseController` so paging arithmetic sits apart from the
/// query, the loading flags and the scroll listener. It holds no notion of
/// *loading* — the controller owns that, along with deciding when a page is
/// stale enough to drop.
class BrowseResults {
  List<Series> _series = [];
  List<Publisher> _publishers = [];
  List<Staff> _staff = [];

  List<Series> get series => _series;
  List<Publisher> get publishers => _publishers;
  List<Staff> get staff => _staff;

  /// The page number to request next. 1 until a page has been taken.
  int _page = 1;
  int get page => _page;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  int _total = 0;
  int get total => _total;

  /// True when [total] is a floor rather than a count — see
  /// [BrowsePage.isTotalCapped].
  bool _isTotalCapped = false;
  bool get isTotalCapped => _isTotalCapped;

  /// The list matching [type], for callers that do not care which it is.
  List<dynamic> forType(BrowseType type) {
    switch (type) {
      case BrowseType.series:
        return _series;
      case BrowseType.publishers:
        return _publishers;
      case BrowseType.staff:
        return _staff;
      default:
        return const [];
    }
  }

  /// How many of [type] are already held — the gateway needs it to work out a
  /// total when the server does not report one.
  int loadedCount(BrowseType type) => forType(type).length;

  void clear() {
    _series = [];
    _publishers = [];
    _staff = [];
    _page = 1;
    _hasMore = true;
    _total = 0;
    _isTotalCapped = false;
  }

  /// Advances to the next page. Call before fetching, so a response can be
  /// matched against the page it was requested for.
  void advancePage() => _page++;

  /// Undoes [advancePage] after the fetch for that page failed, so the retry
  /// requests the same page instead of skipping past it.
  void retreatPage() {
    if (_page > 1) _page--;
  }

  /// Marks the result set exhausted without adding anything — used for a
  /// browse type that has no endpoint behind it yet.
  void markExhausted() => _hasMore = false;

  void addSeries(BrowsePage<Series> page) {
    _series = [..._series, ...page.items];
    _total = page.total;
    _isTotalCapped = page.isTotalCapped;
    _hasMore = page.hasMore;
  }

  void addPublishers(BrowsePage<Publisher> page) {
    _publishers = [..._publishers, ...page.items];
    _total = page.total;
    _hasMore = page.hasMore;
  }

  /// Staff accumulate by identity rather than by appending: the same person
  /// appears on many series, and a later page can reveal that someone
  /// credited as author is also the artist. The total is therefore the number
  /// of distinct people found, not a server-side count.
  void addStaff(BrowsePage<Staff> page) {
    final updated = List<Staff>.from(_staff);
    StaffAggregator.merge(updated, page.items);
    _staff = updated;
    _total = _staff.length;
    _hasMore = page.hasMore;
  }
}

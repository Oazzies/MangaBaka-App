import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/features/browse/services/browse_search_gateway.dart';
import 'package:mangabaka_app/features/browse/utils/staff_aggregator.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/staff/models/staff.dart';

class BrowseResults {
  List<Series> _series = [];
  List<Publisher> _publishers = [];
  List<Staff> _staff = [];

  List<Series> get series => _series;
  List<Publisher> get publishers => _publishers;
  List<Staff> get staff => _staff;

  int _page = 1;
  int get page => _page;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  int _total = 0;
  int get total => _total;

  bool _isTotalCapped = false;
  bool get isTotalCapped => _isTotalCapped;

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

  /// Call before fetching, so a response can be matched to the page it requested.
  void advancePage() => _page++;

  void retreatPage() {
    if (_page > 1) _page--;
  }

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

  /// Merges by person, not appends: later pages add roles, so the total counts distinct people.
  void addStaff(BrowsePage<Staff> page) {
    final updated = List<Staff>.from(_staff);
    StaffAggregator.merge(updated, page.items);
    _staff = updated;
    _total = _staff.length;
    _hasMore = page.hasMore;
  }
}

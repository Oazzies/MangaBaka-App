import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';

/// State for the filter drawer that long-pressing a chip on the series detail
/// screen opens.
///
/// Long-pressing a tag, genre, type, status, staff member, publisher or year
/// starts a filter set and slides the drawer up; long-pressing the same chip
/// again removes it. The screen used to hold all of that inline as seven
/// near-identical `handleXToggle` methods plus two animation controllers —
/// pulled out here so the screen is layout, and this is filter state.
///
/// The animations live here too because they are driven entirely by whether
/// [filters] is null: there is no state in which one is meaningful without the
/// other.
class SeriesFilterDrawerController extends ChangeNotifier {
  static final _logger = LoggingService.logger;

  static const Duration _drawerDuration = Duration(milliseconds: 300);

  /// One full lap of the marching-ants border. Slow enough to read as a
  /// deliberate "filter mode is active" hint rather than motion noise.
  static const Duration _antsDuration = Duration(seconds: 4);

  final SeriesSearchService _searchService;

  /// Drives the drawer's slide and fade. Also gates the marching-ants overlay.
  late final AnimationController drawerAnimation;

  /// Free-running while the drawer is open; its value is the dash phase.
  late final AnimationController marchingAnts;

  late final Animation<Offset> drawerSlide;

  SearchFilters? _filters;

  List<Map<String, dynamic>> _genres = const [];
  List<Map<String, dynamic>> _tags = const [];
  bool _isLoadingMetadata = false;
  bool _disposed = false;

  SeriesFilterDrawerController({
    required TickerProvider vsync,
    SeriesSearchService? searchService,
  }) : _searchService = searchService ?? getIt<SeriesSearchService>() {
    drawerAnimation = AnimationController(
      vsync: vsync,
      duration: _drawerDuration,
    );
    marchingAnts = AnimationController(vsync: vsync, duration: _antsDuration);
    drawerSlide = Tween<Offset>(begin: const Offset(0.0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: drawerAnimation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
  }

  /// The filters being assembled, or null when the drawer is closed.
  SearchFilters? get filters => _filters;

  bool get isOpen => _filters != null;

  List<Map<String, dynamic>> get genres => _genres;
  List<Map<String, dynamic>> get tags => _tags;

  /// True only while the drawer has nothing to render yet — used to show a
  /// spinner instead of an empty filter form.
  bool get isLoadingMetadata =>
      _isLoadingMetadata && _genres.isEmpty && _tags.isEmpty;

  /// The genre and tag vocabularies the drawer's pickers are built from.
  ///
  /// Only the drawer needs these, so the screen defers this until the push
  /// transition has settled rather than paying for it on the first frame. A
  /// failure leaves the pickers empty and is logged: the rest of the drawer
  /// (sort, type, status, year) still works.
  Future<void> loadMetadata() async {
    if (_isLoadingMetadata) return;
    _isLoadingMetadata = true;
    _safeNotify();
    try {
      final results = await Future.wait([
        _searchService.getGenres(),
        _searchService.getTags(),
      ]);
      _genres = results[0];
      _tags = results[1];
    } catch (e) {
      _logger.warning('Failed to load filter metadata in details screen: $e');
    } finally {
      _isLoadingMetadata = false;
      _safeNotify();
    }
  }

  /// Replaces the whole filter set — used by the drawer's own sections, which
  /// hand back a rebuilt [SearchFilters].
  void replaceFilters(SearchFilters filters) {
    _filters = filters;
    _safeNotify();
  }

  /// Closes the drawer, clearing the filters once the slide-out finishes so
  /// the content does not vanish mid-animation.
  void close() {
    marchingAnts.stop();
    drawerAnimation.reverse().then((_) {
      if (_disposed) return;
      _filters = null;
      _safeNotify();
    });
  }

  // ─── Chip toggles ────────────────────────────────────────────────────────
  //
  // Each of these takes a value out of one list-valued filter field, or puts
  // it in. They were seven copies of the same nine lines; [_toggleList] is now
  // the only place that logic lives.

  void toggleTagByName(String tagName) {
    final tagId = resolveTagId(tagName);
    if (tagId == null) return;
    _toggleList(
      read: (f) => f.tag,
      write: (f, values) => f.copyWith(tag: values),
      empty: (values) => SearchFilters(tag: values),
      value: tagId,
    );
  }

  void toggleGenre(String genreKey) => _toggleList(
    read: (f) => f.genre,
    write: (f, values) => f.copyWith(genre: values),
    empty: (values) => SearchFilters(genre: values),
    value: genreKey,
  );

  void toggleType(String typeKey) => _toggleList(
    read: (f) => f.type,
    write: (f, values) => f.copyWith(type: values),
    empty: (values) => SearchFilters(type: values),
    value: typeKey,
  );

  void toggleStatus(String statusKey) => _toggleList(
    read: (f) => f.status,
    write: (f, values) => f.copyWith(status: values),
    empty: (values) => SearchFilters(status: values),
    value: statusKey,
  );

  void toggleStaff(String staffName) => _toggleList(
    read: (f) => f.staff,
    write: (f, values) => f.copyWith(staff: values),
    empty: (values) => SearchFilters(staff: values),
    value: staffName,
  );

  void togglePublisher(String publisherName) => _toggleList(
    read: (f) => f.publisher,
    write: (f, values) => f.copyWith(publisher: values),
    empty: (values) => SearchFilters(publisher: values),
    value: publisherName,
  );

  /// A year filter is a range, so toggling one sets both bounds to that year —
  /// or clears them when that exact year is already selected.
  void toggleYear(int year) {
    HapticFeedback.lightImpact();
    _update((current) {
      if (current == null) {
        return SearchFilters(
          publishedYearLower: year,
          publishedYearUpper: year,
        );
      }
      final isSelected =
          current.publishedYearLower == year &&
          current.publishedYearUpper == year;
      return current.copyWithYear(
        publishedYearLower: isSelected ? null : year,
        publishedYearUpper: isSelected ? null : year,
      );
    });
  }

  void _toggleList({
    required List<String> Function(SearchFilters filters) read,
    required SearchFilters Function(SearchFilters filters, List<String> values)
    write,
    required SearchFilters Function(List<String> values) empty,
    required String value,
  }) {
    HapticFeedback.lightImpact();
    _update((current) {
      if (current == null) return empty([value]);
      final values = List<String>.from(read(current));
      if (!values.remove(value)) values.add(value);
      return write(current, values);
    });
  }

  /// Applies [updateFn] and, when this is the first filter, opens the drawer.
  void _update(SearchFilters Function(SearchFilters? current) updateFn) {
    final wasClosed = _filters == null;
    _filters = updateFn(_filters);
    _safeNotify();
    if (!wasClosed) return;
    drawerAnimation.forward();
    marchingAnts.repeat();
  }

  /// Resolves a tag's display name to the id the search endpoint expects.
  ///
  /// Prefers the drawer's own loaded vocabulary and falls back to
  /// [MetadataService], which is populated from cache at startup and so may
  /// have the answer before [loadMetadata] has finished.
  String? resolveTagId(String name) {
    final lowered = name.toLowerCase();
    for (final tag in _tags) {
      if (tag['name']?.toString().toLowerCase() == lowered) {
        return tag['id']?.toString();
      }
    }
    if (!getIt.isRegistered<MetadataService>()) return null;
    return getIt<MetadataService>().getTagId(name);
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    drawerAnimation.dispose();
    marchingAnts.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';

/// Owns the drawer animations too: they are driven entirely by whether [filters] is null.
class SeriesFilterDrawerController extends ChangeNotifier {
  static final _logger = LoggingService.logger;

  static const Duration _drawerDuration = Duration(milliseconds: 300);

  static const Duration _antsDuration = Duration(seconds: 4);

  final SeriesSearchService _searchService;

  late final AnimationController drawerAnimation;

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

  SearchFilters? get filters => _filters;

  bool get isOpen => _filters != null;

  List<Map<String, dynamic>> get genres => _genres;
  List<Map<String, dynamic>> get tags => _tags;

  bool get isLoadingMetadata =>
      _isLoadingMetadata && _genres.isEmpty && _tags.isEmpty;

  /// A failure only empties the genre and tag pickers; sort, type, status and year still work.
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

  void replaceFilters(SearchFilters filters) {
    _filters = filters;
    _safeNotify();
  }

  /// Clears [filters] only after the slide-out, or the content vanishes mid-animation.
  void close() {
    marchingAnts.stop();
    drawerAnimation.reverse().then((_) {
      if (_disposed) return;
      _filters = null;
      _safeNotify();
    });
  }

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

  void _update(SearchFilters Function(SearchFilters? current) updateFn) {
    final wasClosed = _filters == null;
    _filters = updateFn(_filters);
    _safeNotify();
    if (!wasClosed) return;
    drawerAnimation.forward();
    marchingAnts.repeat();
  }

  /// Falls back to [MetadataService], cache-populated at startup, while [loadMetadata] is still running.
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

import 'package:flutter/foundation.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/collections/models/edition.dart';
import 'package:mangabaka_app/features/collections/services/collection_service.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';

/// The Collections and Editions tabs of a publisher page: one publisher's
/// collections, paged in as the list is scrolled, the shared list of editions,
/// and the edition (if any) the collections are narrowed to.
///
/// Both lists load on first use rather than with the page, so a visitor who
/// only reads the Info tab never pays for them.
class PublisherCollectionsController extends ChangeNotifier {
  static final _logger = LoggingService.logger;

  final String publisherId;
  final CollectionService? _injected;

  /// Resolved on first use, so a page that never opens these tabs never
  /// touches the service.
  CollectionService get _service => _injected ?? getIt<CollectionService>();

  PublisherCollectionsController(this.publisherId, {CollectionService? service})
      : _injected = service;

  final List<SeriesCollection> _items = [];
  int _page = 1;
  bool _hasNext = false;
  bool _loading = false;
  bool _failed = false;
  bool _started = false;
  bool _loadedOnce = false;

  List<Edition>? _editions;
  bool _editionsFailed = false;
  bool _editionsStarted = false;

  String? _editionFilter;
  bool _disposed = false;

  /// Every collection loaded so far, narrowed to [editionFilter] if set.
  List<SeriesCollection> get collections => _editionFilter == null
      ? List.unmodifiable(_items)
      : _items.where((c) => c.editionName == _editionFilter).toList();

  /// Edition names present in what has loaded, for the filter pills.
  List<String> get editionNames => {
        for (final c in _items)
          if (c.editionName.isNotEmpty) c.editionName,
      }.toList()
        ..sort();

  bool get hasNext => _hasNext;
  bool get loading => _loading;
  bool get failed => _failed;
  bool get started => _started;
  String? get editionFilter => _editionFilter;

  List<Edition>? get editions => _editions;
  bool get editionsFailed => _editionsFailed;

  void setEditionFilter(String? name) {
    if (_editionFilter == name) return;
    _editionFilter = name;
    notifyListeners();
  }

  /// Loads the first page of collections, once.
  void ensureCollections() {
    if (_started) return;
    _started = true;
    loadMore();
  }

  /// Loads the editions list, once (or again after a failure).
  Future<void> ensureEditions() async {
    if (_editionsStarted && !_editionsFailed) return;
    _editionsStarted = true;
    _editionsFailed = false;
    notifyListeners();
    try {
      final editions = await _service.fetchEditions();
      if (_disposed) return;
      _editions = editions;
    } catch (e) {
      _logger.warning('Editions failed: $e');
      if (_disposed) return;
      _editionsFailed = true;
    }
    notifyListeners();
  }

  /// Fetches the next page; a no-op while one is in flight or after the last.
  Future<void> loadMore() async {
    if (_loading || (_loadedOnce && !_hasNext)) return;
    _started = true;
    _loading = true;
    _failed = false;
    notifyListeners();
    try {
      final page = await _service.fetchPublisherCollections(
        publisherId,
        page: _page,
      );
      if (_disposed) return;
      _items.addAll(page.items);
      _hasNext = page.hasNext;
      _loadedOnce = true;
      _page++;
    } catch (e) {
      _logger.warning('Publisher collections failed: $e');
      if (_disposed) return;
      _failed = true;
    }
    _loading = false;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

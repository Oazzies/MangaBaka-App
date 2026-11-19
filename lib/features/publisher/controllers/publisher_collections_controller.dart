import 'package:flutter/foundation.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/collections/models/edition.dart';
import 'package:mangabaka_app/features/collections/services/collection_service.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';

/// Both lists load on first use, so a visitor who only reads the Info tab never pays for them.
class PublisherCollectionsController extends ChangeNotifier {
  static final _logger = LoggingService.logger;

  final String publisherId;
  final CollectionService? _injected;

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

  List<SeriesCollection> get collections => _editionFilter == null
      ? List.unmodifiable(_items)
      : _items.where((c) => c.editionName == _editionFilter).toList();

  List<String> get editionNames => {
    for (final c in _items)
      if (c.editionName.isNotEmpty) c.editionName,
  }.toList()..sort();

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

  void ensureCollections() {
    if (_started) return;
    _started = true;
    loadMore();
  }

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

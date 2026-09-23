import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/browse/controllers/browse_results.dart';
import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/services/barcode_search.dart';
import 'package:mangabaka_app/features/browse/services/browse_search_gateway.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/staff/models/staff.dart';

/// Drives the Browse screen: the query, the filters, the active result type,
/// and the loading lifecycle.
///
/// Fetching belongs to [BrowseSearchGateway] and the accumulated pages to
/// [BrowseResults]; what stays here is the state binding them together — what
/// is being searched for, whether a request is in flight, and the generation
/// guard that keeps a slow response from an abandoned search out of the
/// current results.
class BrowseController extends ChangeNotifier {
  static final _logger = LoggingService.logger;

  /// Scroll offset past which the back-to-top button appears.
  static const double _backToTopOffset = 500;

  final BrowseSearchGateway _gateway;
  final BarcodeSearch _barcode;
  final BrowseResults _results = BrowseResults();

  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  BrowseController({
    BrowseSearchGateway? gateway,
    BarcodeSearch? barcodeSearch,
  })  : _gateway = gateway ?? BrowseSearchGateway(),
        _barcode = barcodeSearch ?? BarcodeSearch() {
    scrollController.addListener(_onScroll);
  }

  BrowseType _currentType = BrowseType.series;
  BrowseType get currentType => _currentType;

  List<Series> get seriesResults => _results.series;
  List<Publisher> get publisherResults => _results.publishers;
  List<Staff> get staffResults => _results.staff;

  /// The results for whichever type is active, for callers that do not care
  /// which it is.
  List<dynamic> get searchResults => _results.forType(_currentType);

  int get totalResults => _results.total;
  bool get isTotalCapped => _results.isTotalCapped;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _error;
  String? get error => _error;

  String _currentSearchQuery = '';
  String get currentSearchQuery => _currentSearchQuery;

  SearchFilters _currentFilters = SearchFilters();
  SearchFilters get currentFilters => _currentFilters;

  /// Incremented whenever the search context changes (new query, reset, tab
  /// switch). In-flight responses compare their captured generation against
  /// this before touching state, so a slow page from an old search can never
  /// be appended to the results of a newer one.
  int _requestGeneration = 0;

  bool get isSearchMode =>
      _currentSearchQuery.trim().isNotEmpty ||
      !_currentFilters.isEmpty ||
      _isLoading ||
      _error != null ||
      searchResults.isNotEmpty;

  bool _showBackToTop = false;
  bool get showBackToTop => _showBackToTop;

  bool get _hasSearchContext =>
      _currentSearchQuery.isNotEmpty || _currentFilters.toMap().isNotEmpty;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    // Marks every in-flight page stale, so none of them touches state (or
    // calls notifyListeners) after disposal.
    _requestGeneration++;
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // ─── Scrolling ───────────────────────────────────────────────────────────

  void _onScroll() {
    // Two attached positions means the list is mid-rebuild between routes;
    // reading `position` would throw.
    if (!scrollController.hasClients ||
        scrollController.positions.length != 1) {
      return;
    }

    final isNearEnd = scrollController.position.pixels >=
        scrollController.position.maxScrollExtent -
            AppConstants.scrollThresholdPx;

    if (isNearEnd && _results.hasMore && !_isLoadingMore && _hasSearchContext) {
      _logger.fine(
        'Near end of scroll, loading more results for query: '
        '"$_currentSearchQuery"',
      );
      loadMoreResults();
    }

    final showBackToTop = scrollController.offset > _backToTopOffset;
    if (showBackToTop == _showBackToTop) return;
    _showBackToTop = showBackToTop;
    notifyListeners();
  }

  void checkScroll() => _onScroll();

  void scrollToTop() {
    scrollController.animateTo(
      0,
      duration: AppConstants.mediumAnimationDuration,
      curve: Curves.easeInOut,
    );
  }

  // ─── Search context ──────────────────────────────────────────────────────

  void resetSearchState() {
    _logger.fine('Resetting search state');
    _requestGeneration++;
    _results.clear();
    _error = null;
    _currentSearchQuery = '';
    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  void setType(BrowseType type) {
    if (_currentType == type) return;
    _logger.info('Switching browse type to: $type');
    _currentType = type;
    // Carry an active search across the tab switch rather than dropping it.
    if (_hasSearchContext) {
      searchSeries();
    } else {
      resetSearchState();
    }
  }

  void updateSearchQuery(String text) {
    _currentSearchQuery = text;
    if (text.isEmpty && _currentFilters.toMap().isEmpty) resetSearchState();
  }

  void updateFilters(SearchFilters filters) {
    _logger.info('Filters updated: ${filters.toMap()}');
    _currentFilters = filters;
    // Filters only apply to series; the Publishers and Staff tabs are hidden
    // while any are set, so an active one has to fall back.
    if (!filters.isEmpty &&
        (_currentType == BrowseType.publishers ||
            _currentType == BrowseType.staff)) {
      _currentType = BrowseType.series;
    }
    searchSeries();
  }

  void startTagSearch(List<String> tagIds) {
    _logger.info('Starting tag search with tag IDs: $tagIds');
    _startFilteredSearch(SearchFilters(tag: tagIds));
  }

  void startGenreSearch(String genre) {
    _logger.info('Starting genre search with genre: $genre');
    _startFilteredSearch(SearchFilters(genre: [genre]));
  }

  void startSearchWithFilters(SearchFilters filters) {
    _logger.info('Starting search with filters: ${filters.toMap()}');
    _startFilteredSearch(filters);
  }

  /// Replaces the whole search context with [filters] and runs it. The text
  /// query is cleared: these entry points come from tapping a chip elsewhere
  /// in the app, where a leftover query would silently narrow the results.
  void _startFilteredSearch(SearchFilters filters) {
    searchController.clear();
    _currentSearchQuery = '';
    _currentType = BrowseType.series;
    _currentFilters = filters;
    searchSeries();
  }

  // ─── Fetching ────────────────────────────────────────────────────────────

  Future<void> searchSeries() async {
    if (_currentSearchQuery.trim().isEmpty &&
        _currentFilters.toMap().isEmpty) {
      _logger.fine('Search query and filters are empty, skipping search');
      resetSearchState();
      return;
    }

    _logger.info(
      'Starting new search for $_currentType with query: '
      '"$_currentSearchQuery" with filters: ${_currentFilters.toMap()}',
    );
    _requestGeneration++;
    _isLoading = true;
    _isLoadingMore = false;
    _error = null;
    _results.clear();
    notifyListeners();

    await _fetchPage();
  }

  Future<void> loadMoreResults() async {
    // _isLoading guards against the initial page still being in flight: an
    // empty list has maxScrollExtent 0, which counts as "near end", so the
    // scroll listener could otherwise fire page 2 concurrently with page 1.
    if (_isLoading || _isLoadingMore || !_results.hasMore) return;

    _logger.info(
      'Loading more results for query: "$_currentSearchQuery", '
      'page: ${_results.page + 1}',
    );
    _isLoadingMore = true;
    notifyListeners();

    _results.advancePage();
    await _fetchPage(isLoadMore: true);
  }

  Future<void> _fetchPage({bool isLoadMore = false}) async {
    final generation = _requestGeneration;
    try {
      switch (_currentType) {
        case BrowseType.series:
          final page = await _gateway.fetchSeries(
            query: _currentSearchQuery,
            page: _results.page,
            filters: _currentFilters,
            alreadyLoaded: _results.loadedCount(BrowseType.series),
          );
          if (_isStale(generation, 'series')) return;
          _results.addSeries(page);

        case BrowseType.publishers:
          final page = await _gateway.fetchPublishers(
            query: _currentSearchQuery,
            page: _results.page,
            filters: _currentFilters,
            alreadyLoaded: _results.loadedCount(BrowseType.publishers),
          );
          if (_isStale(generation, 'publisher')) return;
          _results.addPublishers(page);

        case BrowseType.staff:
          final page = await _gateway.fetchStaff(
            query: _currentSearchQuery,
            page: _results.page,
            filters: _currentFilters,
          );
          if (_isStale(generation, 'staff')) return;
          _results.addStaff(page);

        default:
          // A type with no backing endpoint yet: settle into an empty,
          // non-loading state rather than spinning forever.
          _results.markExhausted();
      }
      _finishPage();
    } catch (e) {
      if (generation != _requestGeneration) return;
      _logger.severe(
        'Failed to fetch search results for type $_currentType, query '
        '"$_currentSearchQuery" at page ${_results.page}: $e',
      );
      // The page was advanced before the request; without stepping back, the
      // next scroll-triggered retry would request the page after it and the
      // failed page's results would be silently missing from the list.
      if (isLoadMore) _results.retreatPage();
      _isLoading = false;
      _isLoadingMore = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  bool _isStale(int generation, String label) {
    if (generation == _requestGeneration) return false;
    _logger.fine('Discarding stale $label results for superseded search');
    return true;
  }

  void _finishPage() {
    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
    // A short page may not fill the viewport, leaving nothing to scroll and so
    // no way to ask for the next one; re-check once it has been laid out.
    if (!_results.hasMore) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) checkScroll();
    });
  }

  // ─── Barcode ─────────────────────────────────────────────────────────────

  static double generateRandomSeed() => Random().nextDouble();

  /// Looks a scanned ISBN up and searches for the title it resolves to.
  ///
  /// Returns null on success, or a localisation key naming what went wrong —
  /// the caller shows it, since only the UI knows how.
  Future<String?> handleBarcodeScan(String isbn) async {
    if (isbn.isEmpty) return null;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final failure = await _barcode.run(isbn, search: _searchFor);
    if (failure == null) return null;

    // A search that ran and found nothing has already settled the flags; a
    // lookup that never got that far has not.
    if (_isLoading) {
      _isLoading = false;
      notifyListeners();
    }
    return failure.messageKey;
  }

  /// Runs [title] as a search, returning whether it matched anything.
  Future<bool> _searchFor(String title) async {
    searchController.text = title;
    _currentSearchQuery = title;
    await searchSeries();
    return _results.series.isNotEmpty;
  }
}

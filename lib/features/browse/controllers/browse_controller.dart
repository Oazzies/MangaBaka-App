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
import 'package:mangabaka_app/core/exceptions/error_messages.dart';

part 'browse_fetch_part.dart';

class BrowseController extends ChangeNotifier {
  static final _logger = LoggingService.logger;

  static const double _backToTopOffset = 500;

  final BrowseSearchGateway _gateway;
  final BarcodeSearch _barcode;
  final BrowseResults _results = BrowseResults();

  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  BrowseController({BrowseSearchGateway? gateway, BarcodeSearch? barcodeSearch})
    : _gateway = gateway ?? BrowseSearchGateway(),
      _barcode = barcodeSearch ?? BarcodeSearch() {
    scrollController.addListener(_onScroll);
  }

  BrowseType _currentType = BrowseType.series;
  BrowseType get currentType => _currentType;

  List<Series> get seriesResults => _results.series;
  List<Publisher> get publisherResults => _results.publishers;
  List<Staff> get staffResults => _results.staff;

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

  /// Bumped on every context change; an in-flight page from an older generation is dropped.
  int _requestGeneration = 0;

  bool get isSearchMode =>
      _currentSearchQuery.trim().isNotEmpty ||
      !_currentFilters.isEmpty ||
      _isLoading ||
      _error != null ||
      searchResults.isNotEmpty;

  bool _showBackToTop = false;
  bool get showBackToTop => _showBackToTop;

  /// Publishers are browsable without a query, so that tab always has a search context.
  bool get _hasSearchContext =>
      _currentType == BrowseType.publishers ||
      _currentSearchQuery.isNotEmpty ||
      _currentFilters.toMap().isNotEmpty;

  /// A `PublisherSearchService` sort; null is relevance when searching, most series when browsing.
  String? _publisherSort;
  String? get publisherSort => _publisherSort;

  void setPublisherSort(String? sort) {
    if (_publisherSort == sort) return;
    _publisherSort = sort;
    if (_currentType == BrowseType.publishers) searchSeries();
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    // Stales in-flight pages so none touches state or notifies after disposal.
    _requestGeneration++;
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Two attached positions means a mid-route rebuild; reading `position` would throw.
    if (!scrollController.hasClients ||
        scrollController.positions.length != 1) {
      return;
    }

    final isNearEnd =
        scrollController.position.pixels >=
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
    if (_hasSearchContext) {
      // The other tab's results cannot stand in for this tab's while it loads.
      _results.clear();
      searchSeries();
    } else {
      resetSearchState();
    }
  }

  void updateSearchQuery(String text) {
    _currentSearchQuery = text;
    if (text.isEmpty && _currentFilters.toMap().isEmpty) {
      _currentType == BrowseType.publishers
          ? searchSeries()
          : resetSearchState();
    }
  }

  void updateFilters(SearchFilters filters) {
    _logger.info('Filters updated: ${filters.toMap()}');
    _currentFilters = filters;
    // Publishers and Staff tabs are disabled while filters are set, so an active one falls back.
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

  void startQuerySearch(String query, SearchFilters filters) {
    searchController.text = query;
    _currentSearchQuery = query;
    _currentType = BrowseType.series;
    _currentFilters = filters;
    searchSeries();
  }

  /// Clears the query: these come from chip taps, where a leftover query would narrow results.
  void _startFilteredSearch(SearchFilters filters) {
    searchController.clear();
    _currentSearchQuery = '';
    _currentType = BrowseType.series;
    _currentFilters = filters;
    searchSeries();
  }

  void _notify() => notifyListeners();

  Future<void> searchSeries() => _searchSeriesImpl(this);

  Future<void> loadMoreResults() => _loadMoreResultsImpl(this);

  static double generateRandomSeed() => Random().nextDouble();

  /// Returns null on success, or the localisation key of the error for the UI to show.
  Future<String?> handleBarcodeScan(String isbn) =>
      _handleBarcodeScanImpl(this, isbn);
}

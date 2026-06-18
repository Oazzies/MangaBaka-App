import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/browse/services/book_lookup_service.dart';
import 'package:mangabaka_app/features/browse/utils/browse_helpers.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:mangabaka_app/features/staff/models/staff.dart';

class BrowseController extends ChangeNotifier {
  static final _logger = LoggingService.logger;
  final SeriesSearchService _searchService = getIt<SeriesSearchService>();
  final PublisherSearchService _publisherSearchService =
      getIt<PublisherSearchService>();
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  BrowseType _currentType = BrowseType.series;
  BrowseType get currentType => _currentType;

  List<Series> _seriesResults = [];
  List<Series> get seriesResults => _seriesResults;

  List<Publisher> _publisherResults = [];
  List<Publisher> get publisherResults => _publisherResults;

  List<Staff> _staffResults = [];
  List<Staff> get staffResults => _staffResults;

  // For backward compatibility or general access
  List<dynamic> get searchResults {
    switch (_currentType) {
      case BrowseType.series:
        return _seriesResults;
      case BrowseType.publishers:
        return _publisherResults;
      case BrowseType.staff:
        return _staffResults;
      default:
        return [];
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _error;
  String? get error => _error;

  String _currentSearchQuery = '';
  String get currentSearchQuery => _currentSearchQuery;

  int _currentPage = 1;
  bool _hasMore = true;
  int _totalResults = 0;
  int get totalResults => _totalResults;
  bool _isTotalCapped = false;
  bool get isTotalCapped => _isTotalCapped;

  SearchFilters _currentFilters = SearchFilters();
  SearchFilters get currentFilters => _currentFilters;

  bool get isSearchMode =>
      _currentSearchQuery.trim().isNotEmpty ||
      !_currentFilters.isEmpty ||
      _isLoading ||
      _error != null ||
      searchResults.isNotEmpty;

  bool _showBackToTop = false;
  bool get showBackToTop => _showBackToTop;

  BrowseController() {
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!scrollController.hasClients || scrollController.positions.length != 1) return;

    final isNearEnd =
        scrollController.position.pixels >=
        scrollController.position.maxScrollExtent -
            AppConstants.scrollThresholdPx;

    if (isNearEnd &&
        _hasMore &&
        !_isLoadingMore &&
        (_currentSearchQuery.isNotEmpty ||
            _currentFilters.toMap().isNotEmpty)) {
      _logger.fine(
        'Near end of scroll, loading more results for query: "$_currentSearchQuery"',
      );
      loadMoreResults();
    }

    final showBackToTop = scrollController.offset > 500;
    if (showBackToTop != _showBackToTop) {
      _showBackToTop = showBackToTop;
      notifyListeners();
    }
  }

  void checkScroll() {
    _onScroll();
  }

  void resetSearchState() {
    _logger.fine('Resetting search state');
    _seriesResults = [];
    _publisherResults = [];
    _staffResults = [];
    _error = null;
    _currentSearchQuery = '';
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;
    _totalResults = 0;
    _isTotalCapped = false;
    notifyListeners();
  }

  void setType(BrowseType type) {
    if (_currentType == type) return;
    _logger.info('Switching browse type to: $type');
    _currentType = type;
    // When switching, we might want to re-trigger search if there's a query
    if (_currentSearchQuery.isNotEmpty || _currentFilters.toMap().isNotEmpty) {
      searchSeries();
    } else {
      resetSearchState();
    }
  }

  void updateSearchQuery(String text) {
    _currentSearchQuery = text;
    if (text.isEmpty && _currentFilters.toMap().isEmpty) {
      resetSearchState();
    }
  }

  void updateFilters(SearchFilters filters) {
    _logger.info('Filters updated: ${filters.toMap()}');
    _currentFilters = filters;
    searchSeries();
  }

  void startTagSearch(List<String> tagIds) {
    _logger.info('Starting tag search with tag IDs: $tagIds');
    searchController.clear();
    _currentSearchQuery = '';
    _currentType = BrowseType.series;
    _currentFilters = SearchFilters(tag: tagIds);
    searchSeries();
  }

  void startGenreSearch(String genre) {
    _logger.info('Starting genre search with genre: $genre');
    searchController.clear();
    _currentSearchQuery = '';
    _currentType = BrowseType.series;
    _currentFilters = SearchFilters(genre: [genre]);
    searchSeries();
  }

  void startSearchWithFilters(SearchFilters filters) {
    _logger.info('Starting search with filters: ${filters.toMap()}');
    searchController.clear();
    _currentSearchQuery = '';
    _currentType = BrowseType.series;
    _currentFilters = filters;
    searchSeries();
  }

  Future<void> searchSeries() async {
    if (_currentSearchQuery.trim().isEmpty && _currentFilters.toMap().isEmpty) {
      _logger.fine('Search query and filters are empty, skipping search');
      resetSearchState();
      return;
    }

    _logger.info(
      'Starting new search for $_currentType with query: "$_currentSearchQuery" with filters: ${_currentFilters.toMap()}',
    );
    _isLoading = true;
    _error = null;
    _seriesResults = [];
    _publisherResults = [];
    _staffResults = [];
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;
    _totalResults = 0;
    _isTotalCapped = false;
    notifyListeners();

    await _fetchSearchResults();
  }

  Future<void> loadMoreResults() async {
    if (_isLoadingMore || !_hasMore) return;

    _logger.info(
      'Loading more results for query: "$_currentSearchQuery", page: ${_currentPage + 1}',
    );
    _isLoadingMore = true;
    notifyListeners();

    _currentPage++;
    await _fetchSearchResults();
  }

  Future<void> _fetchSearchResults() async {
    try {
      if (_currentType == BrowseType.series) {
        await _fetchSeriesResults();
      } else if (_currentType == BrowseType.publishers) {
        await _fetchPublisherResults();
      } else if (_currentType == BrowseType.staff) {
        await _fetchStaffResults();
      } else {
        // Not implemented yet
        _hasMore = false;
        _isLoading = false;
        _isLoadingMore = false;
        notifyListeners();
      }
    } catch (e) {
      _logger.severe(
        'Failed to fetch search results for type $_currentType, query "$_currentSearchQuery" at page $_currentPage: $e',
      );
      _isLoading = false;
      _isLoadingMore = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// After a page loads, schedules a scroll check so the list auto-loads the
  /// next page if the content is short enough to fit on screen.
  void _scheduleScrollCheckIfNeeded() {
    if (_hasMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) => checkScroll());
    }
  }

  /// Resolves the current user ID when the "hide library series" setting is on.
  String? _getExcludeUserId() {
    if (!SettingsManager().hideLibrarySeriesInBrowse) return null;
    final auth = getIt<ProfileAuthService>();
    if (!auth.isLoggedIn) return null;
    final profile = auth.cachedProfile;
    if (profile == null) return null;
    final userId = profile.id.replaceAll('-', '');
    _logger.fine('Hiding library series for user: $userId');
    return userId.isEmpty ? null : userId;
  }

  Future<void> _fetchSeriesResults() async {
    final userId = _getExcludeUserId();

    final requestParams = <String, dynamic>{
      'page': _currentPage,
      'limit': AppConstants.defaultPageLimit,
      ..._currentFilters.toMap(),
      if (userId != null) 'exclude_user_library': userId,
    };

    final result = await _searchService.searchSeries(
      _currentSearchQuery,
      sortBy: _currentFilters.sortBy,
      type: _currentFilters.type.isNotEmpty ? _currentFilters.type.first : null,
      extraParams: requestParams,
    );

    final newResults = result.series;

    // API sometimes returns 0 even with data; fall back to a calculated total.
    if (result.total > 0) {
      _totalResults = result.total;
      _isTotalCapped = false;
    } else if (newResults.length < AppConstants.defaultPageLimit) {
      _totalResults = _seriesResults.length + newResults.length;
      _isTotalCapped = false;
    } else {
      _totalResults = 1000;
      _isTotalCapped = true;
    }

    _logger.info(
      'Fetched ${newResults.length} series results for page $_currentPage (Total: $_totalResults)',
    );

    // HYBRID SORT: When a query and a custom sort are both active, the API
    // may prioritise relevance over the requested sort order. We apply the
    // sort locally on each page so the user's chosen order is always honoured.
    if (_currentSearchQuery.isNotEmpty && _currentFilters.sortBy != null) {
      final sortBy = _currentFilters.sortBy!;
      _logger.fine('Applying local sort for query "$_currentSearchQuery": $sortBy');
      newResults.sort((a, b) {
        if (sortBy.startsWith('score_')) {
          final rA = double.tryParse(a.rating) ?? 0.0;
          final rB = double.tryParse(b.rating) ?? 0.0;
          return sortBy == 'score_desc' ? rB.compareTo(rA) : rA.compareTo(rB);
        } else if (sortBy.startsWith('name_')) {
          return sortBy == 'name_desc'
              ? b.title.compareTo(a.title)
              : a.title.compareTo(b.title);
        } else if (sortBy.startsWith('chapters_')) {
          final cA = int.tryParse(a.totalChapters) ?? 0;
          final cB = int.tryParse(b.totalChapters) ?? 0;
          return sortBy == 'chapters_desc' ? cB.compareTo(cA) : cA.compareTo(cB);
        }
        // popularity_ and others: keep API order (no reliable local field)
        return 0;
      });
    }

    _hasMore = newResults.length == AppConstants.defaultPageLimit;
    _isLoading = false;
    _isLoadingMore = false;
    _seriesResults.addAll(newResults);
    notifyListeners();
    _scheduleScrollCheckIfNeeded();
  }

  Future<void> _fetchPublisherResults() async {
    final result = await _publisherSearchService.search({
      'q': _currentSearchQuery,
      'page': _currentPage,
      'limit': AppConstants.defaultPageLimit,
      ..._currentFilters.toMap(),
    });

    final newResults = result.publishers;
    _totalResults = result.total > 0
        ? result.total
        : _publisherResults.length + newResults.length;

    _logger.info(
      'Fetched ${newResults.length} publisher results for page $_currentPage (Total: $_totalResults)',
    );

    _hasMore = newResults.length == AppConstants.defaultPageLimit;
    _isLoading = false;
    _isLoadingMore = false;
    _publisherResults.addAll(newResults);
    notifyListeners();
    _scheduleScrollCheckIfNeeded();
  }

  Future<void> _fetchStaffResults() async {
    final newSeriesResults = await _searchService.searchSeriesByName(
      '',
      extraParams: {
        'staff': _currentSearchQuery,
        'page': _currentPage,
        'limit': AppConstants.defaultPageLimit,
        ..._currentFilters.toMap(),
      },
    );

    // Deduplicate staff across all series on this page.
    // If the same person appears as both author and artist, their role is
    // promoted to 'Author / Artist'.
    final staffMap = <String, Staff>{};
    final queryLower = _currentSearchQuery.toLowerCase();

    void upsertStaff(String name, String initialRole) {
      if (queryLower.isNotEmpty && !name.toLowerCase().contains(queryLower)) {
        return;
      }
      final existing = staffMap[name];
      final resolvedRole = existing == null
          ? initialRole
          : (existing.role == initialRole ? existing.role : 'Author / Artist');
      staffMap[name] = Staff(
        id: existing?.id ?? name.hashCode,
        name: name,
        role: resolvedRole,
        seriesCount: null,
      );
    }

    for (final series in newSeriesResults) {
      for (final author in series.authors) { upsertStaff(author, 'Author'); }
      for (final artist in series.artists) { upsertStaff(artist, 'Artist'); }
    }

    final newResults = staffMap.values.toList()
      ..sort((a, b) => (b.seriesCount ?? 0).compareTo(a.seriesCount ?? 0));

    _logger.info(
      'Fetched ${newResults.length} staff results extracted from ${newSeriesResults.length} series for page $_currentPage',
    );

    _hasMore = newSeriesResults.length == AppConstants.defaultPageLimit;
    _isLoading = false;
    _isLoadingMore = false;

    // Merge with results from previous pages, promoting role when needed.
    for (final staff in newResults) {
      final index = _staffResults.indexWhere((s) => s.name == staff.name);
      if (index != -1) {
        final existing = _staffResults[index];
        if (existing.role != staff.role) {
          _staffResults[index] = Staff(
            id: existing.id,
            name: existing.name,
            role: 'Author / Artist',
            seriesCount: null,
          );
        }
      } else {
        _staffResults.add(staff);
      }
    }

    _totalResults = _staffResults.length;
    notifyListeners();
    _scheduleScrollCheckIfNeeded();
  }

  static double generateRandomSeed() {
    return Random().nextDouble();
  }

  Future<String?> handleBarcodeScan(String isbn) async {
    if (isbn.isEmpty) return null;

    _logger.info('Handling barcode scan for ISBN: $isbn');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final lookupService = BookLookupService();
      final title = await lookupService.lookupTitleByIsbn(isbn);

      if (title != null && title.isNotEmpty) {
        _logger.info('Found title from ISBN: $title');
        searchController.text = title;
        _currentSearchQuery = title;
        await searchSeries();

        if (_seriesResults.isNotEmpty) {
          _logger.info('Successfully found series for ISBN title: $title');
          return null;
        } else {
          final cleanedTitle = BrowseHelpers.cleanTitle(title);
          if (cleanedTitle != title && cleanedTitle.isNotEmpty) {
            _logger.info(
              'No results for raw title, trying cleaned title: $cleanedTitle',
            );
            searchController.text = cleanedTitle;
            _currentSearchQuery = cleanedTitle;
            await searchSeries();
            if (_seriesResults.isNotEmpty) {
              return null;
            }
          }
          _logger.warning(
            'No series found for title associated with ISBN: $isbn (Title: $title)',
          );
          return 'no_series_found_for';
        }
      } else {
        _logger.warning('No title found for ISBN: $isbn');
        _isLoading = false;
        notifyListeners();
        return 'barcode_not_found';
      }
    } catch (e) {
      _logger.severe('Error handling barcode scan for ISBN $isbn: $e');
      _isLoading = false;
      notifyListeners();
      return 'barcode_lookup_failed';
    }
  }

  void scrollToTop() {
    scrollController.animateTo(
      0,
      duration: AppConstants.mediumAnimationDuration,
      curve: Curves.easeInOut,
    );
  }
}

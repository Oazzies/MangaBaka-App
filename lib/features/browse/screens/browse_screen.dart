import 'package:flutter/material.dart';
import 'dart:math';
import 'package:bakahyou/features/browse/widgets/mb_search_bar.dart';
import 'package:bakahyou/features/browse/widgets/browse_content.dart';
import 'package:bakahyou/features/series/services/series_search_service.dart';
import 'package:bakahyou/features/series/screens/series_detail_screen.dart';
import 'package:bakahyou/features/browse/screens/browse_results_screen.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/browse/models/search_filters.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/di/service_locator.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  // Services & Controllers
  late final SeriesSearchService _searchService;
  late final ScrollController _scrollController;

  // Search State
  List<Series> _searchResults = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _currentSearchQuery = '';
  int _currentPage = 1;
  bool _hasMore = true;
  SearchFilters _currentFilters = SearchFilters();

  @override
  void initState() {
    super.initState();
    _searchService = getIt<SeriesSearchService>();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _resetSearchState() {
    setState(() {
      _searchResults = [];
      _error = null;
      _currentSearchQuery = '';
      _currentPage = 1;
      _hasMore = true;
      _isLoadingMore = false;
    });
  }

  void _onScroll() {
    final isNearEnd =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent -
            AppConstants.scrollThresholdPx;

    if (isNearEnd &&
        _hasMore &&
        !_isLoadingMore &&
        (_currentSearchQuery.isNotEmpty ||
            _currentFilters.toMap().isNotEmpty)) {
      _loadMoreResults();
    }
  }

  Future<void> _searchSeries() async {
    // If there is no query and no filters, reset
    if (_currentSearchQuery.trim().isEmpty && _currentFilters.toMap().isEmpty) {
      _resetSearchState();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _searchResults = [];
      _currentPage = 1;
      _hasMore = true;
      _isLoadingMore = false;
    });

    await _fetchSearchResults();
  }

  Future<void> _loadMoreResults() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });
    _currentPage++;
    await _fetchSearchResults();
  }

  Future<void> _fetchSearchResults() async {
    try {
      final extraParams = {
        'page': _currentPage,
        'limit': AppConstants.defaultPageLimit,
        ..._currentFilters.toMap(),
      };

      final newResults = await _searchService.searchSeriesByName(
        _currentSearchQuery,
        extraParams: extraParams,
      );

      setState(() {
        _hasMore = newResults.length == AppConstants.defaultPageLimit;
        _isLoading = false;
        _isLoadingMore = false;
        _searchResults.addAll(newResults);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = e.toString();
      });
    }
  }

  num _generateRandomSeed() {
    return Random().nextDouble() * 2 - 1;
  }

  void _navigateToBrowseResults(String header, String sortBy, {String? type}) {
    num? randomSeed;
    if (sortBy == 'random') {
      randomSeed = _generateRandomSeed();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BrowseResultsScreen(
          sortType: header,
          sortBy: sortBy,
          type: type,
          randomSeed: randomSeed,
        ),
      ),
    );
  }

  void _navigateToDetail(Series series) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SeriesDetailScreen(series: series)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppConstants.horizontalPadding,
            right: AppConstants.horizontalPadding,
            top: AppConstants.verticalPadding,
            bottom: 8.0,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: MBSearchBar(
                  initialFilters: _currentFilters,
                  onChanged: (text) {
                    _currentSearchQuery = text;
                    if (text.isEmpty && _currentFilters.toMap().isEmpty) {
                      _resetSearchState();
                    }
                  },
                  onSubmitted: (text) {
                    _currentSearchQuery = text;
                    _searchSeries();
                  },
                  onFilterApplied: (filters) {
                    setState(() {
                      _currentFilters = filters;
                    });
                    _searchSeries();
                  },
                ),
              ),
              BrowseContent(
                searchResults: _searchResults,
                isLoading: _isLoading,
                isLoadingMore: _isLoadingMore,
                error: _error,
                scrollController: _scrollController,
                onRetry: _searchSeries,
                onNavigateToDetail: _navigateToDetail,
                onNavigateToResults: _navigateToBrowseResults,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

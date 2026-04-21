import 'package:flutter/material.dart';
import 'dart:math';
import 'package:bakahyou/features/browse/widgets/mb_search_bar.dart';
import 'package:bakahyou/features/series/widgets/entry_list_item.dart';
import 'package:bakahyou/features/series/services/series_search_service.dart';
import 'package:bakahyou/features/series/screens/series_detail_screen.dart';
import 'package:bakahyou/features/browse/screens/browse_results_screen.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/browse/widgets/shortcut_section.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({Key? key}) : super(key: key);

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  // Constants
  static const int _pageLimit = 20;
  static const double _scrollThreshold = 100;
  static const Color _backgroundColor = Color(0xFF0a0a0a);
  static const double _horizontalPadding = 16.0;
  static const double _verticalPadding = 16.0;

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

  @override
  void initState() {
    super.initState();
    _searchService = SeriesSearchService();
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
    final isNearEnd = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - _scrollThreshold;

    if (isNearEnd && _hasMore && !_isLoadingMore && _currentSearchQuery.isNotEmpty) {
      _loadMoreResults();
    }
  }

  Future<void> _searchSeries(String text) async {
    if (text.trim().isEmpty) {
      _resetSearchState();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _searchResults = [];
      _currentSearchQuery = text;
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
      final newResults = await _searchService.searchSeriesByName(
        _currentSearchQuery,
        extraParams: {'page': _currentPage, 'limit': _pageLimit},
      );

      setState(() {
        _hasMore = newResults.length == _pageLimit;
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
      MaterialPageRoute(
        builder: (_) => SeriesDetailScreen(series: series),
      ),
    );
  }

  Widget _buildShortcutSections() {
    return SingleChildScrollView(
      child: Column(
        children: [
          ShortcutSection(
            header: 'Manga / Manhwa / Manhua',
            onMostPopular: () => _navigateToBrowseResults(
              'Most Popular',
              'popularity_asc',
              type: 'manga',
            ),
            onRandom: () => _navigateToBrowseResults(
              'Random',
              'random',
              type: 'manga',
            ),
          ),
          ShortcutSection(
            header: 'Novels',
            onMostPopular: () => _navigateToBrowseResults(
              'Most Popular',
              'popularity_asc',
              type: 'novel',
            ),
            onRandom: () => _navigateToBrowseResults(
              'Random',
              'random',
              type: 'novel',
            ),
          ),
          ShortcutSection(
            header: 'OEL / Other',
            onMostPopular: () => _navigateToBrowseResults(
              'Most Popular',
              'popularity_asc',
              type: 'oel',
            ),
            onRandom: () => _navigateToBrowseResults(
              'Random',
              'random',
              type: 'oel',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Expanded(
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _searchSeries(_currentSearchQuery),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _searchResults.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _searchResults.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final series = _searchResults[index];
          return InkWell(
            onTap: () => _navigateToDetail(series),
            child: EntryListItem(series: series),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    // Show shortcuts when no search
    if (_searchResults.isEmpty && !_isLoading && _error == null) {
      return Expanded(child: _buildShortcutSections());
    }

    // Show loading spinner
    if (_isLoading && _searchResults.isEmpty) {
      return _buildLoadingState();
    }

    // Show error
    if (_error != null && _searchResults.isEmpty) {
      return _buildErrorState();
    }

    // Show search results
    if (_searchResults.isNotEmpty) {
      return _buildResultsList();
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: _horizontalPadding,
            right: _horizontalPadding,
            top: _verticalPadding,
            bottom: 8.0,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: MBSearchBar(
                  onChanged: (text) {
                    if (text.isEmpty) {
                      _resetSearchState();
                    }
                  },
                  onSubmitted: _searchSeries,
                ),
              ),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }
}
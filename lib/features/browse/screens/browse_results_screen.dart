import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/series/screens/series_detail_screen.dart';
import 'package:bakahyou/features/series/widgets/entry_list_item.dart';
import 'package:bakahyou/features/series/services/series_search_service.dart';

class BrowseResultsScreen extends StatefulWidget {
  final String sortType;
  final String sortBy;
  final String? type;
  final num? randomSeed;

  const BrowseResultsScreen({
    required this.sortType,
    required this.sortBy,
    this.type,
    this.randomSeed,
    Key? key,
  }) : super(key: key);

  @override
  State<BrowseResultsScreen> createState() => _BrowseResultsScreenState();
}

class _BrowseResultsScreenState extends State<BrowseResultsScreen> {
  // Constants
  static const int _pageLimit = 20;
  static const double _scrollThreshold = 100;
  static const Color _backgroundColor = Color(0xFF0a0a0a);

  // Services & Controllers
  late final SeriesSearchService _searchService;
  late final ScrollController _scrollController;

  // State
  final List<Series> _results = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  late num _currentRandomSeed;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchService = SeriesSearchService();
    _scrollController = ScrollController();
    _currentRandomSeed = widget.randomSeed ?? _generateRandomSeed();
    _scrollController.addListener(_onScroll);
    _fetchResults(initial: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  static num _generateRandomSeed() {
    return Random().nextDouble() * 2 - 1;
  }

  void _onScroll() {
    final isNearEnd = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - _scrollThreshold;

    if (isNearEnd && _hasMore && !_isLoading) {
      _fetchResults(initial: false);
    }
  }

  Future<void> _fetchResults({bool initial = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final params = _buildRequestParams(initial);
      final newResults = await _searchService.searchSeriesByName(
        '',
        sortBy: widget.sortBy,
        type: widget.type,
        extraParams: params,
      );

      setState(() {
        if (initial) {
          _results.clear();
        }
        _results.addAll(newResults);
        _hasMore = newResults.length == _pageLimit;
        _isLoading = false;
        _incrementPageIfNeeded();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load results. Please try again.';
      });
    }
  }

  Map<String, dynamic> _buildRequestParams(bool initial) {
    final params = <String, dynamic>{
      'limit': _pageLimit,
      'page': _currentPage,
    };

    if (widget.sortBy == 'random') {
      if (!initial) {
        _currentRandomSeed = _generateRandomSeed();
      }
      params['random_seed'] = _currentRandomSeed;
    }

    return params;
  }

  void _incrementPageIfNeeded() {
    if (widget.sortBy == 'popularity_asc') {
      _currentPage++;
    }
  }

  void _navigateToDetail(Series series) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeriesDetailScreen(series: series),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No results found.',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
            onPressed: () => _fetchResults(initial: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _results.length + (_isLoading && _results.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _results.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final series = _results[index];
        final shouldShowRanking = widget.sortBy == 'popularity_asc';

        return InkWell(
          onTap: () => _navigateToDetail(series),
          child: shouldShowRanking
              ? EntryListItem(series: series, ranking: index + 1)
              : EntryListItem(series: series),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _buildErrorState();
    }

    if (_results.isEmpty && _isLoading) {
      return _buildLoadingState();
    }

    if (_results.isEmpty) {
      return _buildEmptyState();
    }

    return _buildResultsList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.sortType,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildBody(),
        ),
      ),
    );
  }
}
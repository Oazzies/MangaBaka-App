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
  final List<Series> _results = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  num? _currentRandomSeed;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentRandomSeed = widget.randomSeed;
    _fetchResults(initial: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (_hasMore && !_isLoading) {
        _fetchResults(initial: false);
      }
    }
  }

  Future<void> _fetchResults({bool initial = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = SeriesSearchService();
      Map<String, dynamic> params = {'limit': 20, 'page': _currentPage};
      if (widget.sortBy == 'random') {
        if (!initial) {
          // Generate a new random seed for each "load more" in random mode
          _currentRandomSeed = Random().nextDouble() * 2 - 1;
        }
        params['random_seed'] = _currentRandomSeed;
      }
      final newResults = await service.searchSeriesByName(
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
        _isLoading = false;
        _hasMore = newResults.length == 20;
        if (widget.sortBy == 'popularity_asc') {
          _currentPage++;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load results';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a0a0a),
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
          child: _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: _results.isEmpty && _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _results.isEmpty
                          ? const Center(
                              child: Text(
                                'No results found.',
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount:
                                  _results.length +
                                  (_isLoading && _results.isNotEmpty ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= _results.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.0,
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final series = _results[index];
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            SeriesDetailScreen(series: series),
                                      ),
                                    );
                                  },
                                  child: widget.sortBy == 'popularity_asc'
                                      ? EntryListItem(
                                          series: series,
                                          ranking: index + 1,
                                        )
                                      : EntryListItem(series: series),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

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
  final SeriesSearchService _searchService = SeriesSearchService();
  List<Series> searchResults = [];
  bool isLoading = false;
  String? error;

  Future<void> searchSeries(String text) async {
    if (text.trim().isEmpty) {
      setState(() {
        searchResults = [];
        error = null;
      });
      return;
    }
    setState(() {
      isLoading = true;
      error = null;
      searchResults = [];
    });
    try {
      final results = await _searchService.searchSeriesByName(text);
      setState(() {
        searchResults = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = "Not found or error";
        isLoading = false;
        searchResults = [];
      });
    }
  }

  void _openMostPopular() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BrowseResultsScreen(
          sortType: 'Most Popular',
          sortBy: 'popularity_asc',
        ),
      ),
    );
  }

  void _openRandom() {
    final randomSeed = Random().nextDouble() * 2 - 1; // between -1 and 1
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BrowseResultsScreen(
          sortType: 'Random',
          sortBy: 'random',
          randomSeed: randomSeed,
        ),
      ),
    );
  }

  void _openResults(String header, String sortBy, {String? type}) {
    num? randomSeed;
    if (sortBy == 'random') {
      randomSeed = Random().nextDouble() * 2 - 1;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: 8.0,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
                child: MBSearchBar(
                  onChanged: (text) {
                    if (text.isEmpty) {
                      setState(() {
                        searchResults = [];
                        error = null;
                      });
                    }
                  },
                  onSubmitted: searchSeries,
                ),
              ),
              if (searchResults.isEmpty && !isLoading && error == null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ShortcutSection(
                          header: 'Manga / Manhwa / Manhua',
                          onMostPopular: () => _openResults(
                            'Most Popular',
                            'popularity_asc',
                            type: 'manga',
                          ),
                          onRandom: () =>
                              _openResults('Random', 'random', type: 'manga'),
                        ),
                        ShortcutSection(
                          header: 'Novels',
                          onMostPopular: () => _openResults(
                            'Most Popular',
                            'popularity_asc',
                            type: 'novel',
                          ),
                          onRandom: () =>
                              _openResults('Random', 'random', type: 'novel'),
                        ),
                        ShortcutSection(
                          header: 'OEL / Other',
                          onMostPopular: () => _openResults(
                            'Most Popular',
                            'popularity_asc',
                            type: 'oel',
                          ),
                          onRandom: () =>
                              _openResults('Random', 'random', type: 'oel'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (isLoading) const CircularProgressIndicator(),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              if (searchResults.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final seriesObj = searchResults[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SeriesDetailScreen(series: seriesObj),
                            ),
                          );
                        },
                        child: EntryListItem(series: seriesObj),
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
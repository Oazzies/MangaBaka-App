import 'package:flutter/material.dart';
import 'package:mangabaka_app/widgets/mb_search_bar.dart';
import 'package:mangabaka_app/widgets/entry_list_item.dart';
import 'package:mangabaka_app/services/series_search_service.dart';
import 'package:mangabaka_app/screens/series_detail_screen.dart';
import 'package:mangabaka_app/models/series.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0a0a0a),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
                child: MBSearchBar(
                  onChanged: (_) {},
                  onSubmitted: searchSeries,
                ),
              ),
              if (isLoading)
                CircularProgressIndicator(),
              if (error != null)
                Text(error!, style: TextStyle(color: Colors.red)),
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
                              builder: (_) => SeriesDetailScreen(series: seriesObj),
                            ),
                          );
                        },
                        child: EntryListItem(series: seriesObj)
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
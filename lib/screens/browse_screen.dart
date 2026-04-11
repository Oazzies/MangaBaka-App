import 'package:flutter/material.dart';
import 'package:mangabaka_app/widgets/mb_search_bar.dart';
import 'package:mangabaka_app/widgets/entry_list_item.dart';
import 'package:mangabaka_app/services/series_search_service.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({Key? key}) : super(key: key);

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final SeriesSearchService _searchService = SeriesSearchService();
  List<Map<String, dynamic>> searchResults = [];
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
      appBar: AppBar(title: Text('Browse')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            MBSearchBar(
              onChanged: searchSeries,
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
                    final item = searchResults[index];
                    return EntryListItem(
                      coverUrl: item['cover']?['x150']?['x1'] ?? '',
                      title: item['title'] ?? '',
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
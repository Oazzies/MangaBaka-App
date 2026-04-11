import 'package:flutter/material.dart';
import 'package:mangabaka_app/widgets/mb_search_bar.dart';
import 'package:mangabaka_app/widgets/entry_list_item.dart';
import 'package:mangabaka_app/services/series_service.dart';

class BrowseScreen extends StatefulWidget{
  const BrowseScreen({Key? key}) : super(key: key);

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  Map<String, dynamic>? series;
  bool isLoading = false;
  String? error;

  Future<void> fetchSeriesById(String text) async {
    final id = int.tryParse(text);
    if (id == null){
      setState(() {
        error = "Please enter a valid number";
        series = null;
      });
      return;
    }
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final data = await SeriesService.fetchSeries(id);
      setState(() {
        series = data;
        isLoading = false;
      });
    } catch (exception) {
      setState(() {
        error = "Not found or error";
        isLoading = false;
        series = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            MBSearchBar(
              onChanged: fetchSeriesById,
            ),
            if (isLoading)
              CircularProgressIndicator(),
            if (error != null)
              Text(error!, style: TextStyle(color: Colors.red)),
            if (series != null)
              EntryListItem(
                coverUrl: series!['cover']['x150']['x1'],
                title: series!['title'],
              ),
          ],
        ),
      ),
    );
  }
}
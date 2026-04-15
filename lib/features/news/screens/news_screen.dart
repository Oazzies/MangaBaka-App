import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:mangabaka_app/features/news/services/news_service.dart';
import 'package:mangabaka_app/features/news/widgets/news_list.item.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsService _newsService = NewsService();
  final List<News> _newsList = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNews(initial: true);
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
        _fetchNews(initial: false);
      }
    }
  }

  Future<void> _fetchNews({bool initial = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newNews = await _newsService.fetchNews(page: _currentPage, limit: 10);
      setState(() {
        if (initial) {
          _newsList.clear();
        }
        _newsList.addAll(newNews);
        _isLoading = false;
        _hasMore = newNews.length == 10;
        _currentPage++;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load news';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _newsList.isEmpty && !_isLoading
            ? Center(child: Text(_error ?? 'No news found.'))
            : ListView.builder(
                controller: _scrollController,
                itemCount: _newsList.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _newsList.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return NewsListItem(news: _newsList[index]);
                },
              ),
      ),
    );
  }
}
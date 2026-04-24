import 'package:flutter/material.dart';
import 'package:bakahyou/features/news/models/news.dart';
import 'package:bakahyou/features/news/services/news_service.dart';
import 'package:bakahyou/features/news/widgets/news_list.item.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsService _newsService = NewsService();
  final List<News> _newsList = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isBackgroundRefresh = false;
  int _currentPage = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCachedAndFetch();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadCachedAndFetch() async {
    final cachedNews = await _newsService.getCachedNews();
    if (mounted && cachedNews.isNotEmpty) {
      setState(() {
        _newsList.addAll(cachedNews);
        _currentPage = 2; // temporarily, in case user scrolls immediately
      });
    }
    _fetchNews(initial: true, isBackground: cachedNews.isNotEmpty);
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

  Future<void> _fetchNews({bool initial = false, bool isBackground = false}) async {
    if (_isLoading || _isBackgroundRefresh) return;
    
    setState(() {
      if (isBackground) {
        _isBackgroundRefresh = true;
      } else {
        _isLoading = true;
      }
      _error = null;
    });

    try {
      final pageToFetch = initial ? 1 : _currentPage;
      final newNews = await _newsService.fetchNews(
        page: pageToFetch,
        limit: 10,
      );
      if (!mounted) return;
      setState(() {
        if (initial) {
          _newsList.clear();
          _currentPage = 1;
        }
        _newsList.addAll(newNews);
        _isLoading = false;
        _isBackgroundRefresh = false;
        _hasMore = newNews.length == 10;
        _currentPage++;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isBackgroundRefresh = false;
        if (!isBackground) _error = 'Failed to load news';
      });
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
    });
    await _fetchNews(initial: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBackground,
      body: SafeArea(
        child: _newsList.isEmpty && !_isLoading && !_isBackgroundRefresh
            ? Center(child: Text(_error ?? 'No news found.'))
            : RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView.builder(
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
      ),
    );
  }
}

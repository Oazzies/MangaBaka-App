import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:mangabaka_app/features/news/services/news_service.dart';
import 'package:mangabaka_app/features/news/widgets/news_list.item.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';

import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';

import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  static final _logger = LoggingService.logger;
  late final NewsService _newsService;
  final List<News> _newsList = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isBackgroundRefresh = false;
  int _currentPage = 1;
  String? _error;
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _logger.info('News screen initialized');
    _newsService = getIt<NewsService>();
    _loadCachedAndFetch();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadCachedAndFetch() async {
    _logger.fine('Loading cached news...');
    final cachedNews = await _newsService.getCachedNews();
    if (mounted && cachedNews.isNotEmpty) {
      _logger.info('Loaded ${cachedNews.length} news items from cache');
      setState(() {
        _newsList.addAll(cachedNews);
        _currentPage = 2; //in case user scrolls immediately
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
        _scrollController.position.maxScrollExtent - AppConstants.scrollThresholdPx) {
      if (_hasMore && !_isLoading) {
        _logger.fine('Scroll reached bottom, fetching more news (page $_currentPage)');
        _fetchNews(initial: false);
      }
    }

    final showBackToTop = _scrollController.offset > 500;
    if (showBackToTop != _showBackToTop) {
      setState(() {
        _showBackToTop = showBackToTop;
      });
    }
  }

  Future<void> _fetchNews({bool initial = false, bool isBackground = false}) async {
    if (_isLoading || _isBackgroundRefresh) return;
    
    _logger.info('Fetching news: initial=$initial, isBackground=$isBackground, page=$_currentPage');
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
        limit: AppConstants.defaultPageLimit,
      );
      if (!mounted) return;

      _logger.info('Received ${newNews.length} news items for page $pageToFetch');

      setState(() {
        if (initial) {
          _newsList.clear();
          _currentPage = 1;
        }
        _newsList.addAll(newNews);
        _isLoading = false;
        _isBackgroundRefresh = false;
        _hasMore = newNews.length == AppConstants.defaultPageLimit;
        _currentPage++;
      });
    } catch (e) {
      _logger.severe('Error in NewsScreen while fetching news: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isBackgroundRefresh = false;
        if (!isBackground) _error = 'Failed to load news';
      });
    }
  }

  Future<void> _onRefresh() async {
    _logger.info('User triggered pull-to-refresh for news');
    setState(() {
      _currentPage = 1;
      _hasMore = true;
    });
    await _fetchNews(initial: true);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), ThemeManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();
        return Scaffold(
          backgroundColor: AppConstants.primaryBackground,
          body: SafeArea(
            child: _newsList.isEmpty && !_isLoading && !_isBackgroundRefresh
                ? Center(
                    child: Text(
                      _error != null
                          ? '${l10n.translate('failed_to_load')}: $_error'
                          : l10n.translate('no_results'),
                      style: TextStyle(color: AppConstants.textMutedColor),
                    ),
                  )
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
          floatingActionButton: _showBackToTop
              ? FloatingActionButton(
                  onPressed: () {
                    _scrollController.animateTo(
                      0,
                      duration: AppConstants.mediumAnimationDuration,
                      curve: Curves.easeInOut,
                    );
                  },
                  backgroundColor: AppConstants.accentColor,
                  child: Icon(Icons.arrow_upward, color: AppConstants.primaryBackground),
                )
              : null,
        );
      },
    );
  }
}

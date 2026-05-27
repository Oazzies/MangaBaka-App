import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:mangabaka_app/utils/app_shortcuts.dart';
import 'package:mangabaka_app/features/news/services/news_service.dart';
import 'package:mangabaka_app/features/news/widgets/news_list.item.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/features/profile/screens/settings_screen.dart';

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Data loading
  // -------------------------------------------------------------------------

  Future<void> _loadCachedAndFetch() async {
    _logger.fine('Loading cached news...');
    final cachedNews = await _newsService.getCachedNews();
    if (mounted && cachedNews.isNotEmpty) {
      _logger.info('Loaded ${cachedNews.length} news items from cache');
      setState(() {
        _newsList.addAll(cachedNews);
        _currentPage = 2; // advance so an immediate scroll doesn't re-fetch page 1
      });
    }
    _fetchNews(initial: true, isBackground: cachedNews.isNotEmpty);
  }

  Future<void> _fetchNews({bool initial = false, bool isBackground = false}) async {
    if (_isLoading || _isBackgroundRefresh) return;

    _logger.info(
      'Fetching news: initial=$initial, isBackground=$isBackground, page=$_currentPage',
    );
    setState(() {
      _error = null;
      if (isBackground) {
        _isBackgroundRefresh = true;
      } else {
        _isLoading = true;
      }
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
    _logger.info('User triggered manual refresh for news');
    // Do NOT set _isLoading = true here — _fetchNews guards against concurrent
    // fetches by checking _isLoading, so pre-setting it would cause the fetch
    // to return immediately and silently skip the refresh.
    setState(() {
      _currentPage = 1;
      _hasMore = true;
    });

    // Keep the RefreshIndicator visible for at least 800 ms for visual feedback.
    await Future.wait([
      _fetchNews(initial: true),
      Future.delayed(const Duration(milliseconds: 800)),
    ]);
  }

  // -------------------------------------------------------------------------
  // Scroll handling
  // -------------------------------------------------------------------------

  void _onScroll() {
    _checkPaginationTrigger();
    _checkBackToTopVisibility();
  }

  void _checkPaginationTrigger() {
    final nearBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - AppConstants.scrollThresholdPx;
    if (nearBottom && _hasMore && !_isLoading) {
      _logger.fine('Scroll reached bottom, fetching more news (page $_currentPage)');
      _fetchNews(initial: false);
    }
  }

  void _checkBackToTopVisibility() {
    final shouldShow = _scrollController.offset > 500;
    if (shouldShow != _showBackToTop) {
      setState(() => _showBackToTop = shouldShow);
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LocalizationService(),
        ThemeManager(),
        SettingsManager(),
      ]),
      builder: (context, _) {
        final l10n = LocalizationService();
        final settings = SettingsManager();
        final screenWidth = MediaQuery.of(context).size.width;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        // 2-column grid only makes sense in landscape on wider screens.
        final isGrid = settings.newsListColumns > 1 && screenWidth > 400 && isLandscape;

        return Scaffold(
          backgroundColor: AppConstants.primaryBackground,
          appBar: _buildAppBar(l10n, settings, screenWidth, isLandscape),
          body: Actions(
            actions: <Type, Action<Intent>>{
              RefreshIntent: CallbackAction<RefreshIntent>(
                onInvoke: (_) { _onRefresh(); return null; },
              ),
            },
            child: WidgetUtils.responsiveConstraint(
              SafeArea(child: _buildContent(l10n, isGrid)),
              maxWidth: isGrid ? double.infinity : 800,
            ),
          ),
          floatingActionButton: _buildBackToTopFab(l10n),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    LocalizationService l10n,
    SettingsManager settings,
    double screenWidth,
    bool isLandscape,
  ) {
    return AppBar(
      centerTitle: true,
      title: Text(
        l10n.translate('news'),
        style: TextStyle(
          color: AppConstants.textColor,
          fontWeight: FontWeight.bold,
          fontSize: 22,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        if (isLandscape)
          WidgetUtils.tooltip(
            message: l10n.translate('toggle_layout'),
            child: IconButton(
              icon: Icon(
                settings.newsListColumns == 2
                    ? Icons.view_agenda_outlined
                    : Icons.grid_view_rounded,
                color: AppConstants.textColor,
              ),
              onPressed: () {
                settings.setNewsListColumns(settings.newsListColumns == 1 ? 2 : 1);
              },
            ),
          ),
        if (screenWidth < 600)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
      ],
    );
  }

  Widget _buildContent(LocalizationService l10n, bool isGrid) {
    if (_newsList.isEmpty && !_isLoading && !_isBackgroundRefresh) {
      return Center(
        child: Text(
          _error != null
              ? '${l10n.translate('failed_to_load')}: $_error'
              : l10n.translate('no_results'),
          style: TextStyle(color: AppConstants.textMutedColor),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: isGrid ? _buildGridView() : _buildListView(),
    );
  }

  /// Hand-rolled 2-column masonry layout: odd-indexed items go left, even go right.
  Widget _buildGridView() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < _newsList.length; i += 2)
                      NewsListItem(
                        key: ValueKey('grid_${_newsList[i].id}'),
                        news: _newsList[i],
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 1; i < _newsList.length; i += 2)
                      NewsListItem(
                        key: ValueKey('grid_${_newsList[i].id}'),
                        news: _newsList[i],
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
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
        return NewsListItem(
          key: ValueKey('list_${_newsList[index].id}'),
          news: _newsList[index],
        );
      },
    );
  }

  Widget? _buildBackToTopFab(LocalizationService l10n) {
    if (!_showBackToTop) return null;
    return WidgetUtils.tooltip(
      message: l10n.translate('back_to_top'),
      child: FloatingActionButton(
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: AppConstants.mediumAnimationDuration,
            curve: Curves.easeInOut,
          );
        },
        backgroundColor: AppConstants.accentColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
        ),
        child: Icon(Icons.arrow_upward, color: AppConstants.primaryBackground),
      ),
    );
  }
}

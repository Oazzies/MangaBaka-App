import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/series/screens/series_detail_screen.dart';
import 'package:bakahyou/features/series/widgets/entry_list_item.dart';
import 'package:bakahyou/features/series/services/series_search_service.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/utils/settings/settings_enums.dart';

import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/features/browse/widgets/list_skeleton.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BrowseResultsScreen extends StatefulWidget {
  final String sortType;
  final String sortBy;
  final String? type;
  final double? randomSeed;



  const BrowseResultsScreen({
    required this.sortType,
    required this.sortBy,
    this.type,
    this.randomSeed,
    super.key,
  });

  @override
  State<BrowseResultsScreen> createState() => _BrowseResultsScreenState();
}

class _BrowseResultsScreenState extends State<BrowseResultsScreen> {
  // Services & Controllers
  late final SeriesSearchService _searchService;
  late final ScrollController _scrollController;

  // State
  final List<Series> _results = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  late double _currentRandomSeed;


  String? _error;
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _searchService = getIt<SeriesSearchService>();
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

  static double _generateRandomSeed() {
    return Random().nextDouble();
  }



  void _onScroll() {
    final isNearEnd =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent -
            AppConstants.scrollThresholdPx;

    if (isNearEnd && _hasMore && !_isLoading) {
      _fetchResults(initial: false);
    }

    final showBackToTop = _scrollController.offset > 500;
    if (showBackToTop != _showBackToTop) {
      setState(() {
        _showBackToTop = showBackToTop;
      });
    }
  }

  Future<void> _fetchResults({bool initial = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String? userId;
      if (SettingsManager().hideLibrarySeriesInBrowse) {
        final auth = getIt<ProfileAuthService>();
        if (auth.isLoggedIn) {
          final profile = auth.cachedProfile;
          if (profile != null) {
            // exclude_user_library expects a 32-character alphanumeric string.
            // UUIDs from the profile ID might contain hyphens, so we strip them.
            userId = profile.id.replaceAll('-', '');
          }
        }
      }

      final params = _buildRequestParams(initial, userId);
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
        _hasMore = newResults.length == AppConstants.defaultPageLimit;
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

  Map<String, dynamic> _buildRequestParams(bool initial, String? excludeUserId) {
    final params = <String, dynamic>{
      'limit': AppConstants.defaultPageLimit,
      'page': _currentPage,
    };

    if (excludeUserId != null && excludeUserId.isNotEmpty) {
      params['exclude_user_library'] = excludeUserId;
    }

    if (widget.sortBy == 'random') {
      if (!initial) {
        _currentRandomSeed = _generateRandomSeed();
      }
      params['random_seed'] = _currentRandomSeed;
    }

    return params;
  }

  void _incrementPageIfNeeded() {
    // We increment page for all sorts except random, 
    // as random usually handles its own shuffling/seed logic
    if (widget.sortBy != 'random') {
      _currentPage++;
    }
  }


  void _navigateToDetail(Series series) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SeriesDetailScreen(series: series)),
    );
  }

  Widget _buildLoadingState() {
    final settings = SettingsManager();
    final activeStyle = settings.separateListStyles ? settings.browseListStyle : settings.currentListStyle;
    final isGrid = activeStyle == AppListStyle.grid || activeStyle == AppListStyle.coverOnlyGrid;
    
    return ListSkeleton(isGrid: isGrid);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text('No results found.', style: TextStyle(color: AppConstants.textColor)),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppConstants.errorColor, size: 48),
          SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(color: AppConstants.errorColor),
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
    return ListenableBuilder(
      listenable: SettingsManager(),
      builder: (context, _) {
        final settings = SettingsManager();
        final activeStyle = settings.separateListStyles ? settings.browseListStyle : settings.currentListStyle;
        final isGrid = activeStyle == AppListStyle.grid || activeStyle == AppListStyle.coverOnlyGrid;
        final shouldShowRanking = widget.sortBy == 'popularity_asc';

        if (isGrid) {
          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              childAspectRatio: 0.65,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _results.length + (_isLoading && _results.isNotEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _results.length) {
                return const Center(child: CircularProgressIndicator());
              }

              final series = _results[index];
              return InkWell(
                onTap: () => _navigateToDetail(series),
                child: shouldShowRanking
                    ? EntryListItem(series: series, ranking: index + 1)
                    : EntryListItem(series: series),
              );
            },
          );
        }

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
            return InkWell(
              onTap: () => _navigateToDetail(series),
              child: shouldShowRanking
                  ? EntryListItem(series: series, ranking: index + 1)
                  : EntryListItem(series: series),
            );
          },
        );
      },
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _buildErrorState();
    }

    return AnimatedSwitcher(
      duration: 600.ms,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _results.isEmpty && _isLoading
          ? _buildLoadingState()
          : _results.isEmpty
              ? _buildEmptyState()
              : _buildResultsList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppConstants.primaryBackground,
          appBar: AppBar(
            backgroundColor: AppConstants.primaryBackground,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.sortType,
              style: TextStyle(color: AppConstants.textColor),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
              child: _buildBody(),
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
                  child: const Icon(Icons.arrow_upward, color: Colors.white),
                )
              : null,
        );
      },
    );
  }
}

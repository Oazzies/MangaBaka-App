import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/utils/transitions/app_transitions.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';
import 'package:mangabaka_app/features/browse/widgets/browse_results_body.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';

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
  static final _logger = LoggingService.logger;
  late final SeriesSearchService _searchService;
  late final ScrollController _scrollController;

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
      _logger.fine('Near end of scroll in results, loading page: ${_currentPage + 1}');
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

    _logger.info('Fetching results for "${widget.sortType}" (sortBy: ${widget.sortBy}), page: $_currentPage, initial: $initial');
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
            userId = profile.id.replaceAll('-', '');
            _logger.fine('Hiding library series for user: $userId');
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

      _logger.info('Fetched ${newResults.length} results for page $_currentPage');

      if (!mounted) return;

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
      _logger.severe('Failed to fetch results for "${widget.sortType}" at page $_currentPage: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = LocalizationService().translate('failed_to_load');
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
      AppTransitions.slideUp(SeriesDetailScreen(series: series)),
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
            centerTitle: true,
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
              child: BrowseResultsBody(
                error: _error,
                isLoading: _isLoading,
                results: _results,
                sortBy: widget.sortBy,
                scrollController: _scrollController,
                onRetry: () => _fetchResults(initial: true),
                onSeriesTap: _navigateToDetail,
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

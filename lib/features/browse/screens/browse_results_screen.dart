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
import 'package:bakahyou/utils/transitions/app_transitions.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/features/browse/widgets/browse_results_body.dart';
import 'package:bakahyou/features/browse/widgets/browse_results_list.dart';
import 'package:bakahyou/features/browse/widgets/browse_results_status_widgets.dart';

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

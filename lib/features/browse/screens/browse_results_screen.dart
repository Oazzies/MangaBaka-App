import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/browse/widgets/results/browse_results_body.dart';
import 'package:mangabaka_app/features/browse/controllers/browse_controller.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/browse/widgets/results/browse_results_helpers.dart';

class BrowseResultsScreen extends StatefulWidget {
  final String sortType;
  final String sortBy;
  final String? type;
  final String? staff;
  final String? publisher;

  /// Restricts to one publisher by id — exact, unlike [publisher], which
  /// matches by name. [publisher] is still what titles the screen.
  final String? publisherId;

  /// A genre name to restrict results to.
  final String? genre;

  /// What the publisher's results were narrowed to (a genre, an audience...),
  /// named in the title: Kodansha Works of Seinen.
  final String? refineLabel;

  /// A tag id to restrict results to (e.g. a "Top in {genre}" rail's genre).
  final String? tag;
  final double? randomSeed;

  const BrowseResultsScreen({
    required this.sortType,
    required this.sortBy,
    this.type,
    this.staff,
    this.publisher,
    this.publisherId,
    this.genre,
    this.refineLabel,
    this.tag,
    this.randomSeed,
    super.key,
  });

  String get heroTagPrefix {
    if (staff != null) {
      return 'staff_${staff!.replaceAll(' ', '_')}';
    }
    if (publisher != null) {
      return 'publisher_${publisher!.replaceAll(' ', '_')}';
    }
    return 'browse_${sortType.replaceAll(' ', '_')}';
  }

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
    _currentRandomSeed =
        widget.randomSeed ?? BrowseController.generateRandomSeed();
    _scrollController.addListener(_onScroll);
    _fetchResults(initial: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final isNearEnd =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent -
            AppConstants.scrollThresholdPx;

    if (isNearEnd && _hasMore && !_isLoading) {
      _logger.fine(
        'Near end of scroll in results, loading page: ${_currentPage + 1}',
      );
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

    _logger.info(
      'Fetching results for "${widget.sortType}" (sortBy: ${widget.sortBy}), page: $_currentPage, initial: $initial',
    );
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
      final result = await _searchService.searchSeries(
        '',
        sortBy: widget.sortBy,
        type: widget.type,
        extraParams: params,
      );

      final newResults = result.series;
      final total = result.total;

      _logger.info(
        'Fetched ${newResults.length} results for page $_currentPage (Total: $total)',
      );

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

      // If we have more but they might fit on screen, check if we need to load more
      if (_hasMore) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _onScroll();
        });
      }
    } catch (e, st) {
      _logger.severe(
        'Failed to fetch results for "${widget.sortType}" at page $_currentPage',
        e,
        st,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = LocalizationService().translate('failed_to_load');
      });
    }
  }

  Map<String, dynamic> _buildRequestParams(
    bool initial,
    String? excludeUserId,
  ) {
    if (widget.sortBy == 'random' && !initial) {
      _currentRandomSeed = BrowseController.generateRandomSeed();
    }
    return BrowseResultsHelpers.buildRequestParams(
      page: _currentPage,
      sortBy: widget.sortBy,
      staff: widget.staff,
      publisherId: widget.publisherId,
      publisher: widget.publisher,
      genre: widget.genre,
      tag: widget.tag,
      excludeUserId: excludeUserId,
      randomSeed: _currentRandomSeed,
    );
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
      AppTransitions.slideUp(
        SeriesDetailScreen(series: series, heroTagPrefix: widget.heroTagPrefix),
      ),
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: AppConstants.mediumAnimationDuration,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: context.colors.background,
          appBar: BrowseResultsAppBar(
            title: BrowseResultsHelpers.buildTitleText(
              l10n: LocalizationService(),
              sortType: widget.sortType,
              staff: widget.staff,
              publisher: widget.publisher,
              refineLabel: widget.refineLabel,
            ),
          ),
          body: ListenableBuilder(
            listenable: SettingsManager(),
            builder: (context, _) {
              final isGrid = SettingsManager().resolvedBrowseListStyle.isGrid;

              return NotificationListener<ScrollMetricsNotification>(
                onNotification: (notification) {
                  _onScroll();
                  return false;
                },
                child: WidgetUtils.responsiveConstraint(
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: BrowseResultsBody(
                        error: _error,
                        isLoading: _isLoading,
                        results: _results,
                        sortBy: widget.sortBy,
                        scrollController: _scrollController,
                        onRetry: () => _fetchResults(initial: true),
                        onSeriesTap: _navigateToDetail,
                        heroTagPrefix: widget.heroTagPrefix,
                      ),
                    ),
                  ),
                  maxWidth: isGrid ? double.infinity : 800,
                ),
              );
            },
          ),
          floatingActionButton: _showBackToTop
              ? FloatingActionButton(
                  onPressed: _scrollToTop,
                  backgroundColor: context.colors.accent,
                  child: Icon(
                    Icons.arrow_upward,
                    color: context.colors.background,
                  ),
                )
              : null,
        );
      },
    );
  }
}

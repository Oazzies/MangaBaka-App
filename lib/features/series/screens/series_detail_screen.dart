import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';
import 'package:mangabaka_app/features/browse/utils/browse_navigation.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/controllers/series_filter_drawer_controller.dart';
import 'package:mangabaka_app/features/series/mixins/series_detail_actions_mixin.dart';
import 'package:mangabaka_app/features/series/mixins/series_detail_data_mixin.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_body.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_fab.dart';
import 'package:mangabaka_app/features/series/widgets/series_filter_drawer.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

export 'package:mangabaka_app/core/widgets/dotted_border_painter.dart';

/// The series detail page.
///
/// Owns three things and delegates the rest: the route-transition gate that
/// keeps off-screen work from competing with the push animation, the library
/// entry stream, and the filter-drawer controller. Layout lives in
/// [SeriesDetailBody]; filter state lives in [SeriesFilterDrawerController].
class SeriesDetailScreen extends StatefulWidget {
  final Series series;
  final String? heroTagPrefix;

  /// When true the page is rendered inside another screen (the Discovery
  /// Queue) rather than pushed as its own route: no back button, no FAB, and
  /// deleting the entry does not pop the host route.
  final bool embedded;

  /// Optional content for a right-hand rail in the wide layout, scrolling with
  /// the page. Used by the Discovery Queue.
  final Widget? rightRail;

  const SeriesDetailScreen({
    super.key,
    required this.series,
    this.heroTagPrefix,
    this.embedded = false,
    this.rightRail,
  });

  /// The nearest detail screen's state, so descendant chips can start a filter
  /// or a search without every layer in between forwarding a callback.
  static SeriesDetailScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<SeriesDetailScreenState>();

  @override
  State<SeriesDetailScreen> createState() => SeriesDetailScreenState();
}

class SeriesDetailScreenState extends State<SeriesDetailScreen>
    with
        TickerProviderStateMixin,
        SeriesDetailActionsMixin,
        SeriesDetailDataMixin {
  static final _logger = LoggingService.logger;

  late final LibraryService _libraryService;
  late final SeriesService _seriesService;
  late final SeriesFilterDrawerController _filterDrawer;

  Stream<LibraryEntry?>? _entryStream;
  bool _isAdding = false;
  String _selectedTab = 'Info';

  /// Completes once the route push transition has settled. The body renders
  /// straight away from the [Series] we were handed, but work the user cannot
  /// see yet is held until this fires so it never competes with the slide:
  /// network results, filter metadata, and the below-the-fold tags card.
  final Completer<void> _canApplyData = Completer<void>();
  bool _routeAnimListenerAttached = false;

  @override
  Future<void> whenReadyToApplyData() => _canApplyData.future;

  /// Completes once the push transition has settled.
  ///
  /// The body itself renders immediately, but content below the fold has no
  /// reason to compete with the slide for frames — it can't be seen yet. The
  /// tags card uses this to hold its build until the page has landed.
  Future<void> get transitionSettled => _canApplyData.future;

  SearchFilters? get drawerFilters => _filterDrawer.filters;

  @override
  LibraryService get libraryService => _libraryService;

  @override
  SeriesService get seriesService => _seriesService;

  @override
  Series get series => widget.series;

  @override
  bool get isAdding => _isAdding;

  @override
  set isAdding(bool value) => _isAdding = value;

  @override
  bool get popAfterDelete => !widget.embedded;

  @override
  String get selectedTab => _selectedTab;

  @override
  void initState() {
    super.initState();
    _logger.info(
      'Series detail screen initialized for series: '
      '${widget.series.title} (${widget.series.id})',
    );

    _libraryService = getIt<LibraryService>();
    _seriesService = getIt<SeriesService>();
    _entryStream = _libraryService.watchEntryFromDb(widget.series.id);
    fullSeries = widget.series;

    _filterDrawer = SeriesFilterDrawerController(vsync: this);

    // Filter metadata only feeds the drawer, which cannot be open yet. Load it
    // once the push transition has settled so it never competes with the first
    // frame.
    _canApplyData.future.then((_) {
      if (mounted) _filterDrawer.loadMetadata();
    });

    // The fetch, by contrast, starts immediately: results that arrive during
    // the transition mean no skeleton is shown at all.
    fetchFullData()
        .then((_) {
          _logger.info(
            'Full data fetch complete for series: ${widget.series.id}',
          );
        })
        .catchError((Object e) {
          _logger.severe(
            'Full data fetch failed for series: ${widget.series.id}. Error: $e',
          );
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeAnimListenerAttached) return;
    _routeAnimListenerAttached = true;

    final animation = ModalRoute.of(context)?.animation;
    if (animation == null ||
        animation.status == AnimationStatus.completed ||
        animation.status == AnimationStatus.dismissed) {
      // No transition to wait on (already settled, or pushed without one).
      _completeCanApplyData();
      return;
    }

    void listener(AnimationStatus status) {
      if (status != AnimationStatus.completed &&
          status != AnimationStatus.dismissed) {
        return;
      }
      animation.removeStatusListener(listener);
      _completeCanApplyData();
    }

    animation.addStatusListener(listener);
  }

  @override
  void dispose() {
    // Unblock any fetch still awaiting the transition gate so its async
    // continuation isn't left suspended forever.
    _completeCanApplyData();
    _filterDrawer.dispose();
    super.dispose();
  }

  void _completeCanApplyData() {
    if (_canApplyData.isCompleted) return;
    _canApplyData.complete();
  }

  // ─── Chip interactions ───────────────────────────────────────────────────
  //
  // Called by descendant widgets through [SeriesDetailScreen.of]. Tap runs the
  // search straight away; long-press adds to the filter drawer instead.

  void handleTagTap(String tagName) {
    // Fall back to the raw name when the id is not known yet — the search
    // endpoint accepts either, and the alternative is a dead chip.
    final tagId = _filterDrawer.resolveTagId(tagName) ?? tagName;
    BrowseNavigation.searchByTags(context, [tagId]);
  }

  void handleTagLongPress(String tagName) =>
      _filterDrawer.toggleTagByName(tagName);

  void handleGenreTap(String genreKey) =>
      BrowseNavigation.searchByGenre(context, genreKey);

  void handleGenreLongPress(String genreKey) =>
      _filterDrawer.toggleGenre(genreKey);

  void handleTypeToggle(String typeKey) => _filterDrawer.toggleType(typeKey);

  void handleStatusToggle(String statusKey) =>
      _filterDrawer.toggleStatus(statusKey);

  void handleStaffToggle(String staffName) =>
      _filterDrawer.toggleStaff(staffName);

  void handlePublisherToggle(String publisherName) =>
      _filterDrawer.togglePublisher(publisherName);

  void handleYearToggle(int year) => _filterDrawer.toggleYear(year);

  void executeSearchWithFilters(SearchFilters filters) =>
      BrowseNavigation.searchWithFilters(context, filters);

  void _navigateToAuthorSeries(String authorName) {
    _logger.info('Navigating to series by author: $authorName');
    Navigator.push(
      context,
      AppTransitions.slideRight(
        BrowseResultsScreen(
          sortType: authorName,
          sortBy: 'popularity_desc',
          staff: authorName,
        ),
      ),
    );
  }

  void _navigateToPublisherSeries(String publisherName) {
    _logger.info('Navigating to series by publisher: $publisherName');
    Navigator.push(
      context,
      AppTransitions.slideRight(
        BrowseResultsScreen(
          sortType: publisherName,
          sortBy: 'popularity_desc',
          publisher: publisherName,
        ),
      ),
    );
  }

  void _retryFetch() {
    setState(() {
      isDataLoaded = false;
      fetchError = false;
    });
    fetchFullData();
  }

  void _onTabChanged(String tab) {
    _logger.info('Series detail tab switched to: $tab');
    setState(() => _selectedTab = tab);
    fetchTabData(tab);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LocalizationService(),
        getIt<ProfileAuthService>(),
        _filterDrawer,
      ]),
      builder: (context, _) {
        return PopScope(
          // Back closes the filter drawer before it leaves the page.
          canPop: !_filterDrawer.isOpen,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_filterDrawer.isOpen) _filterDrawer.close();
          },
          // The wide layout carries its own add button in the sidebar; the FAB
          // is the phone/tablet-portrait affordance only. Measured from the
          // page's own constraints, as the body does, so the two always agree
          // on which layout is showing (the desktop sidebar takes width too).
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide =
                  constraints.maxWidth > SeriesDetailBody.wideBreakpoint;
              return Scaffold(
                backgroundColor: context.colors.background,
                body: Stack(
                  children: [
                    Positioned.fill(
                      child: SeriesDetailBody(
                        state: this,
                        entryStream: _entryStream,
                        settings: SettingsManager(),
                        l10n: LocalizationService(),
                        embedded: widget.embedded,
                        rightRail: widget.rightRail,
                        onRetry: _retryFetch,
                        onTabChanged: _onTabChanged,
                        onAuthorTap: _navigateToAuthorSeries,
                        onPublisherTap: _navigateToPublisherSeries,
                      ),
                    ),
                    // Positioned, like the body: a non-positioned child would
                    // make the Stack size itself to that child instead of to the
                    // incoming constraints, collapsing the page.
                    if (_filterDrawer.isOpen)
                      Positioned.fill(
                        child: SeriesFilterDrawer(
                          controller: _filterDrawer,
                          onSearch: executeSearchWithFilters,
                        ),
                      ),
                  ],
                ),
                floatingActionButton: (isWide || widget.embedded)
                    ? null
                    : SeriesDetailFAB(
                        entryStream: _entryStream,
                        isAdding: _isAdding,
                        onAdd: addSeriesToLibrary,
                      ),
              );
            },
          ),
        );
      },
    );
  }
}

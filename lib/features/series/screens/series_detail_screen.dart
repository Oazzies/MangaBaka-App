import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';
import 'package:mangabaka_app/features/browse/utils/browse_navigation.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/lists/services/library_lists_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/controllers/series_filter_drawer_controller.dart';
import 'package:mangabaka_app/features/series/mixins/series_detail_actions_mixin.dart';
import 'package:mangabaka_app/features/series/mixins/series_detail_data_mixin.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/series/services/series_list_deps.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_scaffold.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_status_controller.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

export 'package:mangabaka_app/core/widgets/dotted_border_painter.dart';

class SeriesDetailScreen extends StatefulWidget {
  final Series series;
  final String? heroTagPrefix;

  /// Inside the Discovery Queue, not its own route: no back button, no FAB, no pop on delete.
  final bool embedded;

  final Widget? rightRail;

  const SeriesDetailScreen({
    super.key,
    required this.series,
    this.heroTagPrefix,
    this.embedded = false,
    this.rightRail,
  });

  /// Lets descendant chips start a filter or search without every layer forwarding a callback.
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
  late final ProfileAuthService _auth = getIt<ProfileAuthService>();

  late final SeriesListDeps listDeps = SeriesListDeps(
    auth: _auth,
    library: _libraryService,
    prefetch: _seriesService.fetchSeries,
  );

  bool get isLoggedIn => _auth.isLoggedIn;
  MetadataService get metadata => getIt<MetadataService>();
  StackService get stackService => getIt<StackService>();
  LibraryListsService get listsService => getIt<LibraryListsService>();
  StackStatusController get stackStatus => getIt<StackStatusController>();

  Stream<LibraryEntry?>? _entryStream;
  bool _isAdding = false;
  String _selectedTab = 'Info';

  /// Network results, filter metadata and the tags card wait on this so they never compete with the push.
  final Completer<void> _canApplyData = Completer<void>();
  bool _routeAnimListenerAttached = false;

  @override
  Future<void> whenReadyToApplyData() => _canApplyData.future;

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

    _canApplyData.future.then((_) {
      if (mounted) _filterDrawer.loadMetadata();
    });

    // Not gated: results that arrive during the transition mean no skeleton is shown.
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
    // Unblocks a fetch still awaiting the gate, or its continuation stays suspended forever.
    _completeCanApplyData();
    _filterDrawer.dispose();
    super.dispose();
  }

  void _completeCanApplyData() {
    if (_canApplyData.isCompleted) return;
    _canApplyData.complete();
  }

  void handleTagTap(String tagName) {
    // The search endpoint accepts a raw tag name too; without the fallback the chip is dead.
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
        _auth,
        _filterDrawer,
      ]),
      builder: (context, _) {
        return SeriesDetailScaffold(
          state: this,
          filterDrawer: _filterDrawer,
          entryStream: _entryStream,
          embedded: widget.embedded,
          rightRail: widget.rightRail,
          isAdding: _isAdding,
          onRetry: _retryFetch,
          onTabChanged: _onTabChanged,
          onAuthorTap: _navigateToAuthorSeries,
          onPublisherTap: _navigateToPublisherSeries,
          onSearch: executeSearchWithFilters,
          onAdd: addSeriesToLibrary,
        );
      },
    );
  }
}

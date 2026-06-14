import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/shared/widgets/app_shortcuts.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_app_bar.dart';

import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_manager.dart';
import 'package:mangabaka_app/features/series/widgets/layouts/series_detail_mobile_layout.dart';
import 'package:mangabaka_app/features/series/widgets/layouts/series_detail_wide_layout.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_error_banner.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_fab.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_tab_content.dart';
import 'package:mangabaka_app/features/series/mixins/series_detail_actions_mixin.dart';
import 'package:mangabaka_app/features/series/mixins/series_detail_data_mixin.dart';


import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';

class SeriesDetailScreen extends StatefulWidget {
  final Series series;

  const SeriesDetailScreen({super.key, required this.series});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> with SeriesDetailActionsMixin, SeriesDetailDataMixin {
  static final _logger = LoggingService.logger;
  late final LibraryService _libraryService;
  late final SeriesService _seriesService;
  Stream<LibraryEntry?>? _entryStream;
  bool _isAdding = false;
  bool _routeAnimationListenerAdded = false;
  bool _routeTransitionComplete = false;
  bool _fetchStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routeAnimationListenerAdded) {
      final route = ModalRoute.of(context);
      if (route != null) {
        _routeAnimationListenerAdded = true;
        final animation = route.animation;
        if (animation != null) {
          if (animation.isCompleted) {
            _routeTransitionComplete = true;
            _startFetch();
          } else {
            animation.addStatusListener(_onRouteAnimationStatusChanged);
          }
        } else {
          _routeTransitionComplete = true;
          _startFetch();
        }
      }
    }
  }

  void _onRouteAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (mounted) {
        setState(() {
          _routeTransitionComplete = true;
        });
        _startFetch();
      }
      final route = ModalRoute.of(context);
      route?.animation?.removeStatusListener(_onRouteAnimationStatusChanged);
    }
  }

  void _startFetch() {
    if (_fetchStarted) return;
    _fetchStarted = true;
    _logger.fine('Starting full data fetch for series: ${widget.series.id}');
    fetchFullData().then((_) {
      _logger.info('Full data fetch complete for series: ${widget.series.id}');
    }).catchError((e) {
      _logger.severe('Full data fetch failed for series: ${widget.series.id}. Error: $e');
    });
  }

  @override
  void dispose() {
    if (_routeAnimationListenerAdded) {
      final route = ModalRoute.of(context);
      route?.animation?.removeStatusListener(_onRouteAnimationStatusChanged);
    }
    super.dispose();
  }

  @override
  LibraryService get libraryService => _libraryService;

  @override
  Series get series => widget.series;

  @override
  bool get isAdding => _isAdding;

  @override
  set isAdding(bool value) => _isAdding = value;

  String _selectedTab = 'Info';

  @override
  SeriesService get seriesService => _seriesService;

  @override
  String get selectedTab => _selectedTab;

  @override
  void initState() {
    super.initState();
    _logger.info('Series detail screen initialized for series: ${widget.series.title} (${widget.series.id})');
    _libraryService = getIt<LibraryService>();
    _seriesService = getIt<SeriesService>();
    _entryStream = _libraryService.watchEntryFromDb(widget.series.id);
    fullSeries = widget.series; 
  }

  void _navigateToAuthorSeries(String authorName) {
    _logger.info('Navigating to series by author: $authorName');
    Navigator.push(
      context,
      AppTransitions.slideRight(BrowseResultsScreen(
        sortType: authorName,
        sortBy: 'popularity_desc',
        staff: authorName,
      )),
    );
  }

  void _navigateToPublisherSeries(String publisherName) {
    _logger.info('Navigating to series by publisher: $publisherName');
    Navigator.push(
      context,
      AppTransitions.slideRight(BrowseResultsScreen(
        sortType: publisherName,
        sortBy: 'popularity_desc',
        publisher: publisherName,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsManager();
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;
    final displayLoaded = isDataLoaded && _routeTransitionComplete;

    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), ThemeManager(), getIt<ProfileAuthService>()]),
      builder: (context, _) {
        final l10n = LocalizationService();
        return Scaffold(
          backgroundColor: AppConstants.primaryBackground,
          body: Actions(
            actions: <Type, Action<Intent>>{
              RefreshIntent: CallbackAction<RefreshIntent>(
                onInvoke: (intent) {
                  setState(() {
                    isDataLoaded = false;
                    fetchError = false;
                  });
                  fetchFullData();
                  return null;
                },
              ),
            },
            child: StreamBuilder<LibraryEntry?>(
              stream: _entryStream,
              builder: (context, snapshot) {
                final entry = snapshot.data;
                return RepaintBoundary(
                  child: CustomScrollView(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      slivers: [
                        SeriesDetailAppBar(
                          series: fullSeries ?? widget.series,
                          title: (fullSeries ?? widget.series).getDisplayTitle(settings.defaultTitleLanguage),
                          entry: entry,
                          isWide: isWide || isTablet,
                          horizontalPadding: isWide ? 40.0 : 16.0,
                          onBack: () => Navigator.pop(context),
                          onShare: shareLink,
                          onDelete: showDeleteConfirmationDialog,
                          onCopy: copyToClipboard,
                        ),
                        if (fetchError)
                          SeriesDetailErrorBanner(onRetry: () {
                            setState(() {
                              isDataLoaded = false;
                              fetchError = false;
                            });
                            fetchFullData();
                          }),
                        SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1400),
                              child: isWide 
                                ? SeriesDetailWideLayout(
                                  series: fullSeries ?? widget.series,
                                  title: (fullSeries ?? widget.series).getDisplayTitle(settings.defaultTitleLanguage),
                                  entry: entry,
                                  l10n: l10n,
                                  isDataLoaded: displayLoaded,
                                  selectedTab: _selectedTab,
                                  onAuthorTap: _navigateToAuthorSeries,
                                  onPublisherTap: _navigateToPublisherSeries,
                                  onTabChanged: (tab) {
                                    _logger.info('Series detail tab switched to: $tab');
                                    setState(() => _selectedTab = tab);
                                    fetchTabData(tab);
                                  },
                                  onStateChanged: (s) => _libraryService.updateLibraryEntryState((fullSeries ?? widget.series).id, s),
                                  onRatingChanged: (r) => _libraryService.updateLibraryEntryRating((fullSeries ?? widget.series).id, r),
                                  onUpdateChapter: () => entry != null ? showUpdateProgressDialog(entry, isChapter: true) : null,
                                  onUpdateVolume: () => entry != null ? showUpdateProgressDialog(entry, isChapter: false) : null,
                                  onUpdateRating: () => entry != null ? showUpdateRatingDialog(entry) : null,
                                  buildTabContent: (hPadding, {isWide = false, wideRightPaddingOnly = false}) => SeriesDetailTabContent(
                                    series: fullSeries ?? widget.series,
                                    entry: entry,
                                    l10n: l10n,
                                    selectedTab: _selectedTab,
                                    covers: covers,
                                    related: related,
                                    similar: similar,
                                    news: news,
                                    collections: collections,
                                    works: works,
                                    enrichedLinks: enrichedLinks,
                                    isWide: isWide,
                                    hPadding: hPadding,
                                    wideRightPaddingOnly: wideRightPaddingOnly,
                                    onAuthorTap: _navigateToAuthorSeries,
                                    onPublisherTap: _navigateToPublisherSeries,
                                  ),
                                )
                                : SeriesDetailMobileLayout(
                                  series: fullSeries ?? widget.series,
                                  title: (fullSeries ?? widget.series).getDisplayTitle(settings.defaultTitleLanguage),
                                  entry: entry,
                                  l10n: l10n,
                                  isDataLoaded: displayLoaded,
                                  selectedTab: _selectedTab,
                                  onTabChanged: (tab) {
                                    _logger.info('Series detail tab switched to: $tab');
                                    setState(() => _selectedTab = tab);
                                    fetchTabData(tab);
                                  },
                                  onStateChanged: (s) => _libraryService.updateLibraryEntryState((fullSeries ?? widget.series).id, s),
                                  onRatingChanged: (r) => _libraryService.updateLibraryEntryRating((fullSeries ?? widget.series).id, r),
                                  onUpdateChapter: () => entry != null ? showUpdateProgressDialog(entry, isChapter: true) : null,
                                  onUpdateVolume: () => entry != null ? showUpdateProgressDialog(entry, isChapter: false) : null,
                                  onUpdateRating: () => entry != null ? showUpdateRatingDialog(entry) : null,
                                  buildTabContent: (hPadding) => SeriesDetailTabContent(
                                    series: fullSeries ?? widget.series,
                                    entry: entry,
                                    l10n: l10n,
                                    selectedTab: _selectedTab,
                                    covers: covers,
                                    related: related,
                                    similar: similar,
                                    news: news,
                                    collections: collections,
                                    works: works,
                                    enrichedLinks: enrichedLinks,
                                    hPadding: hPadding,
                                    onAuthorTap: _navigateToAuthorSeries,
                                    onPublisherTap: _navigateToPublisherSeries,
                                  ),
                                ),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 80)),
                      ],
                    ),
                  );
              },
            ),
          ),
          floatingActionButton: SeriesDetailFAB(entryStream: _entryStream, isAdding: _isAdding, onAdd: addSeriesToLibrary),
        );
      },
    );
  }

}


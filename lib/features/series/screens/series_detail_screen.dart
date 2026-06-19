import 'dart:ui' show PathMetric;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/shared/widgets/app_shortcuts.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_sort_section.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_categories_section.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_type_status_section.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_details_section.dart';
import 'package:mangabaka_app/features/browse/screens/browse_screen.dart';
import 'package:mangabaka_app/features/navigation/screens/main_screen.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';

class SeriesDetailScreen extends StatefulWidget {
  final Series series;
  final String? heroTagPrefix;

  const SeriesDetailScreen({
    super.key,
    required this.series,
    this.heroTagPrefix,
  });

  static SeriesDetailScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<SeriesDetailScreenState>();

  @override
  State<SeriesDetailScreen> createState() => SeriesDetailScreenState();
}

class SeriesDetailScreenState extends State<SeriesDetailScreen> with TickerProviderStateMixin, SeriesDetailActionsMixin, SeriesDetailDataMixin {
  static final _logger = LoggingService.logger;
  late final LibraryService _libraryService;
  late final SeriesService _seriesService;
  Stream<LibraryEntry?>? _entryStream;
  bool _isAdding = false;

  SearchFilters? _drawerFilters;
  SearchFilters? get drawerFilters => _drawerFilters;

  late final SeriesSearchService _searchService;
  List<Map<String, dynamic>> _genres = [];
  List<Map<String, dynamic>> _tags = [];
  bool _isLoadingMetadata = false;

  final List<String> _types = ['manga', 'manhwa', 'manhua', 'novel', 'oel'];
  final List<String> _statuses = [
    'ongoing',
    'releasing',
    'completed',
    'hiatus',
    'cancelled',
  ];

  late final AnimationController _filterAnimationController;
  late final AnimationController _marchingAntsController;
  late final Animation<Offset> _drawerSlideAnimation;

  void _updateFilters(SearchFilters Function(SearchFilters? current) updateFn) {
    final wasNull = _drawerFilters == null;
    final newFilters = updateFn(_drawerFilters);
    setState(() {
      _drawerFilters = newFilters;
    });
    if (wasNull) {
      _filterAnimationController.forward();
      _marchingAntsController.repeat();
    }
  }

  void _hideFilterMode() {
    _marchingAntsController.stop();
    _filterAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _drawerFilters = null;
        });
      }
    });
  }

  String? _getTagIdByName(String name) {
    try {
      final tagItem = _tags.firstWhere(
        (t) => t['name']?.toString().toLowerCase() == name.toLowerCase(),
      );
      return tagItem['id']?.toString();
    } catch (_) {
      try {
        final metadata = getIt<MetadataService>();
        return metadata.getTagId(name);
      } catch (_) {
        return null;
      }
    }
  }

  void handleTagTap(String tagName) {
    final tagId = _getTagIdByName(tagName) ?? tagName;
    _executeTagSearch([tagId]);
  }

  void handleTagLongPress(String tagName) {
    HapticFeedback.lightImpact();
    final tagId = _getTagIdByName(tagName);
    if (tagId == null) return;

    _updateFilters((current) {
      if (current == null) {
        return SearchFilters(tag: [tagId]);
      } else {
        final currentTags = List<String>.from(current.tag);
        if (currentTags.contains(tagId)) {
          currentTags.remove(tagId);
        } else {
          currentTags.add(tagId);
        }
        return current.copyWith(tag: currentTags);
      }
    });
  }

  void handleGenreTap(String genreKey) {
    _executeGenreSearch(genreKey);
  }

  void handleGenreLongPress(String genreKey) {
    HapticFeedback.lightImpact();
    _updateFilters((current) {
      if (current == null) {
        return SearchFilters(genre: [genreKey]);
      } else {
        final currentGenres = List<String>.from(current.genre);
        if (currentGenres.contains(genreKey)) {
          currentGenres.remove(genreKey);
        } else {
          currentGenres.add(genreKey);
        }
        return current.copyWith(genre: currentGenres);
      }
    });
  }

  void handleTypeToggle(String typeKey) {
    HapticFeedback.lightImpact();
    _updateFilters((current) {
      if (current == null) {
        return SearchFilters(type: [typeKey]);
      } else {
        final currentTypes = List<String>.from(current.type);
        if (currentTypes.contains(typeKey)) {
          currentTypes.remove(typeKey);
        } else {
          currentTypes.add(typeKey);
        }
        return current.copyWith(type: currentTypes);
      }
    });
  }

  void handleStatusToggle(String statusKey) {
    HapticFeedback.lightImpact();
    _updateFilters((current) {
      if (current == null) {
        return SearchFilters(status: [statusKey]);
      } else {
        final currentStatuses = List<String>.from(current.status);
        if (currentStatuses.contains(statusKey)) {
          currentStatuses.remove(statusKey);
        } else {
          currentStatuses.add(statusKey);
        }
        return current.copyWith(status: currentStatuses);
      }
    });
  }

  void handleStaffToggle(String staffName) {
    HapticFeedback.lightImpact();
    _updateFilters((current) {
      if (current == null) {
        return SearchFilters(staff: [staffName]);
      } else {
        final currentStaff = List<String>.from(current.staff);
        if (currentStaff.contains(staffName)) {
          currentStaff.remove(staffName);
        } else {
          currentStaff.add(staffName);
        }
        return current.copyWith(staff: currentStaff);
      }
    });
  }

  void handlePublisherToggle(String publisherName) {
    HapticFeedback.lightImpact();
    _updateFilters((current) {
      if (current == null) {
        return SearchFilters(publisher: [publisherName]);
      } else {
        final currentPublishers = List<String>.from(current.publisher);
        if (currentPublishers.contains(publisherName)) {
          currentPublishers.remove(publisherName);
        } else {
          currentPublishers.add(publisherName);
        }
        return current.copyWith(publisher: currentPublishers);
      }
    });
  }

  void handleYearToggle(int year) {
    HapticFeedback.lightImpact();
    _updateFilters((current) {
      if (current == null) {
        return SearchFilters(
          publishedYearLower: year,
          publishedYearUpper: year,
        );
      } else {
        if (current.publishedYearLower == year &&
            current.publishedYearUpper == year) {
          return current.copyWithYear(
            publishedYearLower: null,
            publishedYearUpper: null,
          );
        } else {
          return current.copyWithYear(
            publishedYearLower: year,
            publishedYearUpper: year,
          );
        }
      }
    });
  }

  void _executeTagSearch(List<String> tagIds) {
    final browseState = BrowseScreen.browseScreenKey.currentState;
    if (browseState != null) {
      browseState.controller.startTagSearch(tagIds);
    }
    MainScreen.setTabIndex(2);
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _executeGenreSearch(String genreKey) {
    final browseState = BrowseScreen.browseScreenKey.currentState;
    if (browseState != null) {
      browseState.controller.startGenreSearch(genreKey);
    }
    MainScreen.setTabIndex(2);
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void executeSearchWithFilters(SearchFilters filters) {
    final browseState = BrowseScreen.browseScreenKey.currentState;
    if (browseState != null) {
      browseState.controller.startSearchWithFilters(filters);
    }
    MainScreen.setTabIndex(2);
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Map<String, String> _getSortOptions(LocalizationService l10n) {
    return {
      'name_asc': l10n.translate('title_asc'),
      'name_desc': l10n.translate('title_desc'),
      'popularity_asc': l10n.translate('popularity_asc'),
      'popularity_desc': l10n.translate('popularity_desc'),
      'score_desc': l10n.translate('rating_desc'),
      'score_asc': l10n.translate('rating_asc'),
      'chapters_desc': l10n.translate('chapters_desc'),
      'chapters_asc': l10n.translate('chapters_asc'),
      'random': l10n.translate('random_sort'),
    };
  }

  Future<void> _loadMetadata() async {
    _isLoadingMetadata = true;
    try {
      final results = await Future.wait([
        _searchService.getGenres(),
        _searchService.getTags(),
      ]);
      if (mounted) {
        setState(() {
          _genres = results[0];
          _tags = results[1];
          _isLoadingMetadata = false;
        });
      }
    } catch (e) {
      _logger.warning('Failed to load metadata in details screen: $e');
      if (mounted) {
        setState(() {
          _isLoadingMetadata = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    _marchingAntsController.dispose();
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
    _searchService = getIt<SeriesSearchService>();
    _entryStream = _libraryService.watchEntryFromDb(widget.series.id);
    fullSeries = widget.series; 
    _loadMetadata(); 

    _filterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _marchingAntsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _drawerSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    // Start fetching immediately — don't wait for route animation to complete.
    // This allows data to arrive during or right after the transition,
    // eliminating unnecessary skeleton display time.
    fetchFullData().then((_) {
      _logger.info('Full data fetch complete for series: ${widget.series.id}');
    }).catchError((e) {
      _logger.severe('Full data fetch failed for series: ${widget.series.id}. Error: $e');
    });
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
    final displayLoaded = isDataLoaded;

    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), ThemeManager(), getIt<ProfileAuthService>()]),
      builder: (context, _) {
        final l10n = LocalizationService();
        return PopScope(
          canPop: _drawerFilters == null,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_drawerFilters != null) {
              _hideFilterMode();
            }
          },
          child: Scaffold(
            backgroundColor: AppConstants.primaryBackground,
            body: Stack(
              children: [
                Positioned.fill(
                  child: Actions(
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
                                heroTagPrefix: widget.heroTagPrefix,
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
                                        onAuthorTap: _navigateToAuthorSeries,
                                        onPublisherTap: _navigateToPublisherSeries,
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
                ),
                if (_drawerFilters != null) ...[
                  Positioned.fill(
                    child: IgnorePointer(
                      child: FadeTransition(
                        opacity: _filterAnimationController,
                        child: AnimatedBuilder(
                          animation: _marchingAntsController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: DottedBorderPainter(
                                color: AppConstants.accentColor,
                                strokeWidth: 3,
                                gap: 6,
                                phase: _marchingAntsController.value * 24.0,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: SlideTransition(
                      position: _drawerSlideAnimation,
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _filterAnimationController,
                          curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
                        ),
                        child: _buildFilterDrawer(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            floatingActionButton: SeriesDetailFAB(entryStream: _entryStream, isAdding: _isAdding, onAdd: addSeriesToLibrary),
          ),
        );
      },
    );
  }

  Widget _buildFilterDrawer(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final screenHeight = mediaQuery.size.height;
    
    // Header is ~80px. We want header + bottom navigation spacing.
    final minHeight = 84.0 + bottomPadding;
    final minChildSize = screenHeight > 0 ? (minHeight / screenHeight).clamp(0.05, 0.9) : 0.12;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: minChildSize,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: [minChildSize, 0.5, 0.85],
      shouldCloseOnMinExtent: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppConstants.primaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
            border: Border(
              top: BorderSide(
                color: AppConstants.borderColor.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              _buildDrawerHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: _buildDrawerFilterContent(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final l10n = LocalizationService();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: AppConstants.borderColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _hideFilterMode,
                child: Text(
                  l10n.translate('reset').toUpperCase(),
                  style: TextStyle(
                    color: AppConstants.textMutedColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                _drawerFilters != null && _drawerFilters!.activeFiltersCount > 0
                    ? '${l10n.translate('filters')} (${_drawerFilters!.activeFiltersCount})'
                    : l10n.translate('filters'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  if (_drawerFilters != null) {
                    executeSearchWithFilters(_drawerFilters!);
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor:
                      AppConstants.accentColor.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  l10n.translate('search').toUpperCase(),
                  style: TextStyle(
                    color: AppConstants.accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerFilterContent(BuildContext context) {
    final l10n = LocalizationService();
    final sortOptions = _getSortOptions(l10n);

    if (_genres.isEmpty && _tags.isEmpty && _isLoadingMetadata) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SearchFilterSortSection(
          filters: _drawerFilters!,
          onFiltersChanged: (newFilters) => setState(() => _drawerFilters = newFilters),
          l10n: l10n,
          sortOptions: sortOptions,
        ),
        const SizedBox(height: 8),
        SearchFilterCategoriesSection(
          filters: _drawerFilters!,
          onFiltersChanged: (newFilters) => setState(() => _drawerFilters = newFilters),
          l10n: l10n,
          genres: _genres,
          tags: _tags,
        ),
        const SizedBox(height: 8),
        SearchFilterTypeStatusSection(
          filters: _drawerFilters!,
          onFiltersChanged: (newFilters) => setState(() => _drawerFilters = newFilters),
          l10n: l10n,
          types: _types,
          statuses: _statuses,
        ),
        const SizedBox(height: 8),
        SearchFilterDetailsSection(
          filters: _drawerFilters!,
          onFiltersChanged: (newFilters) => setState(() => _drawerFilters = newFilters),
          l10n: l10n,
        ),
        SizedBox(height: 32 + MediaQuery.of(context).padding.bottom),
      ],
    );
  }

}

class DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double phase;

  DottedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.gap = 4.0,
    this.phase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRect(Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ));

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = phase % (gap * 3);
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? gap * 2 : gap;
        if (draw) {
          canvas.drawPath(
            metric.extractPath(distance, distance + len),
            paint,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DottedBorderPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gap != gap;
}


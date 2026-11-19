import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/publisher/utils/publisher_sort.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/screens/browse/desktop_browse_landing.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_filter_panel.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_list_controls.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/browse/controllers/browse_controller.dart';
import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';
import 'package:mangabaka_app/features/browse/screens/mix_screen.dart';
import 'package:mangabaka_app/features/home/screens/discovery_queue_screen.dart';
import 'package:mangabaka_app/features/browse/utils/browse_helpers.dart';
import 'package:mangabaka_app/features/browse/widgets/results/browse_content.dart';
import 'package:mangabaka_app/features/browse/widgets/search/mb_search_bar.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/features/series/services/series_list_deps.dart';

import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

part 'desktop_browse_controls_part.dart';

class DesktopBrowseScreen extends StatefulWidget {
  static final GlobalKey<DesktopBrowseScreenState> stateKey =
      GlobalKey<DesktopBrowseScreenState>();

  const DesktopBrowseScreen({super.key});

  @override
  State<DesktopBrowseScreen> createState() => DesktopBrowseScreenState();
}

class DesktopBrowseScreenState extends State<DesktopBrowseScreen>
    implements DesktopRefreshable {
  static final _logger = LoggingService.logger;

  late final BrowseController _controller;
  late final SeriesListDeps _listDeps = SeriesListDeps.fromLocator();
  final FocusNode _searchFocus = FocusNode();

  /// Seeded by `BrowseNavigation` when a chip elsewhere starts a search.
  BrowseController get controller => _controller;

  void focusSearch() => _searchFocus.requestFocus();

  @override
  Future<void> refresh() => _controller.searchSeries();

  @override
  void initState() {
    super.initState();
    _controller = BrowseController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openDetail(Series series) {
    _logger.info('Opening series ${series.id} from desktop browse');
    Navigator.of(
      context,
    ).push(AppTransitions.slideUp(SeriesDetailScreen(series: series)));
  }

  void _openResults(
    String header,
    String sortBy, {
    String? type,
    String? staff,
    String? publisher,
  }) {
    Navigator.of(context).push(
      AppTransitions.slideRight(
        BrowseResultsScreen(
          sortType: header,
          sortBy: sortBy,
          type: type,
          staff: staff,
          publisher: publisher,
          randomSeed: sortBy == 'random'
              ? BrowseController.generateRandomSeed()
              : null,
        ),
      ),
    );
  }

  void _openMix() =>
      Navigator.of(context).push(AppTransitions.slideRight(const MixScreen()));

  void _openDiscoveryQueue() => Navigator.of(
    context,
  ).push(AppTransitions.slideRight(const DiscoveryQueueScreen()));

  void _onResultSelected(AutocompleteSeriesResult result) =>
      _openDetail(BrowseHelpers.convertAutocompleteToSeries(result));

  void _clearSearch() {
    _controller.searchController.clear();
    _controller.updateSearchQuery('');
    _controller.updateFilters(SearchFilters());
    _controller.resetSearchState();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LocalizationService(),
        SettingsManager(),
        _controller,
      ]),
      builder: (context, _) {
        final l10n = LocalizationService();
        final isSeries = _controller.currentType == BrowseType.series;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isSeries)
              DesktopSidePanel(
                child: DesktopFilterPanel(
                  filters: _controller.currentFilters,
                  onChanged: _controller.updateFilters,
                  searchService: getIt<SeriesSearchService>(),
                  metadata: getIt<MetadataService>(),
                ),
              ),
            Expanded(
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: (_) {
                  _controller.checkScroll();
                  return false;
                },
                child: Stack(
                  children: [
                    Positioned.fill(child: _main(l10n)),
                    if (_controller.showBackToTop)
                      Positioned(
                        right: 28,
                        bottom: 28,
                        child: FloatingActionButton.small(
                          heroTag: 'desktop_browse_top',
                          tooltip: l10n.translate('back_to_top'),
                          backgroundColor: context.colors.accent,
                          onPressed: _controller.scrollToTop,
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            color: context.colors.onAccent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _main(LocalizationService l10n) {
    final c = _controller;
    final searching = c.isSearchMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DesktopBrowseHeader(
          controller: c,
          searchFocus: _searchFocus,
          l10n: l10n,
          searching: searching,
          onResultSelected: _onResultSelected,
          onClearSearch: _clearSearch,
          prefetch: _listDeps.prefetch,
        ),
        _DesktopBrowseControlsBar(
          controller: c,
          l10n: l10n,
          searching: searching,
        ),
        if (!searching)
          Expanded(
            child: DesktopBrowseLanding(
              onNavigate: _openResults,
              onMix: _openMix,
              onDiscoveryQueue: _openDiscoveryQueue,
            ),
          )
        else
          _padded(
            BrowseContent(
              searchResults: c.searchResults,
              browseType: c.currentType,
              isLoading: c.isLoading,
              isLoadingMore: c.isLoadingMore,
              scrollController: c.scrollController,
              error: c.error,
              onRetry: c.searchSeries,
              onNavigateToDetail: _openDetail,
              onNavigateToResults: _openResults,
              onNavigateToMix: _openMix,
              onNavigateToDiscoveryQueue: _openDiscoveryQueue,
              deps: _listDeps,
            ),
          ),
      ],
    );
  }

  /// [content]'s build returns an [Expanded], so it needs a column of its own to expand in.
  Widget _padded(Widget content) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesktopTokens.pagePadding - 12,
        ),
        child: Column(children: [content]),
      ),
    );
  }
}

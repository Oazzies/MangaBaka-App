import 'package:flutter/material.dart';
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
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Browse on desktop: filters in a permanent left panel, the search field and
/// result controls across the top, and results filling the rest.
///
/// Built on the same [BrowseController] as the phone screen — only the
/// arrangement differs. Every filter change applies immediately.
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
  final FocusNode _searchFocus = FocusNode();

  /// The controller `BrowseNavigation` seeds when a chip elsewhere starts a
  /// search.
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

  // ─── Navigation ──────────────────────────────────────────────────────────

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

  // ─── Build ───────────────────────────────────────────────────────────────

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
            DesktopSidePanel(
              child: DesktopFilterPanel(
                filters: _controller.currentFilters,
                onChanged: _controller.updateFilters,
                enabled: isSeries,
                disabledMessage: l10n.translate('filters_series_only'),
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
        Padding(
          padding: EdgeInsets.fromLTRB(
            DesktopTokens.pagePadding,
            10,
            DesktopLayout.isDesktopPlatform
                ? DesktopTokens.windowControlsClearance
                : DesktopTokens.pagePadding,
            0,
          ),
          child: DerivedLayoutBuilder<bool>(
            derive: (constraints) => constraints.maxWidth < 620,
            builder: (context, narrow) {
              final searchBar = ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: MBSearchBar(
                  focusNode: _searchFocus,
                  controller: c.searchController,
                  initialFilters: c.currentFilters,
                  showFilterButton: false,
                  suggestionsAllowed: c.currentType == BrowseType.series,
                  onResultSelected: _onResultSelected,
                  onChanged: c.updateSearchQuery,
                  onSubmitted: (_) => c.searchSeries(),
                ),
              );

              final clearButton = searching
                  ? DesktopPillButton(
                      label: l10n.translate('clear_all'),
                      icon: Icons.close_rounded,
                      onPressed: _clearSearch,
                    )
                  : null;

              final titleText = Text(
                l10n.translate('browse').toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.display(
                  color: context.colors.text,
                  fontSize: 30,
                ),
              );

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: titleText),
                        if (clearButton != null) clearButton,
                      ],
                    ),
                    const SizedBox(height: 12),
                    searchBar,
                  ],
                );
              }

              return Row(
                children: [
                  titleText,
                  const SizedBox(width: 28),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: searchBar,
                    ),
                  ),
                  if (clearButton != null) ...[
                    const SizedBox(width: 12),
                    clearButton,
                  ],
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesktopTokens.pagePadding,
            18,
            DesktopTokens.pagePadding,
            10,
          ),
          child: Builder(
            builder: (context) {
              final leftControls = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (c.currentFilters.isEmpty)
                    DesktopSegmented<BrowseType>(
                      value: c.currentType,
                      segments: [
                        (BrowseType.series, l10n.translate('series'), null),
                        (
                          BrowseType.publishers,
                          l10n.translate('publishers'),
                          null,
                        ),
                        (BrowseType.staff, l10n.translate('staff'), null),
                      ],
                      onChanged: c.setType,
                    ),
                  if (searching && c.totalResults > 0) ...[
                    const SizedBox(width: 16),
                    Text(
                      '${c.totalResults}${c.isTotalCapped ? '+' : ''} '
                      '${l10n.translate(c.currentType.name)}',
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              );

              final rightControls = c.currentType == BrowseType.series
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DesktopSortMenu(
                          filters: c.currentFilters,
                          onChanged: c.updateFilters,
                        ),
                        const SizedBox(width: 10),
                        const DesktopListStyleToggle(
                          scope: DesktopListScope.browse,
                        ),
                      ],
                    )
                  : null;

              if (rightControls == null) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: leftControls,
                );
              }

              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 10,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: leftControls,
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: rightControls,
                  ),
                ],
              );
            },
          ),
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
          // BrowseContent is itself an Expanded.
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
            ),
          ),
      ],
    );
  }

  /// Insets [content] — whose build returns an [Expanded] — horizontally,
  /// giving it a column of its own to expand in.
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

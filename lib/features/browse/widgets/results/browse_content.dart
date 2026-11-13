import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/core/widgets/dynamic_row_height_grid.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_series_row.dart';
import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/features/browse/widgets/results/browse_people_results.dart';
import 'package:mangabaka_app/features/browse/widgets/shortcuts/browse_shortcuts.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';
import 'package:mangabaka_app/features/series/widgets/series_list_skeleton.dart';

class BrowseContent extends StatelessWidget {
  final List<dynamic> searchResults;
  final BrowseType browseType;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final ScrollController scrollController;
  final VoidCallback onRetry;
  final Function(Series) onNavigateToDetail;
  final Function(
    String,
    String, {
    String? type,
    String? staff,
    String? publisher,
  })
  onNavigateToResults;
  final VoidCallback onNavigateToMix;
  final VoidCallback onNavigateToDiscoveryQueue;

  /// Side inset of the grid layouts: 12 to match the Library when the parent
  /// adds none, 0 when the parent already insets its content.
  final double horizontalInset;

  const BrowseContent({
    super.key,
    required this.searchResults,
    required this.browseType,
    required this.isLoading,
    required this.isLoadingMore,
    required this.error,
    required this.scrollController,
    required this.onRetry,
    required this.onNavigateToDetail,
    required this.onNavigateToResults,
    required this.onNavigateToMix,
    required this.onNavigateToDiscoveryQueue,
    this.horizontalInset = 12,
  });

  EdgeInsets get _gridPadding =>
      EdgeInsets.symmetric(horizontal: horizontalInset, vertical: 12);

  Widget _buildLoadingState() {
    if (browseType == BrowseType.series) {
      final settings = SettingsManager();
      final activeStyle = settings.resolvedBrowseListStyle;
      final isGrid = activeStyle.isGrid;

      return SeriesListSkeleton(
        isGrid: isGrid,
        horizontalPadding: horizontalInset,
      );
    }

    return const Center(child: MbSpinner());
  }

  Widget _buildErrorState(BuildContext context, LocalizationService l10n) =>
      BrowseErrorState(error: error, l10n: l10n, onRetry: onRetry);

  Widget _buildResultsList(LocalizationService l10n) {
    return switch (browseType) {
      BrowseType.series => _buildSeriesResults(l10n),
      BrowseType.publishers => _buildPublisherResults(),
      BrowseType.staff => _buildStaffResults(),
      _ => Center(child: Text(l10n.translate('no_results'))),
    };
  }

  /// Builds a single tappable series item with hover-prefetch for desktop.
  Widget _buildSeriesItem(Series series, {required AppListStyle activeStyle}) {
    final seriesService = getIt<SeriesService>();
    return MouseRegion(
      onEnter: (_) => seriesService.fetchSeries(series.id),
      child: InkWell(
        onTap: () => onNavigateToDetail(series),
        child: EntryListItem(
          key: ValueKey('${activeStyle.name}_${series.id}'),
          series: series,
          listStyle: activeStyle,
        ),
      ),
    );
  }

  Widget _buildSeriesResults(LocalizationService l10n) {
    return ListenableBuilder(
      listenable: Listenable.merge([SettingsManager(), l10n]),
      builder: (context, _) {
        final settings = SettingsManager();
        final activeStyle = settings.resolvedBrowseListStyle;
        final isGrid = activeStyle.isGrid;
        final itemCount = searchResults.length + (isLoadingMore ? 1 : 0);

        if (isGrid) {
          final columns = settings.resolvedBrowseGridColumnCount;
          final isCompactGrid = activeStyle == AppListStyle.compactGrid;

          Widget buildGridContent(BuildContext context, int calculatedColumns) {
            if (isCompactGrid) {
              return DynamicRowHeightGrid(
                controller: scrollController,
                padding: _gridPadding,
                crossAxisCount: calculatedColumns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index >= searchResults.length) {
                    if (isLoadingMore && index == searchResults.length) {
                      return const Center(child: MbSpinner());
                    }
                    return const SizedBox.shrink();
                  }
                  return _buildSeriesItem(
                    searchResults[index] as Series,
                    activeStyle: activeStyle,
                  );
                },
              );
            }

            return GridView.builder(
              controller: scrollController,
              padding: _gridPadding,
              gridDelegate: columns > 0
                  ? SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      childAspectRatio: activeStyle.childAspectRatio,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    )
                  : SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 160,
                      childAspectRatio: activeStyle.childAspectRatio,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (index >= searchResults.length) {
                  if (isLoadingMore && index == searchResults.length) {
                    return const Center(child: MbSpinner());
                  }
                  return const SizedBox.shrink();
                }
                return _buildSeriesItem(
                  searchResults[index] as Series,
                  activeStyle: activeStyle,
                );
              },
            );
          }

          if (columns == 0) {
            // Rebuilt only when the column count changes; between those a
            // resize just re-lays the grid out.
            return DerivedLayoutBuilder<int>(
              derive: (constraints) =>
                  ((constraints.maxWidth + 10) / 170).ceil().clamp(1, 12),
              builder: buildGridContent,
            );
          }
          final expectedWidth =
              columns * 160.0 + (columns - 1) * 10.0 + horizontalInset * 2;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: expectedWidth),
              child: buildGridContent(context, columns),
            ),
          );
        }

        final list = ListView.builder(
          controller: scrollController,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index >= searchResults.length) {
              if (isLoadingMore && index == searchResults.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: MbSpinner()),
                );
              }
              return const SizedBox.shrink();
            }
            return _buildSeriesItem(
              searchResults[index] as Series,
              activeStyle: activeStyle,
            );
          },
        );

        // On desktop the list styles are tables, so they get column labels.
        if (!DesktopLayout.isActive(context)) return list;
        return Column(
          children: [
            DesktopSeriesListHeader(style: activeStyle),
            Expanded(child: list),
          ],
        );
      },
    );
  }

  Widget _buildPublisherResults() => BrowsePeopleResults(
    searchResults: searchResults,
    browseType: BrowseType.publishers,
    isLoadingMore: isLoadingMore,
    scrollController: scrollController,
    onNavigateToResults: onNavigateToResults,
  );

  Widget _buildStaffResults() => BrowsePeopleResults(
    searchResults: searchResults,
    browseType: BrowseType.staff,
    isLoadingMore: isLoadingMore,
    scrollController: scrollController,
    onNavigateToResults: onNavigateToResults,
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        final l10n = LocalizationService();

        Widget content;
        if (searchResults.isEmpty && !isLoading && error == null) {
          if (browseType == BrowseType.series) {
            content = BrowseShortcuts(
              key: const ValueKey('shortcuts'),
              onNavigate: onNavigateToResults,
              onMix: onNavigateToMix,
              onDiscoveryQueue: onNavigateToDiscoveryQueue,
            );
          } else {
            content = BrowseEmptyPrompt(
              browseType: browseType,
              l10n: l10n,
            );
          }
        } else if (isLoading && searchResults.isEmpty) {
          content = _buildLoadingState();
        } else if (error != null && searchResults.isEmpty) {
          content = _buildErrorState(context, l10n);
        } else if (searchResults.isNotEmpty) {
          content = _buildResultsList(l10n);
        } else {
          content = const SizedBox.shrink(key: ValueKey('empty'));
        }

        return Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: content,
          ),
        );
      },
    );
  }
}

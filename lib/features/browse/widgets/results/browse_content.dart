import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';
import 'package:mangabaka_app/features/browse/widgets/shortcuts/browse_shortcuts.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/widgets/series_list_skeleton.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/widgets/dynamic_row_height_grid.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_series_row.dart';

import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_list_item.dart';
import 'package:mangabaka_app/features/collections/screens/collections_browse_screen.dart';
import 'package:mangabaka_app/features/staff/models/staff.dart';
import 'package:mangabaka_app/features/staff/widgets/staff_list_item.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

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
  });

  Widget _buildLoadingState() {
    if (browseType == BrowseType.series) {
      final settings = SettingsManager();
      final activeStyle = settings.resolvedBrowseListStyle;
      final isGrid = activeStyle.isGrid;

      return SeriesListSkeleton(isGrid: isGrid);
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(BuildContext context, LocalizationService l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: context.colors.error, size: 48),
          const SizedBox(height: 16),
          Text(
            error ?? 'An unexpected error occurred.',
            style: AppTypography.sans(color: context.colors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(l10n.translate('retry')),
          ),
        ],
      ),
    );
  }

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
          final isCompactGrid = activeStyle == AppListStyle.compactGrid;

          Widget buildGridContent(BuildContext context, int calculatedColumns) {
            if (isCompactGrid) {
              return DynamicRowHeightGrid(
                controller: scrollController,
                padding: const EdgeInsets.all(12),
                crossAxisCount: calculatedColumns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index >= searchResults.length) {
                    if (isLoadingMore && index == searchResults.length) {
                      return const Center(child: CircularProgressIndicator());
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
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                childAspectRatio: activeStyle.childAspectRatio,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (index >= searchResults.length) {
                  if (isLoadingMore && index == searchResults.length) {
                    return const Center(child: CircularProgressIndicator());
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

          // Rebuilt only when the column count changes; between those a
          // resize just re-lays the grid out.
          return DerivedLayoutBuilder<int>(
            derive: (constraints) =>
                ((constraints.maxWidth + 10) / 170).ceil().clamp(1, 12),
            builder: buildGridContent,
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
                  child: Center(child: CircularProgressIndicator()),
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

  Widget _buildPublisherResults() {
    return _buildPeopleResults(
      cellHeight: 118,
      itemBuilder: (context, index, margin) {
        final publisher = searchResults[index] as Publisher;
        return PublisherListItem(
          publisher: publisher,
          margin: margin,
          onTap: () =>
              CollectionsBrowseScreen.open(context, publisher: publisher),
        );
      },
    );
  }

  Widget _buildStaffResults() {
    return _buildPeopleResults(
      cellHeight: 88,
      itemBuilder: (context, index, margin) {
        final staff = searchResults[index] as Staff;
        return StaffListItem(
          staff: staff,
          margin: margin,
          onTap: () => onNavigateToResults(
            staff.name,
            'popularity_desc',
            staff: staff.name,
          ),
        );
      },
    );
  }

  /// Publishers and staff share their layout: a plain list on a phone, and a
  /// grid of cards on desktop — a card stretched across a wide window is mostly
  /// empty space between the name and the chevron.
  Widget _buildPeopleResults({
    required double cellHeight,
    required Widget Function(BuildContext, int, EdgeInsetsGeometry?)
    itemBuilder,
  }) {
    return Builder(
      builder: (context) {
        final itemCount = searchResults.length + (isLoadingMore ? 1 : 0);
        Widget spinner() => const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        );

        if (DesktopLayout.isActive(context)) {
          return GridView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 12),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 460,
              mainAxisExtent: cellHeight,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) => index >= searchResults.length
                ? spinner()
                : itemBuilder(context, index, EdgeInsets.zero),
          );
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: itemCount,
          itemBuilder: (context, index) => index >= searchResults.length
              ? spinner()
              // Null margin: each card keeps its own list default.
              : itemBuilder(context, index, null),
        );
      },
    );
  }

  /// Returns an appropriate icon for the empty / prompt state of each browse type.
  IconData _emptyStateIconFor(BrowseType type) => switch (type) {
    BrowseType.publishers => Icons.business,
    BrowseType.staff => Icons.people,
    _ => Icons.search,
  };

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
          } else if (browseType == BrowseType.publishers) {
            content = Center(
              key: const ValueKey('publishers_prompt'),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_rounded,
                    size: 64,
                    color: context.colors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.translate('search_publishers_hint'),
                    style: AppTypography.sans(
                      color: context.colors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(
                      Icons.collections_bookmark_rounded,
                      size: 18,
                    ),
                    label: Text(l10n.translate('collections_and_editions')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.accent,
                      side: BorderSide(color: context.colors.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => CollectionsBrowseScreen.open(context),
                  ),
                ],
              ),
            );
          } else {
            content = Center(
              key: const ValueKey('search_prompt'),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _emptyStateIconFor(browseType),
                    size: 64,
                    color: context.colors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.translate('no_results'),
                    style: AppTypography.sans(
                      color: context.colors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
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

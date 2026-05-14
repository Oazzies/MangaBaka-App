import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';
import 'package:mangabaka_app/features/browse/widgets/browse_shortcuts.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/settings/settings_enums.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/widgets/series_list_skeleton.dart';
import 'package:mangabaka_app/features/series/services/series_id_service.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';

import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_list_item.dart';
import 'package:mangabaka_app/features/staff/models/staff.dart';
import 'package:mangabaka_app/features/staff/widgets/staff_list_item.dart';

class BrowseContent extends StatelessWidget {
  final List<dynamic> searchResults;
  final BrowseType browseType;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final ScrollController scrollController;
  final VoidCallback onRetry;
  final Function(Series) onNavigateToDetail;
  final Function(String, String, {String? type, String? staff, String? publisher}) onNavigateToResults;

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
  });

  Widget _buildLoadingState() {
    if (browseType == BrowseType.series) {
      final settings = SettingsManager();
      final activeStyle = settings.separateListStyles ? settings.browseListStyle : settings.currentListStyle;
      final isGrid = activeStyle.isGrid;
      
      return SeriesListSkeleton(isGrid: isGrid);
    }
    
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(LocalizationService l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppConstants.errorColor, size: 48),
          const SizedBox(height: 16),
          Text(
            error ?? 'An unexpected error occurred.',
            style: TextStyle(color: AppConstants.errorColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: Text(l10n.translate('retry'))),
        ],
      ),
    );
  }

  Widget _buildResultsList(LocalizationService l10n) {
    if (browseType == BrowseType.series) {
      return _buildSeriesResults(l10n);
    } else if (browseType == BrowseType.publishers) {
      return _buildPublisherResults(l10n);
    } else if (browseType == BrowseType.staff) {
      return _buildStaffResults(l10n);
    } else {
      return Center(child: Text(l10n.translate('no_results')));
    }
  }

  Widget _buildSeriesResults(LocalizationService l10n) {
    return ListenableBuilder(
      listenable: Listenable.merge([SettingsManager(), l10n]),
      builder: (context, _) {
        final settings = SettingsManager();
        final activeStyle = settings.separateListStyles ? settings.browseListStyle : settings.currentListStyle;
        final isGrid = activeStyle.isGrid;

        final seriesService = getIt<SeriesService>();
        if (isGrid) {
          return GridView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              childAspectRatio: 0.65,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: searchResults.length + (isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == searchResults.length) {
                return const Center(child: CircularProgressIndicator());
              }

              final series = searchResults[index] as Series;
              return MouseRegion(
                onEnter: (_) => seriesService.fetchSeries(series.id),
                child: InkWell(
                  onTap: () => onNavigateToDetail(series),
                  child: EntryListItem(key: ValueKey('grid_${series.id}'), series: series),
                ),
              );
            },
          );
        }

        return ListView.builder(
          controller: scrollController,
          itemCount: searchResults.length + (isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == searchResults.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final series = searchResults[index] as Series;
            return MouseRegion(
              onEnter: (_) => seriesService.fetchSeries(series.id),
              child: InkWell(
                onTap: () => onNavigateToDetail(series),
                child: EntryListItem(key: ValueKey('list_${series.id}'), series: series),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPublisherResults(LocalizationService l10n) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: searchResults.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == searchResults.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final publisher = searchResults[index] as Publisher;
        return PublisherListItem(
          publisher: publisher,
          onTap: () => onNavigateToResults(publisher.name, 'name_asc', publisher: publisher.name),
        );
      },
    );
  }

  Widget _buildStaffResults(LocalizationService l10n) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: searchResults.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == searchResults.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final staff = searchResults[index] as Staff;
        return StaffListItem(
          staff: staff,
          onTap: () => onNavigateToResults(staff.name, 'popularity_desc', staff: staff.name),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        final l10n = LocalizationService();
        
        Widget content;
        if (searchResults.isEmpty && !isLoading && error == null) {
          if (browseType == BrowseType.series) {
            content = BrowseShortcuts(key: const ValueKey('shortcuts'), onNavigate: onNavigateToResults);
          } else {
            content = Center(
              key: const ValueKey('search_prompt'),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    browseType == BrowseType.publishers 
                      ? Icons.business 
                      : (browseType == BrowseType.staff ? Icons.people : Icons.search),
                    size: 64,
                    color: AppConstants.textMutedColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.translate('no_results'),
                    style: TextStyle(
                      color: AppConstants.textMutedColor,
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
          content = _buildErrorState(l10n);
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
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: content,
          ),
        );
      },
    );
  }
}

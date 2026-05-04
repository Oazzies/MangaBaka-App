import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/series/widgets/entry_list_item.dart';
import 'package:bakahyou/features/browse/widgets/browse_shortcuts.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/utils/settings/settings_enums.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/features/series/widgets/series_list_skeleton.dart';

class BrowseContent extends StatelessWidget {
  final List<Series> searchResults;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final ScrollController scrollController;
  final VoidCallback onRetry;
  final Function(Series) onNavigateToDetail;
  final Function(String, String, {String? type}) onNavigateToResults;

  const BrowseContent({
    super.key,
    required this.searchResults,
    required this.isLoading,
    required this.isLoadingMore,
    required this.error,
    required this.scrollController,
    required this.onRetry,
    required this.onNavigateToDetail,
    required this.onNavigateToResults,
  });

  Widget _buildLoadingState() {
    final settings = SettingsManager();
    final activeStyle = settings.separateListStyles ? settings.browseListStyle : settings.currentListStyle;
    final isGrid = activeStyle == AppListStyle.grid || activeStyle == AppListStyle.coverOnlyGrid;
    
    return SeriesListSkeleton(isGrid: isGrid);
  }

  Widget _buildErrorState(LocalizationService l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppConstants.errorColor, size: 48),
          SizedBox(height: 16),
          Text(
            error!,
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
    return ListenableBuilder(
      listenable: Listenable.merge([SettingsManager(), l10n]),
      builder: (context, _) {
        final settings = SettingsManager();
        final activeStyle = settings.separateListStyles ? settings.browseListStyle : settings.currentListStyle;
        final isGrid = activeStyle == AppListStyle.grid || activeStyle == AppListStyle.coverOnlyGrid;

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

              final series = searchResults[index];
              return InkWell(
                onTap: () => onNavigateToDetail(series),
                child: EntryListItem(series: series),
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

            final series = searchResults[index];
            return InkWell(
              onTap: () => onNavigateToDetail(series),
              child: EntryListItem(series: series),
            );
          },
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
          content = BrowseShortcuts(onNavigate: onNavigateToResults);
        } else if (isLoading && searchResults.isEmpty) {
          content = _buildLoadingState();
        } else if (error != null && searchResults.isEmpty) {
          content = _buildErrorState(l10n);
        } else if (searchResults.isNotEmpty) {
          content = _buildResultsList(l10n);
        } else {
          content = const SizedBox.shrink();
        }

        return Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
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

import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/series/widgets/entry_list_item.dart';
import 'package:bakahyou/features/browse/widgets/browse_shortcuts.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/utils/settings/settings_enums.dart';


import 'package:bakahyou/utils/localization/localization_service.dart';

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
    return Expanded(child: Center(child: CircularProgressIndicator()));
  }

  Widget _buildErrorState(LocalizationService l10n) {
    return Expanded(
      child: Center(
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
      ),
    );
  }

  Widget _buildResultsList(LocalizationService l10n) {
    return Expanded(
      child: ListenableBuilder(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        final l10n = LocalizationService();
        if (searchResults.isEmpty && !isLoading && error == null) {
          return Expanded(child: BrowseShortcuts(onNavigate: onNavigateToResults));
        }

        if (isLoading && searchResults.isEmpty) {
          return _buildLoadingState();
        }

        if (error != null && searchResults.isEmpty) {
          return _buildErrorState(l10n);
        }

        if (searchResults.isNotEmpty) {
          return _buildResultsList(l10n);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

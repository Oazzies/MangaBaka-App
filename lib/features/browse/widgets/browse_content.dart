import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/series/widgets/entry_list_item.dart';
import 'package:bakahyou/features/browse/widgets/browse_shortcuts.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

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

  Widget _buildErrorState() {
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
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return Expanded(
      child: ListView.builder(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (searchResults.isEmpty && !isLoading && error == null) {
      return Expanded(child: BrowseShortcuts(onNavigate: onNavigateToResults));
    }

    if (isLoading && searchResults.isEmpty) {
      return _buildLoadingState();
    }

    if (error != null && searchResults.isEmpty) {
      return _buildErrorState();
    }

    if (searchResults.isNotEmpty) {
      return _buildResultsList();
    }

    return const SizedBox.shrink();
  }
}

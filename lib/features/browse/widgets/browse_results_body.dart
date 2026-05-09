import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/browse/widgets/browse_results_list.dart';
import 'package:bakahyou/features/browse/widgets/browse_results_status_widgets.dart';

class BrowseResultsBody extends StatelessWidget {
  final String? error;
  final bool isLoading;
  final List<Series> results;
  final String sortBy;
  final ScrollController scrollController;
  final VoidCallback onRetry;
  final Function(Series) onSeriesTap;

  const BrowseResultsBody({
    required this.error,
    required this.isLoading,
    required this.results,
    required this.sortBy,
    required this.scrollController,
    required this.onRetry,
    required this.onSeriesTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return BrowseResultsError(
        error: error!,
        onRetry: onRetry,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: results.isEmpty && isLoading
          ? const BrowseResultsLoading()
          : results.isEmpty
              ? const BrowseResultsEmpty()
              : BrowseResultsList(
                  results: results,
                  scrollController: scrollController,
                  isLoading: isLoading,
                  shouldShowRanking: sortBy == 'popularity_asc',
                  onSeriesTap: onSeriesTap,
                ),
    );
  }
}

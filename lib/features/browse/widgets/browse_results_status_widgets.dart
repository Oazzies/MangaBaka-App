import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/widgets/series_list_skeleton.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/utils/settings/settings_enums.dart';

class BrowseResultsLoading extends StatelessWidget {
  const BrowseResultsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsManager();
    final activeStyle = settings.separateListStyles
        ? settings.browseListStyle
        : settings.currentListStyle;
    final isGrid = activeStyle.isGrid;

    return SeriesListSkeleton(isGrid: isGrid);
  }
}

class BrowseResultsEmpty extends StatelessWidget {
  const BrowseResultsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        LocalizationService().translate('no_results'),
        style: TextStyle(color: AppConstants.textColor),
      ),
    );
  }
}

class BrowseResultsError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const BrowseResultsError({
    required this.error,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppConstants.errorColor, size: 48),
          const SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(color: AppConstants.errorColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(LocalizationService().translate('retry')),
          ),
        ],
      ),
    );
  }
}

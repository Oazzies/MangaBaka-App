import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/widgets/series_list_skeleton.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class BrowseResultsLoading extends StatelessWidget {
  const BrowseResultsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsManager();
    final activeStyle = settings.resolvedBrowseListStyle;
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
        style: AppTypography.sans(color: context.colors.text),
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
          Icon(Icons.error_outline, color: context.colors.error, size: 48),
          const SizedBox(height: 16),
          Text(
            error,
            style: AppTypography.sans(color: context.colors.error),
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

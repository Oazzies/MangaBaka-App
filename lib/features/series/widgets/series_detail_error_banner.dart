import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';

class SeriesDetailErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const SeriesDetailErrorBanner({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppConstants.errorColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppConstants.denseRadius),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppConstants.errorColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LocalizationService().translate('failed_to_load'),
                  style: TextStyle(
                    color: AppConstants.errorColor,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  LocalizationService().translate('retry'),
                  style: TextStyle(
                    color: AppConstants.errorColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

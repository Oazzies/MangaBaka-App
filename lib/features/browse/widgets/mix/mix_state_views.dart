import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';

class MixEmptyState extends StatelessWidget {
  final LocalizationService l10n;

  const MixEmptyState({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Text(
              l10n.translate('mix_empty_title').toUpperCase(),
              style: AppTypography.display(
                color: context.colors.text,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.translate('mix_empty_subtitle'),
              style: AppTypography.sans(
                color: context.colors.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class MixLoadingState extends StatelessWidget {
  final LocalizationService l10n;

  const MixLoadingState({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MbSpinner(size: 28, strokeWidth: 2.5, color: context.colors.accent),
          const SizedBox(height: 16),
          Text(
            l10n.translate('mix_generating'),
            style: AppTypography.sans(
              color: context.colors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class MixErrorState extends StatelessWidget {
  final LocalizationService l10n;
  final VoidCallback onRetry;

  const MixErrorState({super.key, required this.l10n, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: context.colors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('mix_error'),
              style: AppTypography.sans(
                color: context.colors.error,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.translate('retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.accent,
                foregroundColor: context.colors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.pillRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MixNoResultsState extends StatelessWidget {
  final LocalizationService l10n;

  const MixNoResultsState({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          l10n.translate('mix_no_results'),
          style: AppTypography.sans(
            color: context.colors.textMuted,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

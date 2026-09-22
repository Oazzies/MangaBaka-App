import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/features/browse/controllers/mix_controller.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The API's suggested additional seeds, shown once the user has picked two.
///
/// Suggestions are best-effort — [MixService.fetchSeedSuggestions] degrades to
/// an empty list on failure — so this renders nothing rather than an error
/// when there is nothing to show.
class MixSeedSuggestions extends StatelessWidget {
  final MixController controller;
  final LocalizationService l10n;
  final ValueChanged<AutocompleteSeriesResult> onSeedAdded;

  const MixSeedSuggestions({
    super.key,
    required this.controller,
    required this.l10n,
    required this.onSeedAdded,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.isSuggestionsLoading) {
      return _LoadingRow(label: l10n.translate('mix_seed_suggestions'));
    }
    if (controller.seedSuggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: context.colors.accent,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.translate('mix_seed_suggestions'),
              style: AppTypography.sans(
                color: context.colors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: controller.seedSuggestions.length,
            itemBuilder: (context, i) {
              final suggestion = controller.seedSuggestions[i];
              return _SuggestionCard(
                suggestion: suggestion,
                onTap: () => onSeedAdded(suggestion),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LoadingRow extends StatelessWidget {
  final String label;

  const _LoadingRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.colors.accent,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTypography.sans(
            color: context.colors.textMuted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final AutocompleteSeriesResult suggestion;
  final VoidCallback onTap;

  const _SuggestionCard({required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppConstants.denseRadius),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.denseRadius),
                bottomLeft: Radius.circular(AppConstants.denseRadius),
              ),
              child: SizedBox(
                width: 46,
                height: double.infinity,
                child: suggestion.thumbnailUrl.isEmpty
                    ? Container(color: context.colors.surfaceRaised)
                    : WidgetUtils.networkImage(
                        url: suggestion.thumbnailUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 100,
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                suggestion.title,
                style: AppTypography.sans(
                  color: context.colors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: context.colors.surfaceRaised,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: context.colors.accent,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

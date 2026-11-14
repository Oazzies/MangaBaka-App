import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class FilterChipBadge extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;
  final bool isNegative;

  const FilterChipBadge({
    super.key,
    required this.label,
    required this.onDeleted,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isNegative ? context.colors.error : context.colors.text;
    final bgColor = isNegative
        ? context.colors.error.withValues(alpha: 0.12)
        : context.colors.surfaceRaised;

    return RawChip(
      label: Text(label.toUpperCase()),
      onDeleted: onDeleted,
      deleteIcon: Icon(Icons.close_rounded, size: 14, color: color),
      backgroundColor: bgColor,
      side: BorderSide.none,
      labelStyle: AppTypography.sans(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

String filterSortLabel(String sortBy, LocalizationService l10n) {
  switch (sortBy) {
    case 'name_asc':
      return l10n.translate('title_asc');
    case 'name_desc':
      return l10n.translate('title_desc');
    case 'popularity_asc':
      return l10n.translate('popularity_asc');
    case 'popularity_desc':
      return l10n.translate('popularity_desc');
    case 'my_score_desc':
      return l10n.translate('my_rating_desc');
    case 'my_score_asc':
      return l10n.translate('my_rating_asc');
    case 'score_desc':
      return l10n.translate('rating_desc');
    case 'score_asc':
      return l10n.translate('rating_asc');
    case 'chapters_desc':
      return l10n.translate('chapters_desc');
    case 'chapters_asc':
      return l10n.translate('chapters_asc');
    case 'unread_desc':
      return l10n.translate('unread_desc');
    case 'unread_asc':
      return l10n.translate('unread_asc');
    case 'random':
      return l10n.translate('random_sort');
    default:
      return sortBy;
  }
}

List<Widget> buildFilterPairChips(
  BuildContext context, {
  required List<String> include,
  required List<String> exclude,
  required String Function(String) labelFor,
  required void Function(String) onRemoveInclude,
  required void Function(String) onRemoveExclude,
}) {
  return [
    for (final v in include)
      FilterChipBadge(
        label: labelFor(v),
        onDeleted: () => onRemoveInclude(v),
      ),
    for (final v in exclude)
      FilterChipBadge(
        label: '- ${labelFor(v)}',
        onDeleted: () => onRemoveExclude(v),
        isNegative: true,
      ),
  ];
}

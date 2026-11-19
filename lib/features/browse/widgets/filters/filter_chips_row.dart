import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/active_filter_chips.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';

class FilterChipsRow extends StatelessWidget {
  static const double stripHeight = 40;

  final SearchFilters filters;
  final ValueChanged<SearchFilters> onFiltersChanged;
  final MetadataService metadata;
  final Widget? leading;

  /// One line of [stripHeight], built even with no chips, so the first filter moves nothing below.
  const FilterChipsRow({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    required this.metadata,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        final l10n = LocalizationService();
        final chips = buildActiveFilterChips(
          filters: filters,
          onChanged: onFiltersChanged,
          l10n: l10n,
          metadata: metadata,
        );
        if (chips.isNotEmpty) {
          chips.add(
            _ResetFiltersButton(
              label: l10n.translate('reset'),
              onTap: () => onFiltersChanged(SearchFilters()),
            ),
          );
        }

        return _buildStrip(chips);
      },
    );
  }

  Widget _buildStrip(List<Widget> chips) {
    return SizedBox(
      height: stripHeight,
      child: Row(
        children: [
          ?leading,
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < chips.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    chips[i],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetFiltersButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ResetFiltersButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.colors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restart_alt_rounded,
              size: 16,
              color: context.colors.error,
            ),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: AppTypography.sans(
                color: context.colors.error,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

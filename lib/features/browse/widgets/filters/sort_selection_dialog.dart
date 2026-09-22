import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class SortSelectionDialog {
  static void show({
    required BuildContext context,
    required LocalizationService l10n,
    required Map<String, String> sortOptions,
    required SearchFilters currentFilters,
    required ValueChanged<String?> onSortSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext dialogContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: dialogContext.colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildHeader(dialogContext),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l10n.translate('sort_by').toUpperCase(),
                  style: AppTypography.display(
                    color: dialogContext.colors.text,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SelectionTile(
                        label: l10n.translate('default'),
                        isSelected: currentFilters.sortBy == null,
                        onTap: () {
                          onSortSelected(null);
                          Navigator.pop(dialogContext);
                        },
                        isLast: false,
                      ),
                      ...sortOptions.entries.map((e) {
                        final isSelected = currentFilters.sortBy == e.key;
                        final isEntryLast =
                            e.key == sortOptions.entries.last.key;
                        return _SelectionTile(
                          label: e.value,
                          isSelected: isSelected,
                          onTap: () {
                            onSortSelected(e.key);
                            Navigator.pop(dialogContext);
                          },
                          isLast: isEntryLast,
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SafeArea(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildHeader(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: context.colors.surfaceRaised,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLast;

  const _SelectionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: context.colors.surfaceRaised,
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: AppTypography.sans(
                color: isSelected
                    ? context.colors.text
                    : context.colors.textMuted,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected
                  ? context.colors.accent
                  : context.colors.border.withValues(alpha: 0.3),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

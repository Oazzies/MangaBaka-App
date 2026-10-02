import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/publisher/utils/publisher_sort.dart';

/// The Publishers tab's own "filter": a sheet with its sort orders, opened from
/// the search bar's filter button in place of the series filter sheet.
Future<void> showPublisherSortSheet(
  BuildContext context, {
  required String? current,
  required ValueChanged<String?> onSelected,
}) {
  final l10n = LocalizationService();
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: context.colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppConstants.largeRadius),
      ),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('sort_by').toUpperCase(),
              style: AppTypography.display(
                color: sheetContext.colors.text,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            for (final (value, label) in publisherSortOptions(l10n))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  label,
                  style: AppTypography.sans(
                    color: value == current
                        ? sheetContext.colors.accent
                        : sheetContext.colors.text,
                    fontWeight:
                        value == current ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                trailing: value == current
                    ? Icon(Icons.check_rounded, color: sheetContext.colors.accent)
                    : null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onSelected(value);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

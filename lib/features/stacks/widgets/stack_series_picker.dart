import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_series_search.dart';

export 'package:mangabaka_app/features/stacks/widgets/stack_series_search.dart';

/// [StackSeriesSearch] in a tall bottom sheet on a phone, a dialog on
/// desktop.
Future<void> showStackSeriesPicker(
  BuildContext context, {
  required bool Function(String seriesId) isAdded,
  required void Function(Series series) onToggle,
}) {
  final l10n = LocalizationService();
  Widget content(BuildContext context) =>
      StackSeriesSearch(isAdded: isAdded, onToggle: onToggle, autofocus: true);

  if (DesktopLayout.isActive(context)) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: context.colors.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.translate('stacks_add_series'),
                        style: AppTypography.sans(
                          color: context.colors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.translate('done')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(child: content(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  return showAdaptiveSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.colors.surface,
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 8,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.translate('stacks_add_series'),
                      style: AppTypography.sans(
                        color: context.colors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.translate('done')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(child: content(context)),
            ],
          ),
        ),
      ),
    ),
  );
}

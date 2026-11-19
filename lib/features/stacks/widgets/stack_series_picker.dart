import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/adaptive_form.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_series_search.dart';

export 'package:mangabaka_app/features/stacks/widgets/stack_series_search.dart';

Future<void> showStackSeriesPicker(
  BuildContext context, {
  required SeriesSearchService searchService,
  required bool Function(String seriesId) isAdded,
  required void Function(Series series) onToggle,
}) {
  final l10n = LocalizationService();
  return showAdaptiveForm<void>(
    context: context,
    title: l10n.translate('stacks_add_series'),
    scrollable: false,
    builder: (context) => _StackSeriesPicker(
      l10n: l10n,
      search: StackSeriesSearch(
        searchService: searchService,
        isAdded: isAdded,
        onToggle: onToggle,
        autofocus: true,
      ),
    ),
  );
}

class _StackSeriesPicker extends StatelessWidget {
  final LocalizationService l10n;
  final Widget search;

  const _StackSeriesPicker({required this.l10n, required this.search});

  @override
  Widget build(BuildContext context) {
    if (AdaptiveFormPage.isPage(context)) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: search,
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 640),
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
            Expanded(child: search),
          ],
        ),
      ),
    );
  }
}

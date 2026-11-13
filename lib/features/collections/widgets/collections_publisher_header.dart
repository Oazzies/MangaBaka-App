import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_dropdown.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

class CollectionsPublisherHeaderCard extends StatelessWidget {
  final Publisher publisher;
  final LocalizationService l10n;
  final List<String> editionNames;
  final String? editionFilter;
  final bool canChangePublisher;
  final VoidCallback onChangePublisher;
  final ValueChanged<String> onEditionFilterChanged;

  const CollectionsPublisherHeaderCard({
    super.key,
    required this.publisher,
    required this.l10n,
    required this.editionNames,
    required this.editionFilter,
    required this.canChangePublisher,
    required this.onChangePublisher,
    required this.onEditionFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          publisher.name,
                          style: AppTypography.display(
                            color: c.text,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (publisher.subType.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: c.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  publisher.subType.toUpperCase(),
                                  style: AppTypography.monoLabel(
                                    color: c.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (publisher.founded != null)
                              Text(
                                l10n
                                    .translate('publisher_established')
                                    .replaceAll(
                                      '{year}',
                                      publisher.founded.toString(),
                                    ),
                                style: AppTypography.sans(
                                  color: c.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (publisher.closed != null)
                              Text(
                                l10n
                                    .translate('publisher_closed')
                                    .replaceAll(
                                      '{year}',
                                      publisher.closed.toString(),
                                    ),
                                style: AppTypography.sans(
                                  color: c.error.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (publisher.imprints.isNotEmpty)
                              Text(
                                l10n
                                    .translate('publisher_imprints')
                                    .replaceAll(
                                      '{count}',
                                      publisher.imprints.length.toString(),
                                    ),
                                style: AppTypography.sans(
                                  color: c.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (canChangePublisher)
                    TextButton(
                      onPressed: onChangePublisher,
                      child: Text(l10n.translate('change').toUpperCase()),
                    ),
                ],
              ),
              if (publisher.description != null &&
                  publisher.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  publisher.description!,
                  style: AppTypography.sans(
                    color: c.textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.menu_book_rounded, size: 16),
                label: Text(l10n.translate('series')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.text,
                  side: BorderSide(color: c.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    AppTransitions.slideRight(
                      BrowseResultsScreen(
                        sortType: publisher.name,
                        sortBy: 'name_asc',
                        publisher: publisher.name,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (editionNames.length > 1) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: MbDropdown<String>(
              label: l10n.translate('editions'),
              value: editionFilter ?? '',
              options: [
                ('', l10n.translate('all_editions')),
                for (final name in editionNames) (name, name),
              ],
              onChanged: onEditionFilterChanged,
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

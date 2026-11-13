import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_dropdown.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/features/collections/models/edition.dart';
import 'package:mangabaka_app/features/collections/widgets/collection_card.dart';
import 'package:mangabaka_app/features/publisher/controllers/publisher_collections_controller.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_metadata_panels.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';

/// Builds the list items for the publisher's Collections tab.
List<Widget> buildPublisherCollectionsItems({
  required BuildContext context,
  required LocalizationService l10n,
  required PublisherCollectionsController controller,
  required void Function(SeriesCollection) onOpenCollection,
}) {
  final names = controller.editionNames;
  final shown = controller.collections;
  return [
    if (names.length > 1)
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Align(
          alignment: Alignment.centerLeft,
          child: MbDropdown<String>(
            label: l10n.translate('editions'),
            value: controller.editionFilter ?? '',
            options: [
              ('', l10n.translate('all_editions')),
              for (final name in names) (name, name),
            ],
            onChanged: (key) =>
                controller.setEditionFilter(key.isEmpty ? null : key),
          ),
        ),
      ),
    for (final collection in shown)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CollectionCard(
          collection: collection,
          showPublisher: false,
          onTap: () => onOpenCollection(collection),
        ),
      ),
    _CollectionsFooter(
      l10n: l10n,
      controller: controller,
      empty: shown.isEmpty,
    ),
  ];
}

/// Builds the list items for the publisher's Editions tab.
List<Widget> buildPublisherEditionsItems({
  required LocalizationService l10n,
  required PublisherCollectionsController controller,
  required void Function(Edition) onPickEdition,
}) {
  if (controller.editionsFailed) {
    return [
      Center(
        child: TextButton(
          onPressed: controller.ensureEditions,
          child: Text(l10n.translate('retry')),
        ),
      ),
    ];
  }
  final editions = controller.editions;
  if (editions == null) {
    return const [
      Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: MbSpinner()),
      ),
    ];
  }
  return [
    for (final e in editions)
      PublisherEditionTile(
        edition: e,
        selected: controller.editionFilter == e.name,
        onTap: () => onPickEdition(e),
      ),
  ];
}

class _CollectionsFooter extends StatelessWidget {
  final LocalizationService l10n;
  final PublisherCollectionsController controller;
  final bool empty;

  const _CollectionsFooter({
    required this.l10n,
    required this.controller,
    required this.empty,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: MbSpinner()),
      );
    }
    if (controller.failed) {
      return Center(
        child: TextButton(
          onPressed: controller.loadMore,
          child: Text(l10n.translate('retry')),
        ),
      );
    }
    if (empty && !controller.hasNext) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            l10n.translate('no_collections_available'),
            textAlign: TextAlign.center,
            style: AppTypography.sans(color: context.colors.textMuted),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

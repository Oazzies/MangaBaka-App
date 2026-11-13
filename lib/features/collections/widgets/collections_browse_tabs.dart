import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/features/collections/models/edition.dart';
import 'package:mangabaka_app/features/collections/widgets/collection_card.dart';
import 'package:mangabaka_app/features/collections/widgets/collections_browse_rows.dart';
import 'package:mangabaka_app/features/collections/widgets/collections_publisher_header.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';

class CollectionsPublisherPicker extends StatelessWidget {
  final LocalizationService l10n;
  final TextEditingController query;
  final bool searching;
  final List<Publisher> matches;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Publisher> onChoosePublisher;

  const CollectionsPublisherPicker({
    super.key,
    required this.l10n,
    required this.query,
    required this.searching,
    required this.matches,
    required this.onQueryChanged,
    required this.onChoosePublisher,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        TextField(
          controller: query,
          onChanged: onQueryChanged,
          textInputAction: TextInputAction.search,
          style: AppTypography.sans(color: context.colors.text),
          decoration: InputDecoration(
            hintText: l10n.translate('search_publishers_hint'),
            suffixIcon: searching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: MbSpinner(size: 16, strokeWidth: 2),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        if (matches.isEmpty && query.text.trim().isEmpty)
          CollectionsBrowseHint(l10n.translate('collections_pick_publisher'))
        else if (matches.isEmpty && !searching)
          CollectionsBrowseHint(l10n.translate('no_results'))
        else
          for (final p in matches)
            CollectionsPublisherRow(
              publisher: p,
              onTap: () => onChoosePublisher(p),
            ),
      ],
    );
  }
}

class CollectionsPublisherList extends StatelessWidget {
  final LocalizationService l10n;
  final ScrollController scroll;
  final Publisher publisher;
  final List<SeriesCollection> list;
  final String? editionFilter;
  final bool canChangePublisher;
  final bool loadingList;
  final bool listFailed;
  final bool hasNext;
  final VoidCallback onChangePublisher;
  final ValueChanged<String> onEditionFilterChanged;
  final ValueChanged<SeriesCollection> onOpenCollection;
  final VoidCallback onRetry;

  const CollectionsPublisherList({
    super.key,
    required this.l10n,
    required this.scroll,
    required this.publisher,
    required this.list,
    required this.editionFilter,
    required this.canChangePublisher,
    required this.loadingList,
    required this.listFailed,
    required this.hasNext,
    required this.onChangePublisher,
    required this.onEditionFilterChanged,
    required this.onOpenCollection,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final filter = editionFilter;
    final shown = filter == null
        ? list
        : list.where((c) => c.editionName == filter).toList();
    final editionNames = {
      for (final c in list)
        if (c.editionName.isNotEmpty) c.editionName,
    }.toList()..sort();

    final header = CollectionsPublisherHeaderCard(
      publisher: publisher,
      l10n: l10n,
      editionNames: editionNames,
      editionFilter: filter,
      canChangePublisher: canChangePublisher,
      onChangePublisher: onChangePublisher,
      onEditionFilterChanged: onEditionFilterChanged,
    );

    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: shown.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) return header;
        if (index <= shown.length) {
          final c = shown[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CollectionCard(
              collection: c,
              showPublisher: false,
              onTap: () => onOpenCollection(c),
            ),
          );
        }
        if (loadingList) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: MbSpinner()),
          );
        }
        if (listFailed) {
          return Center(
            child: TextButton(
              onPressed: onRetry,
              child: Text(l10n.translate('retry')),
            ),
          );
        }
        if (shown.isEmpty && !hasNext) {
          return CollectionsBrowseHint(
            l10n.translate('no_collections_available'),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class CollectionsEditionsTab extends StatelessWidget {
  final LocalizationService l10n;
  final bool editionsFailed;
  final List<Edition>? editions;
  final Publisher? publisher;
  final String? editionFilter;
  final VoidCallback onRetry;
  final ValueChanged<Edition> onPickEdition;

  const CollectionsEditionsTab({
    super.key,
    required this.l10n,
    required this.editionsFailed,
    required this.editions,
    required this.publisher,
    required this.editionFilter,
    required this.onRetry,
    required this.onPickEdition,
  });

  @override
  Widget build(BuildContext context) {
    if (editionsFailed) {
      return Center(
        child: TextButton(
          onPressed: onRetry,
          child: Text(l10n.translate('retry')),
        ),
      );
    }
    final list = editions;
    if (list == null) {
      return const Center(child: MbSpinner());
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (publisher == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.translate('editions_pick_publisher'),
              style: AppTypography.sans(
                color: context.colors.textMuted,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        for (final e in list)
          CollectionsEditionRow(
            edition: e,
            selected: editionFilter == e.name,
            onTap: publisher == null ? null : () => onPickEdition(e),
          ),
      ],
    );
  }
}

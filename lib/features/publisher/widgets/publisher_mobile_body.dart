import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_pill.dart';
import 'package:mangabaka_app/features/collections/models/edition.dart';
import 'package:mangabaka_app/features/home/widgets/home_rail.dart';
import 'package:mangabaka_app/features/publisher/controllers/publisher_collections_controller.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_collections_tab.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_desktop_body.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_header.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_metadata_panels.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_panel.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_shelves.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';

class PublisherMobileBody extends StatelessWidget {
  final Publisher publisher;
  final LocalizationService l10n;
  final PublisherDetailTab tab;
  final bool loading;
  final ScrollController scrollController;
  final PublisherCollectionsController collectionsController;
  final Future<void> factsReady;
  final Future<void> shelvesReady;
  final Map<PublisherShelf, Future<List<Series>>> shelves;
  final ValueChanged<PublisherDetailTab> onSelectTab;
  final OpenPublisherCallback onOpenPublisher;
  final void Function(SeriesCollection) onOpenCollection;
  final void Function(Edition) onPickEdition;
  final Widget Function(LocalizationService l10n, Publisher publisher)
  buildStatsSection;
  final Widget Function(LocalizationService l10n) buildSimilarSection;

  const PublisherMobileBody({
    super.key,
    required this.publisher,
    required this.l10n,
    required this.tab,
    required this.loading,
    required this.scrollController,
    required this.collectionsController,
    required this.factsReady,
    required this.shelvesReady,
    required this.shelves,
    required this.onSelectTab,
    required this.onOpenPublisher,
    required this.onOpenCollection,
    required this.onPickEdition,
    required this.buildStatsSection,
    required this.buildSimilarSection,
  });

  @override
  Widget build(BuildContext context) {
    final items = <({Widget child, bool bare})>[];
    void add(Widget w, {bool bare = false}) =>
        items.add((child: w, bare: bare));

    add(PublisherMobileHeader(publisher: publisher, l10n: l10n));
    add(_tabBar(l10n));

    if (tab == PublisherDetailTab.info) {
      if (publisher.description != null && publisher.description!.isNotEmpty) {
        add(
          PublisherPanel(
            label: l10n.translate('publisher_about'),
            child: Text(
              publisher.description!,
              style: AppTypography.sans(
                color: context.colors.text,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        );
      }
      if (publisher.note != null && publisher.note!.isNotEmpty) {
        add(PublisherNoteLine(text: publisher.note!));
      }
      add(
        FutureBuilder<void>(
          future: factsReady,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const PublisherSectionLoading();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildStatsSection(l10n, publisher),
                const SizedBox(height: 14),
                buildSimilarSection(l10n),
              ],
            );
          },
        ),
      );
      if (publisher.parent != null || publisher.imprints.isNotEmpty) {
        add(
          PublisherFamilyPanel(
            publisher: publisher,
            l10n: l10n,
            onOpenPublisher: onOpenPublisher,
          ),
        );
      }
      if (publisher.aliases.isNotEmpty) {
        add(PublisherAliasesPanel(publisher: publisher, l10n: l10n));
      }
      if (publisher.links.isNotEmpty) {
        add(PublisherLinksPanel(publisher: publisher, l10n: l10n));
      }
      add(
        PublisherMobileShelvesBlock(
          publisher: publisher,
          l10n: l10n,
          loading: loading,
          shelvesReady: shelvesReady,
          shelves: shelves,
        ),
        bare: true,
      );
    } else if (tab == PublisherDetailTab.collections) {
      for (final w in buildPublisherCollectionsItems(
        context: context,
        l10n: l10n,
        controller: collectionsController,
        onOpenCollection: onOpenCollection,
      )) {
        add(w);
      }
    } else {
      for (final w in buildPublisherEditionsItems(
        l10n: l10n,
        controller: collectionsController,
        onPickEdition: onPickEdition,
      )) {
        add(w);
      }
    }

    final bottom = 32 + MediaQuery.viewPaddingOf(context).bottom;
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(0, 12, 0, bottom),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        if (item.child is HomeRail || item.bare) return item.child;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: item.child,
        );
      },
    );
  }

  Widget _tabBar(LocalizationService l10n) {
    final tabs = [
      (PublisherDetailTab.info, l10n.translate('publisher_tab_info')),
      (PublisherDetailTab.collections, l10n.translate('tab_collections')),
      (PublisherDetailTab.editions, l10n.translate('editions')),
    ];
    return Row(
      children: [
        for (var i = 0; i < tabs.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: MbPill(
              label: tabs[i].$2,
              selected: tab == tabs[i].$1,
              expand: true,
              onTap: () => onSelectTab(tabs[i].$1),
            ),
          ),
        ],
      ],
    );
  }
}

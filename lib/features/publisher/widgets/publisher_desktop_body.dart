import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/collections/models/edition.dart';
import 'package:mangabaka_app/features/publisher/controllers/publisher_collections_controller.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_collections_tab.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_header.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_metadata_panels.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_shelves.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';

enum PublisherDetailTab { info, collections, editions }

class PublisherDesktopScaffold extends StatelessWidget {
  final Future<Publisher> detailFuture;
  final Publisher? initial;
  final String fallbackTitle;
  final PublisherDetailTab tab;
  final ScrollController scrollController;
  final PublisherCollectionsController collectionsController;
  final Map<PublisherShelf, Future<List<Series>>> shelves;
  final ValueChanged<PublisherDetailTab> onSelectTab;
  final VoidCallback onRetry;
  final void Function(SeriesCollection) onOpenCollection;
  final void Function(Edition) onPickEdition;
  final OpenPublisherCallback onOpenPublisher;
  final Widget Function(LocalizationService l10n, Publisher publisher)
  buildStatsSection;
  final Widget Function(LocalizationService l10n) buildSimilarSection;

  static const double _sidebarWidth = 380;
  static const double _sidebarMinWidth = 1120;

  const PublisherDesktopScaffold({
    super.key,
    required this.detailFuture,
    required this.initial,
    required this.fallbackTitle,
    required this.tab,
    required this.scrollController,
    required this.collectionsController,
    required this.shelves,
    required this.onSelectTab,
    required this.onRetry,
    required this.onOpenCollection,
    required this.onPickEdition,
    required this.onOpenPublisher,
    required this.buildStatsSection,
    required this.buildSimilarSection,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return FutureBuilder<Publisher>(
      future: detailFuture,
      builder: (context, snapshot) {
        final publisher = snapshot.data ?? initial;
        final title = publisher?.name ?? fallbackTitle;
        final body = publisher == null
            ? (snapshot.hasError
                  ? DesktopEmptyState(
                      icon: Icons.business_rounded,
                      message: l10n.translate('retry'),
                      action: DesktopPillButton(
                        label: l10n.translate('retry'),
                        icon: Icons.refresh_rounded,
                        onPressed: onRetry,
                      ),
                    )
                  : const Center(child: MbSpinner()))
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: DesktopTokens.maxPageWidth,
                  ),
                  child: DerivedLayoutBuilder<bool>(
                    derive: (c) => c.maxWidth >= _sidebarMinWidth,
                    builder: (context, sidebar) => _body(
                      context,
                      l10n,
                      publisher,
                      sidebar: sidebar,
                      loading: !snapshot.hasData,
                    ),
                  ),
                ),
              );

        return Scaffold(
          backgroundColor: context.colors.background,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DesktopPageHeader(
                leading: DesktopIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: title.isEmpty ? l10n.translate('publishers') : title,
                subtitle: title.isEmpty ? null : l10n.translate('publishers'),
                actions: [
                  if (publisher != null)
                    DesktopSegmented<PublisherDetailTab>(
                      value: tab,
                      segments: [
                        (
                          PublisherDetailTab.info,
                          l10n.translate('publisher_tab_info'),
                          null,
                        ),
                        (
                          PublisherDetailTab.collections,
                          l10n.translate('tab_collections'),
                          null,
                        ),
                        (
                          PublisherDetailTab.editions,
                          l10n.translate('editions'),
                          null,
                        ),
                      ],
                      onChanged: onSelectTab,
                    ),
                ],
              ),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    LocalizationService l10n,
    Publisher publisher, {
    required bool sidebar,
    required bool loading,
  }) {
    const gap = DesktopTokens.sectionGap;
    final identity = PublisherDesktopIdentity(
      publisher: publisher,
      l10n: l10n,
      loading: loading,
    );

    if (tab != PublisherDetailTab.info) {
      final items = tab == PublisherDetailTab.collections
          ? buildPublisherCollectionsItems(
              context: context,
              l10n: l10n,
              controller: collectionsController,
              onOpenCollection: onOpenCollection,
            )
          : buildPublisherEditionsItems(
              l10n: l10n,
              controller: collectionsController,
              onPickEdition: onPickEdition,
            );
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(
          DesktopTokens.pagePadding,
          0,
          DesktopTokens.pagePadding,
          48,
        ),
        children: [
          identity,
          const SizedBox(height: gap),
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items,
              ),
            ),
          ),
        ],
      );
    }

    final facts = <Widget>[
      buildStatsSection(l10n, publisher),
      buildSimilarSection(l10n),
      if (publisher.parent != null || publisher.imprints.isNotEmpty)
        PublisherFamilyPanel(
          publisher: publisher,
          l10n: l10n,
          onOpenPublisher: onOpenPublisher,
        ),
      if (publisher.aliases.isNotEmpty)
        PublisherAliasesPanel(publisher: publisher, l10n: l10n),
      if (publisher.links.isNotEmpty)
        PublisherLinksPanel(publisher: publisher, l10n: l10n),
    ];

    Widget stacked(List<Widget> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          items[i],
        ],
      ],
    );

    final mainList = ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        DesktopTokens.pagePadding,
        0,
        sidebar ? DesktopTokens.pagePadding * 0.75 : DesktopTokens.pagePadding,
        48,
      ),
      children: [
        identity,
        if (!sidebar) ...[const SizedBox(height: gap), stacked(facts)],
        const SizedBox(height: gap),
        for (final (shelf, title, sort) in publisherShelfDefs(l10n))
          PublisherDesktopShelf(
            publisher: publisher,
            shelf: shelf,
            title: title,
            sort: sort,
            future: shelves[shelf]!,
          ),
      ],
    );
    if (!sidebar) return mainList;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: mainList),
        SizedBox(
          width: _sidebarWidth,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              0,
              0,
              DesktopTokens.pagePadding,
              48,
            ),
            children: [stacked(facts)],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/widgets/design/mb_dropdown.dart';
import 'package:mangabaka_app/core/widgets/design/mb_pill.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_carousel.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_cover_card.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';
import 'package:mangabaka_app/features/collections/models/edition.dart';
import 'package:mangabaka_app/features/collections/screens/collection_detail_screen.dart';
import 'package:mangabaka_app/features/collections/widgets/collection_card.dart';
import 'package:mangabaka_app/features/publisher/controllers/publisher_collections_controller.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:mangabaka_app/features/publisher/utils/format_count.dart';
import 'package:mangabaka_app/features/home/widgets/home_rail.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_logo.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_stats_charts.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/mb_card.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:url_launcher/url_launcher.dart';

/// One publisher: who they are, what they publish, and who they resemble.
///
/// The header paints at once from whatever the caller already has (a search
/// row, a series' publisher ref); the full record, the catalog stats and the
/// similar-publishers list then load independently, so a failure in one leaves
/// the others on screen.
class PublisherDetailScreen extends StatefulWidget {
  final String publisherId;

  /// A partial record to show while the full one loads.
  final Publisher? initial;

  /// Fallback title when only an id and a name are known.
  final String? name;

  const PublisherDetailScreen({
    super.key,
    required this.publisherId,
    this.initial,
    this.name,
  });

  static void open(
    BuildContext context, {
    required String id,
    Publisher? publisher,
    String? name,
  }) {
    Navigator.of(context).push(
      AppTransitions.slideRight(
        PublisherDetailScreen(publisherId: id, initial: publisher, name: name),
      ),
    );
  }

  @override
  State<PublisherDetailScreen> createState() => _PublisherDetailScreenState();
}

/// The page's tabs. Switching one swaps what is shown below the bar; it never
/// opens another page.
enum _PublisherTab { info, collections, editions }

class _PublisherDetailScreenState extends State<PublisherDetailScreen> {
  late final PublisherSearchService _service = getIt<PublisherSearchService>();
  late final PublisherCollectionsController _collections =
      PublisherCollectionsController(widget.publisherId);
  final ScrollController _scroll = ScrollController();

  late Future<Publisher> _detail;
  late Future<PublisherStats> _stats;
  late Future<List<SimilarPublisher>> _similar;
  late Map<PublisherShelf, Future<List<Series>>> _shelves;

  _PublisherTab _tab = _PublisherTab.info;

  /// How close to the end of the list (in logical pixels) the next page of
  /// collections starts loading.
  static const double _loadAhead = 700;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_loadMoreIfNeeded);
    _collections.addListener(_onCollectionsChanged);
  }

  @override
  void dispose() {
    _collections.removeListener(_onCollectionsChanged);
    _collections.dispose();
    _scroll.removeListener(_loadMoreIfNeeded);
    _scroll.dispose();
    super.dispose();
  }

  void _load() {
    _detail = _service.getPublisher(widget.publisherId);
    // The stats and similar sections only subscribe once the record has
    // loaded; `ignore` keeps a failure in the meantime from being reported as
    // unhandled (their FutureBuilders still receive it).
    _stats = _service.getStats(widget.publisherId)..ignore();
    _similar = _service.getSimilar(widget.publisherId)..ignore();
    _shelves = {
      for (final shelf in PublisherShelf.values)
        shelf: _service.getShelf(widget.publisherId, shelf)..ignore(),
    };
  }

  void _retry() => setState(_load);

  String get _title => widget.initial?.name ?? widget.name ?? '';

  // ─── Tabs & paging ─────────────────────────────────────────────────────────

  void _selectTab(_PublisherTab tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    if (_scroll.hasClients) _scroll.jumpTo(0);
    switch (tab) {
      case _PublisherTab.collections:
        _collections.ensureCollections();
      case _PublisherTab.editions:
        _collections.ensureEditions();
      case _PublisherTab.info:
        break;
    }
  }

  void _onCollectionsChanged() {
    if (!mounted) return;
    setState(() {});
    // A page may not fill the window (a short page, or an edition filter
    // hiding most of it), and then there is no scrolling to trigger the next
    // one — so check again once the new items are laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMoreIfNeeded());
  }

  /// Loads the next page of collections when the end of the list is near, or
  /// already in view. Stops after a failed load: the retry button is the
  /// user's to press.
  void _loadMoreIfNeeded() {
    if (!mounted ||
        _tab != _PublisherTab.collections ||
        !_collections.hasNext ||
        _collections.loading ||
        _collections.failed ||
        !_scroll.hasClients) {
      return;
    }
    final position = _scroll.position;
    if (position.maxScrollExtent - position.pixels < _loadAhead) {
      _collections.loadMore();
    }
  }

  void _pickEdition(Edition edition) {
    _collections.setEditionFilter(edition.name);
    _selectTab(_PublisherTab.collections);
  }

  void _openCollection(SeriesCollection collection) {
    Navigator.of(context).push(
      AppTransitions.slideRight(CollectionDetailScreen(collection: collection)),
    );
  }

  Widget _tabBar(LocalizationService l10n) {
    final tabs = [
      (_PublisherTab.info, l10n.translate('publisher_tab_info')),
      (_PublisherTab.collections, l10n.translate('tab_collections')),
      (_PublisherTab.editions, l10n.translate('editions')),
    ];
    // Equal pills in the style of the Series / Publishers / Staff switcher.
    return Row(
      children: [
        for (var i = 0; i < tabs.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: MbPill(
              label: tabs[i].$2,
              selected: _tab == tabs[i].$1,
              expand: true,
              onTap: () => _selectTab(tabs[i].$1),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    if (DesktopLayout.isActive(context)) return _buildDesktop(context, l10n);

    final body = FutureBuilder<Publisher>(
      future: _detail,
      builder: (context, snapshot) {
        final publisher = snapshot.data ?? widget.initial;
        if (publisher == null) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: _retry,
                child: Text(l10n.translate('retry')),
              ),
            );
          }
          return const Center(child: MbSpinner());
        }
        return _content(context, l10n, publisher, loading: !snapshot.hasData);
      },
    );

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: mbScreenAppBar(
        title: _title.isEmpty ? l10n.translate('publishers') : _title,
      ),
      body: WidgetUtils.responsiveConstraint(maxWidth: 900, body),
    );
  }

  // ─── Desktop ───────────────────────────────────────────────────────────────

  /// Width of the right-hand column, and the page width from which it sits
  /// beside the main column rather than under it (as on the desktop Profile).
  static const double _sidebarWidth = 380;
  static const double _sidebarMinWidth = 1120;

  Widget _buildDesktop(BuildContext context, LocalizationService l10n) {
    return FutureBuilder<Publisher>(
      future: _detail,
      builder: (context, snapshot) {
        final publisher = snapshot.data ?? widget.initial;
        final title = publisher?.name ?? _title;

        Widget body;
        if (publisher == null) {
          body = snapshot.hasError
              ? DesktopEmptyState(
                  icon: Icons.business_rounded,
                  message: l10n.translate('retry'),
                  action: DesktopPillButton(
                    label: l10n.translate('retry'),
                    icon: Icons.refresh_rounded,
                    onPressed: _retry,
                  ),
                )
              : const Center(child: MbSpinner());
        } else {
          body = Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: DesktopTokens.maxPageWidth,
              ),
              child: DerivedLayoutBuilder<bool>(
                derive: (c) => c.maxWidth >= _sidebarMinWidth,
                builder: (context, sidebar) => _desktopBody(
                  context,
                  l10n,
                  publisher,
                  sidebar: sidebar,
                  loading: !snapshot.hasData,
                ),
              ),
            ),
          );
        }

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
                    DesktopSegmented<_PublisherTab>(
                      value: _tab,
                      segments: [
                        (_PublisherTab.info, l10n.translate('publisher_tab_info'), null),
                        (_PublisherTab.collections, l10n.translate('tab_collections'), null),
                        (_PublisherTab.editions, l10n.translate('editions'), null),
                      ],
                      onChanged: _selectTab,
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

  Widget _desktopBody(
    BuildContext context,
    LocalizationService l10n,
    Publisher publisher, {
    required bool sidebar,
    required bool loading,
  }) {
    const gap = DesktopTokens.sectionGap;
    final identity = _DesktopIdentity(
      publisher: publisher,
      l10n: l10n,
      loading: loading,
    );

    // Collections and Editions: the identity card, then one centred column of
    // rows — the same card the Info tab opens with, so the page keeps its head.
    if (_tab != _PublisherTab.info) {
      final items = _tab == _PublisherTab.collections
          ? _collectionsItems(l10n)
          : _editionsItems(l10n);
      return ListView(
        controller: _scroll,
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

    // What describes the publisher; beside the shelves on a wide window.
    final facts = <Widget>[
      _statsSection(l10n, publisher),
      _similarSection(l10n),
      if (publisher.parent != null || publisher.imprints.isNotEmpty)
        _Family(publisher: publisher, l10n: l10n),
      if (publisher.aliases.isNotEmpty) _Aliases(publisher: publisher, l10n: l10n),
      if (publisher.links.isNotEmpty) _Links(publisher: publisher, l10n: l10n),
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

    final main = <Widget>[
      identity,
      if (!sidebar) ...[const SizedBox(height: gap), stacked(facts)],
      const SizedBox(height: gap),
      for (final (shelf, title, sort) in _shelfDefs(l10n))
        _desktopShelf(publisher, shelf, title, sort),
    ];

    final mainList = ListView(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(
        DesktopTokens.pagePadding,
        0,
        sidebar ? DesktopTokens.pagePadding * 0.75 : DesktopTokens.pagePadding,
        48,
      ),
      children: main,
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

  /// One shelf as a desktop carousel — the same row the Home feed uses.
  Widget _desktopShelf(
    Publisher publisher,
    PublisherShelf shelf,
    String title,
    String? sort,
  ) {
    return FutureBuilder<List<Series>>(
      future: _shelves[shelf],
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        final series = snapshot.data ?? const <Series>[];
        final loading = !snapshot.hasData;
        if (!loading && series.isEmpty) return const SizedBox.shrink();
        final textArea = DesktopCoverCard.textAreaHeight(context);
        return Padding(
          padding: const EdgeInsets.only(bottom: DesktopTokens.sectionGap),
          child: DesktopCarousel(
            title: title,
            loading: loading,
            itemCount: series.length,
            itemWidth: 156,
            stretch: true,
            itemHeight: (width) => width * 1.5 + textArea,
            onViewAll: sort == null
                ? null
                : () => Navigator.of(context).push(
                      AppTransitions.slideRight(
                        BrowseResultsScreen(
                          sortType: title,
                          sortBy: sort,
                          publisher: publisher.name,
                          publisherId: publisher.id,
                          refineLabel: title,
                        ),
                      ),
                    ),
            itemBuilder: (context, i) => DesktopCoverCard(
              series: series[i],
              heroTag: 'publisher_${publisher.id}_${shelf.name}_$i',
              showRating: false,
            ),
          ),
        );
      },
    );
  }

  // ─── Mobile body ───────────────────────────────────────────────────────────

  Widget _content(
    BuildContext context,
    LocalizationService l10n,
    Publisher publisher, {
    required bool loading,
  }) {
    // Each entry is one list item, so a long collections list only builds what
    // is on screen. The rails inset themselves (`bare`); everything else is
    // inset here.
    final items = <({Widget child, bool bare})>[];
    void add(Widget w, {bool bare = false}) => items.add((child: w, bare: bare));

    add(_Header(publisher: publisher, l10n: l10n));
    add(_tabBar(l10n));

    switch (_tab) {
      case _PublisherTab.info:
        if (publisher.description != null && publisher.description!.isNotEmpty) {
          add(
            _Panel(
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
          add(_NoteLine(text: publisher.note!));
        }
        add(_statsSection(l10n, publisher));
        if (publisher.parent != null || publisher.imprints.isNotEmpty) {
          add(_Family(publisher: publisher, l10n: l10n));
        }
        if (publisher.aliases.isNotEmpty) {
          add(_Aliases(publisher: publisher, l10n: l10n));
        }
        if (publisher.links.isNotEmpty) {
          add(_Links(publisher: publisher, l10n: l10n));
        }
        add(_similarSection(l10n));
        if (loading) {
          add(
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: MbSpinner(size: 20, strokeWidth: 2)),
            ),
          );
        }
        for (final (shelf, title, sort) in _shelfDefs(l10n)) {
          add(_shelf(publisher, shelf, title, sort), bare: true);
        }
      case _PublisherTab.collections:
        for (final w in _collectionsItems(l10n)) {
          add(w);
        }
      case _PublisherTab.editions:
        for (final w in _editionsItems(l10n)) {
          add(w);
        }
    }

    // Extra room at the end keeps the last item clear of the system navigation
    // bar (viewPadding, as the scaffold does not consume it).
    final bottom = 32 + MediaQuery.viewPaddingOf(context).bottom;
    return ListView.builder(
      controller: _scroll,
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

  // ─── Collections & Editions ────────────────────────────────────────────────

  /// The Collections tab: edition filter pills, the collections, and a footer
  /// for the loading, retry and empty states.
  List<Widget> _collectionsItems(LocalizationService l10n) {
    final c = _collections;
    final names = c.editionNames;
    final filter = c.editionFilter;
    final shown = c.collections;

    return [
      if (names.length > 1)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Align(
            alignment: Alignment.centerLeft,
            // A dropdown, like the Browse sort, instead of a pill per edition:
            // there are many editions and the pills wrapped into a wall.
            child: MbDropdown<String>(
              label: l10n.translate('editions'),
              value: filter ?? '',
              options: [
                ('', l10n.translate('all_editions')),
                for (final name in names) (name, name),
              ],
              onChanged: (key) => c.setEditionFilter(key.isEmpty ? null : key),
            ),
          ),
        ),
      for (final collection in shown)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CollectionCard(
            collection: collection,
            showPublisher: false,
            onTap: () => _openCollection(collection),
          ),
        ),
      _collectionsFooter(l10n, shown.isEmpty),
    ];
  }

  Widget _collectionsFooter(LocalizationService l10n, bool empty) {
    final c = _collections;
    if (c.loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: MbSpinner()),
      );
    }
    if (c.failed) {
      return Center(
        child: TextButton(
          onPressed: c.loadMore,
          child: Text(l10n.translate('retry')),
        ),
      );
    }
    if (empty && !c.hasNext) {
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

  /// The Editions tab: every edition with what it means. Choosing one narrows
  /// the collections to it and shows them.
  List<Widget> _editionsItems(LocalizationService l10n) {
    final c = _collections;
    if (c.editionsFailed) {
      return [
        Center(
          child: TextButton(
            onPressed: c.ensureEditions,
            child: Text(l10n.translate('retry')),
          ),
        ),
      ];
    }
    final editions = c.editions;
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
        _EditionTile(
          edition: e,
          selected: c.editionFilter == e.name,
          onTap: () => _pickEdition(e),
        ),
    ];
  }

  List<(PublisherShelf, String, String?)> _shelfDefs(LocalizationService l10n) => [
        (PublisherShelf.newest, l10n.translate('publisher_shelf_newest'), 'published_start_date_desc'),
        (PublisherShelf.popular, l10n.translate('publisher_shelf_popular'), 'popularity_desc'),
        (PublisherShelf.highestRated, l10n.translate('publisher_shelf_highest_rated'), 'score_desc'),
        (PublisherShelf.trending, l10n.translate('trending'), 'trending_7d'),
        (PublisherShelf.hiddenGems, l10n.translate('hidden_gems'), null),
      ];

  /// One series rail. Loads on its own and drops out if it fails or is empty.
  Widget _shelf(Publisher publisher, PublisherShelf shelf, String title, String? sort) {
    return FutureBuilder<List<Series>>(
      future: _shelves[shelf],
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        return HomeRail(
          title: title,
          heroScopeId: 'publisher_${publisher.id}_${shelf.name}',
          series: snapshot.data ?? const [],
          loading: !snapshot.hasData,
          onViewAll: sort == null
              ? null
              : () => Navigator.of(context).push(
                    AppTransitions.slideRight(
                      BrowseResultsScreen(
                        sortType: title,
                        sortBy: sort,
                        publisher: publisher.name,
                        publisherId: publisher.id,
                        refineLabel: title,
                      ),
                    ),
                  ),
        );
      },
    );
  }

  Widget _statsSection(LocalizationService l10n, Publisher publisher) {
    return FutureBuilder<PublisherStats>(
      future: _stats,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _SectionError(
            label: l10n.translate('publisher_stats'),
            onRetry: _retry,
            l10n: l10n,
          );
        }
        final stats = snapshot.data;
        if (stats == null) return const _SectionLoading();
        if (stats.seriesCount == 0) return const SizedBox.shrink();
        return _StatsView(
          stats: stats,
          publisher: publisher,
          l10n: l10n,
        );
      },
    );
  }

  Widget _similarSection(LocalizationService l10n) {
    return FutureBuilder<List<SimilarPublisher>>(
      future: _similar,
      builder: (context, snapshot) {
        final items = snapshot.data;
        if (snapshot.hasError || items == null || items.isEmpty) {
          return const SizedBox.shrink();
        }
        return _Panel(
          label: l10n.translate('publisher_similar'),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in items)
                MbPill(
                  label: s.name,
                  icon: Icons.business_rounded,
                  onTap: () => PublisherDetailScreen.open(
                    context,
                    id: s.id,
                    name: s.name,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// One edition: its name and what it means.
class _EditionTile extends StatelessWidget {
  final Edition edition;
  final bool selected;
  final VoidCallback onTap;

  const _EditionTile({
    required this.edition,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          edition.name.toUpperCase(),
          style: AppTypography.display(
            color: selected ? colors.accent : colors.text,
            fontSize: 14,
          ),
        ),
        if (edition.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            edition.description,
            style: AppTypography.sans(
              color: colors.textMuted,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DesktopLayout.isActive(context)
          ? DesktopHoverSurface(
              onTap: onTap,
              idleColor: colors.surface,
              borderRadius: BorderRadius.circular(DesktopTokens.panelRadius),
              padding: const EdgeInsets.all(18),
              child: SizedBox(width: double.infinity, child: content),
            )
          : Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(width: double.infinity, child: content),
                ),
              ),
            ),
    );
  }
}

// ─── Header & actions ────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Publisher publisher;
  final LocalizationService l10n;

  const _Header({required this.publisher, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final facts = <String>[
      if (publisher.countryOfOrigin != null && publisher.countryOfOrigin!.isNotEmpty)
        publisher.countryOfOrigin!,
      if (publisher.languages.isNotEmpty)
        publisher.languages.map((l) => l.toUpperCase()).join(' · '),
      if (publisher.founded != null)
        l10n.translate('publisher_established').replaceAll('{year}', '${publisher.founded}'),
      if (publisher.seriesCount != null)
        l10n
            .translate('publisher_series_count')
            .replaceAll('{count}', formatCount(publisher.seriesCount!)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PublisherLogoView(publisher: publisher, size: 72),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  publisher.name,
                  style: AppTypography.display(
                    color: context.colors.text,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (publisher.subType.isNotEmpty)
                      _Badge(text: publisher.subType.toUpperCase()),
                    if (publisher.closed != null)
                      Text(
                        l10n
                            .translate('publisher_closed')
                            .replaceAll('{year}', '${publisher.closed}'),
                        style: AppTypography.sans(
                          color: context.colors.error.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    for (final fact in facts)
                      Text(
                        fact,
                        style: AppTypography.sans(
                          color: context.colors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTypography.monoLabel(
          color: context.colors.accent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _NoteLine extends StatelessWidget {
  final String text;

  const _NoteLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 16, color: context.colors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.sans(
              color: context.colors.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Family, aliases, links ──────────────────────────────────────────────────

class _Family extends StatelessWidget {
  final Publisher publisher;
  final LocalizationService l10n;

  const _Family({required this.publisher, required this.l10n});

  @override
  Widget build(BuildContext context) {
    Widget pill(Publisher p) => MbPill(
          label: p.name,
          icon: Icons.business_rounded,
          onTap: p.id.isEmpty
              ? null
              : () => PublisherDetailScreen.open(
                    context,
                    id: p.id,
                    publisher: p,
                  ),
        );

    return _Panel(
      label: publisher.parent != null && publisher.imprints.isEmpty
          ? l10n.translate('publisher_parent')
          : l10n.translate('publisher_imprints_title'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (publisher.parent != null) ...[
            _SubLabel(l10n.translate('publisher_parent')),
            const SizedBox(height: 8),
            Wrap(children: [pill(publisher.parent!)]),
            if (publisher.imprints.isNotEmpty) const SizedBox(height: 14),
          ],
          if (publisher.imprints.isNotEmpty) ...[
            if (publisher.parent != null) ...[
              _SubLabel(l10n.translate('publisher_imprints_title')),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final i in publisher.imprints) pill(i)],
            ),
          ],
        ],
      ),
    );
  }
}

class _SubLabel extends StatelessWidget {
  final String text;

  const _SubLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: AppTypography.monoLabel(
          color: context.colors.textMuted,
          fontSize: 10,
        ),
      );
}

class _Aliases extends StatelessWidget {
  final Publisher publisher;
  final LocalizationService l10n;

  const _Aliases({required this.publisher, required this.l10n});

  @override
  Widget build(BuildContext context) {
    // Machine-generated spelling variants ("SHueisha") drown out the useful
    // names, so native and official titles lead and the rest follow.
    final aliases = [...publisher.aliases]
      ..sort((a, b) => _rank(a).compareTo(_rank(b)));
    return _Panel(
      label: l10n.translate('publisher_aliases'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final a in aliases.take(12))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  if (a.language.isNotEmpty && a.language != 'unknown')
                    SizedBox(
                      width: 32,
                      child: Text(
                        a.language.toUpperCase(),
                        style: AppTypography.monoLabel(
                          color: context.colors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      a.title,
                      style: AppTypography.sans(
                        color: context.colors.text,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static int _rank(PublisherAlias a) => switch (a.type) {
        'native' => 0,
        'official' => 1,
        _ => 2,
      };
}

class _Links extends StatelessWidget {
  final Publisher publisher;
  final LocalizationService l10n;

  const _Links({required this.publisher, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      label: l10n.translate('publisher_links'),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final link in publisher.links)
            if (Uri.tryParse(link.link) case final uri? when uri.hasScheme)
              MbPill(
                label: link.type.isEmpty ? uri.host : '${_cap(link.type)} · ${uri.host}',
                icon: Icons.link_rounded,
                onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
              ),
        ],
      ),
    );
  }
}

// ─── Stats ───────────────────────────────────────────────────────────────────

class _StatsView extends StatelessWidget {
  final PublisherStats stats;
  final Publisher publisher;
  final LocalizationService l10n;

  const _StatsView({
    required this.stats,
    required this.publisher,
    required this.l10n,
  });

  void _browse(BuildContext context, {String? genre, String? tag, required String refine}) {
    Navigator.of(context).push(
      AppTransitions.slideRight(
        BrowseResultsScreen(
          sortType: '${publisher.name} · $refine',
          sortBy: 'popularity_desc',
          publisher: publisher.name,
          publisherId: publisher.id,
          genre: genre,
          tag: tag,
          refineLabel: refine,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsManager(),
      builder: (context, _) => _build(
        context,
        SettingsManager().publisherStatsStyle == PublisherStatsStyle.charts,
      ),
    );
  }

  Widget _build(BuildContext context, bool charts) {
    final colors = context.colors;
    final tiles = <(String, String)>[
      (l10n.translate('publisher_series'), formatCount(stats.seriesCount)),
      if (stats.averageScore != null)
        (l10n.translate('publisher_stat_avg_score'), (stats.averageScore! / 10).toStringAsFixed(1)),
      if (stats.firstYear != null && stats.lastYear != null)
        (
          l10n.translate('publisher_stat_years'),
          stats.firstYear == stats.lastYear
              ? '${stats.firstYear}'
              : '${stats.firstYear}–${stats.lastYear}',
        ),
      if (stats.hasAnime > 0)
        (l10n.translate('publisher_stat_anime'), formatCount(stats.hasAnime)),
    ];

    List<ChartEntry> entries(
      List<StatBucket> b, {
      String Function(String)? label,
      Color Function(String)? color,
    }) =>
        [
          for (final e in b)
            ChartEntry(
              (label ?? _cap)(e.key),
              e.count,
              color: color?.call(e.key),
            ),
        ];

    Color statusColor(String k) => switch (k) {
          'completed' => colors.success,
          'releasing' => colors.info,
          'hiatus' => colors.warning,
          'cancelled' => colors.error,
          _ => colors.textMuted,
        };
    Color ratingColor(String k) => switch (k) {
          'safe' => colors.success,
          'suggestive' => colors.warning,
          'erotica' => colors.error.withValues(alpha: 0.75),
          'pornographic' => colors.error,
          _ => colors.textMuted,
        };

    Widget section(String label, Widget child) => Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_SubLabel(label), const SizedBox(height: 8), child],
          ),
        );

    Widget bars(List<ChartEntry> e) =>
        _BarList(entries: [for (final x in e) (x.label, x.count)]);

    final decades = entries(stats.decades, label: (k) => '${k}s');
    final media = entries(stats.mediaTypes);
    final status = entries(stats.statuses, color: statusColor);
    final ratings = entries(stats.contentRatings, color: ratingColor);

    return _Panel(
      label: l10n.translate('publisher_stats'),
      trailing: _StyleToggle(charts: charts),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [for (final (label, value) in tiles) _StatTile(label: label, value: value)],
          ),
          // Each kind of data gets the chart that reads best: time-ordered
          // data as columns, unordered categories as bars, parts of a whole as
          // one stacked bar, and tags as share-of-catalog bars. "List" falls
          // back to plain rows for all of them.
          if (decades.length > 1)
            section(
              l10n.translate('publisher_by_decade'),
              charts ? ColumnChart(entries: decades) : bars(decades),
            ),
          if (media.length > 1)
            section(
              l10n.translate('publisher_media_types'),
              charts ? BarChartRows(entries: media) : bars(media),
            ),
          if (status.length > 1)
            section(
              l10n.translate('status'),
              charts ? StackedBarChart(entries: status) : bars(status),
            ),
          if (ratings.length > 1)
            section(
              l10n.translate('content_rating'),
              charts ? StackedBarChart(entries: ratings) : bars(ratings),
            ),
          if (stats.knownFor.isNotEmpty)
            _tagBlock(context, l10n.translate('publisher_known_for'), stats.knownFor, byGenre: false, charts: charts),
          if (stats.genres.isNotEmpty)
            _tagBlock(context, l10n.translate('publisher_genres'), stats.genres, byGenre: true, charts: charts),
          if (stats.audience.isNotEmpty)
            _tagBlock(context, l10n.translate('publisher_audience'), stats.audience, byGenre: false, charts: charts),
          if (stats.sharesWith.isNotEmpty)
            section(
              l10n.translate('publisher_shares_with'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in stats.sharesWith.take(10))
                    MbPill(
                      label: p.name,
                      icon: Icons.business_rounded,
                      trailingText: formatCount(p.sharedCount),
                      onTap: p.id.isEmpty
                          ? null
                          : () => PublisherDetailScreen.open(
                                context,
                                id: p.id,
                                name: p.name,
                              ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tagBlock(
    BuildContext context,
    String label,
    List<StatTag> tags, {
    required bool byGenre,
    required bool charts,
  }) {
    void open(StatTag t) => byGenre
        ? _browse(context, genre: t.name, refine: t.name)
        : _browse(context, tag: t.id, refine: t.name);

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubLabel(label),
          const SizedBox(height: 8),
          if (charts)
            Column(
              children: [
                for (final t in tags.take(8))
                  ShareBarRow(
                    label: t.name,
                    share: t.share,
                    catalogShare: t.catalogShare,
                    count: t.count,
                    onTap: () => open(t),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.translate('publisher_share_legend'),
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in tags.take(10))
                  MbPill(
                    label: t.name,
                    trailingText: formatCount(t.count),
                    onTap: () => open(t),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Switches the stats between charts and plain rows; remembered across visits.
class _StyleToggle extends StatelessWidget {
  final bool charts;

  const _StyleToggle({required this.charts});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget button(IconData icon, bool selected, PublisherStatsStyle style) =>
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => SettingsManager().setPublisherStatsStyle(style),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: selected ? colors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: selected ? colors.onAccent : colors.textMuted,
            ),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(Icons.bar_chart_rounded, charts, PublisherStatsStyle.charts),
        button(Icons.view_list_rounded, !charts, PublisherStatsStyle.list),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.display(color: context.colors.accent, fontSize: 22),
        ),
        const SizedBox(height: 2),
        _SubLabel(label),
      ],
    );
  }
}

/// Horizontal proportional bars: a label, a bar scaled to the largest entry,
/// and the count.
class _BarList extends StatelessWidget {
  final List<(String, int)> entries;

  const _BarList({required this.entries});

  @override
  Widget build(BuildContext context) {
    final max = entries.fold<int>(0, (m, e) => e.$2 > m ? e.$2 : m);
    if (max == 0) return const SizedBox.shrink();
    return Column(
      children: [
        for (final (label, count) in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 88,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      color: context.colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: count / max,
                      minHeight: 8,
                      backgroundColor: context.colors.surfaceRaised,
                      valueColor: AlwaysStoppedAnimation(context.colors.accent),
                    ),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    formatCount(count),
                    textAlign: TextAlign.end,
                    style: AppTypography.sans(
                      color: context.colors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: MbSpinner(size: 20, strokeWidth: 2)),
      );
}

class _SectionError extends StatelessWidget {
  final String label;
  final VoidCallback onRetry;
  final LocalizationService l10n;

  const _SectionError({
    required this.label,
    required this.onRetry,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      label: label,
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: onRetry,
          child: Text(l10n.translate('retry')),
        ),
      ),
    );
  }
}

String _cap(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');

/// The page's card surface: the phone's [MbCard], or the desktop's flat panel
/// with a display-caps section title.
class _Panel extends StatelessWidget {
  final String? label;
  final Widget? trailing;
  final Widget child;

  const _Panel({this.label, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!DesktopLayout.isActive(context)) {
      return MbCard(label: label, trailing: trailing, child: child);
    }
    return DesktopCard(
      showBorder: false,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null)
            DesktopSectionTitle(
              title: label!,
              trailing: trailing,
              fontSize: 16,
              padding: const EdgeInsets.only(bottom: 14),
            ),
          child,
        ],
      ),
    );
  }
}

/// The desktop identity card: a large logo, the name and its facts, then the
/// description and any note at reading width.
class _DesktopIdentity extends StatelessWidget {
  final Publisher publisher;
  final LocalizationService l10n;
  final bool loading;

  const _DesktopIdentity({
    required this.publisher,
    required this.l10n,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final facts = <String>[
      if (publisher.countryOfOrigin != null && publisher.countryOfOrigin!.isNotEmpty)
        publisher.countryOfOrigin!,
      if (publisher.languages.isNotEmpty)
        publisher.languages.map((l) => l.toUpperCase()).join(' · '),
      if (publisher.founded != null)
        l10n.translate('publisher_established').replaceAll('{year}', '${publisher.founded}'),
      if (publisher.seriesCount != null)
        l10n
            .translate('publisher_series_count')
            .replaceAll('{count}', formatCount(publisher.seriesCount!)),
    ];
    final description = publisher.description;

    return DesktopCard(
      showBorder: false,
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PublisherLogoView(publisher: publisher, size: 112),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      publisher.name,
                      style: AppTypography.display(
                        color: colors.text,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (publisher.subType.isNotEmpty)
                          _Badge(text: publisher.subType.toUpperCase()),
                        if (publisher.closed != null)
                          Text(
                            l10n
                                .translate('publisher_closed')
                                .replaceAll('{year}', '${publisher.closed}'),
                            style: AppTypography.sans(
                              color: colors.error.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        for (final fact in facts)
                          Text(
                            fact,
                            style: AppTypography.monoLabel(
                              color: colors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (loading) const MbSpinner(size: 20, strokeWidth: 2),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 22),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: DesktopTokens.readableWidth,
              ),
              child: Text(
                description,
                style: AppTypography.sans(
                  color: colors.text,
                  fontSize: 14.5,
                  height: 1.55,
                ),
              ),
            ),
          ],
          if (publisher.note != null && publisher.note!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _NoteLine(text: publisher.note!),
          ],
        ],
      ),
    );
  }
}

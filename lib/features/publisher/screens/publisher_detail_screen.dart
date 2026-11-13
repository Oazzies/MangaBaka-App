import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/collections/models/edition.dart';
import 'package:mangabaka_app/features/collections/screens/collection_detail_screen.dart';
import 'package:mangabaka_app/features/publisher/controllers/publisher_collections_controller.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_desktop_body.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_metadata_panels.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_mobile_body.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_panel.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_stats_panel.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

/// One publisher: who they are, what they publish, and who they resemble.
class PublisherDetailScreen extends StatefulWidget {
  final String publisherId;
  final Publisher? initial;
  final String? name;
  final PublisherSearchService? service;

  const PublisherDetailScreen({
    super.key,
    required this.publisherId,
    this.initial,
    this.name,
    this.service,
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

class _PublisherDetailScreenState extends State<PublisherDetailScreen> {
  late final PublisherSearchService _service =
      widget.service ?? getIt<PublisherSearchService>();
  late final PublisherCollectionsController _collections =
      PublisherCollectionsController(widget.publisherId);
  final ScrollController _scroll = ScrollController();

  late Future<Publisher> _detail;
  late Future<PublisherStats> _stats;
  late Future<List<SimilarPublisher>> _similar;
  late Map<PublisherShelf, Future<List<Series>>> _shelves;
  late Future<void> _factsReady;
  late Future<void> _shelvesReady;

  PublisherDetailTab _tab = PublisherDetailTab.info;

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
    _stats = _service.getStats(widget.publisherId)..ignore();
    _similar = _service.getSimilar(widget.publisherId)..ignore();
    _shelves = {
      for (final shelf in PublisherShelf.values)
        shelf: _service.getShelf(widget.publisherId, shelf)..ignore(),
    };
    _factsReady = _settled([_stats, _similar]);
    _shelvesReady = _settled(_shelves.values);
  }

  static Future<void> _settled(Iterable<Future<Object?>> futures) =>
      Future.wait([
        for (final f in futures) f.then<void>((_) {}, onError: (Object _) {}),
      ]);

  void _retry() => setState(_load);
  String get _title => widget.initial?.name ?? widget.name ?? '';

  void _selectTab(PublisherDetailTab tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    if (_scroll.hasClients) _scroll.jumpTo(0);
    if (tab == PublisherDetailTab.collections) _collections.ensureCollections();
    if (tab == PublisherDetailTab.editions) _collections.ensureEditions();
  }

  void _onCollectionsChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMoreIfNeeded());
  }

  void _loadMoreIfNeeded() {
    if (!mounted ||
        _tab != PublisherDetailTab.collections ||
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
    _selectTab(PublisherDetailTab.collections);
  }

  void _openCollection(SeriesCollection collection) {
    Navigator.of(context).push(
      AppTransitions.slideRight(CollectionDetailScreen(collection: collection)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    if (DesktopLayout.isActive(context)) {
      return PublisherDesktopScaffold(
        detailFuture: _detail,
        initial: widget.initial,
        fallbackTitle: _title,
        tab: _tab,
        scrollController: _scroll,
        collectionsController: _collections,
        shelves: _shelves,
        onSelectTab: _selectTab,
        onRetry: _retry,
        onOpenCollection: _openCollection,
        onPickEdition: _pickEdition,
        onOpenPublisher: PublisherDetailScreen.open,
        buildStatsSection: _statsSection,
        buildSimilarSection: _similarSection,
      );
    }

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
        return PublisherMobileBody(
          publisher: publisher,
          l10n: l10n,
          tab: _tab,
          loading: !snapshot.hasData,
          scrollController: _scroll,
          collectionsController: _collections,
          factsReady: _factsReady,
          shelvesReady: _shelvesReady,
          shelves: _shelves,
          onSelectTab: _selectTab,
          onOpenPublisher: PublisherDetailScreen.open,
          onOpenCollection: _openCollection,
          onPickEdition: _pickEdition,
          buildStatsSection: _statsSection,
          buildSimilarSection: _similarSection,
        );
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

  Widget _statsSection(LocalizationService l10n, Publisher publisher) {
    return FutureBuilder<PublisherStats>(
      future: _stats,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return PublisherSectionError(
            label: l10n.translate('publisher_stats'),
            onRetry: _retry,
            l10n: l10n,
          );
        }
        final stats = snapshot.data;
        if (stats == null) return const PublisherSectionLoading();
        if (stats.seriesCount == 0) return const SizedBox.shrink();
        return PublisherStatsView(
          stats: stats,
          publisher: publisher,
          l10n: l10n,
          onOpenPublisher: PublisherDetailScreen.open,
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
        return PublisherSimilarPanel(
          items: items,
          l10n: l10n,
          onOpenPublisher: PublisherDetailScreen.open,
        );
      },
    );
  }
}

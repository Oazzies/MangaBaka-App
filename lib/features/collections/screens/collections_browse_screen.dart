import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/collections/models/edition.dart';
import 'package:mangabaka_app/features/collections/screens/collection_detail_screen.dart';
import 'package:mangabaka_app/features/collections/services/collection_service.dart';
import 'package:mangabaka_app/features/collections/widgets/collections_browse_scaffold.dart';
import 'package:mangabaka_app/features/collections/widgets/collections_browse_tabs.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

/// Browse collections and editions.
class CollectionsBrowseScreen extends StatefulWidget {
  final Publisher? initialPublisher;

  const CollectionsBrowseScreen({super.key, this.initialPublisher});

  static void open(BuildContext context, {Publisher? publisher}) =>
      Navigator.of(context).push(
        AppTransitions.slideRight(
          CollectionsBrowseScreen(initialPublisher: publisher),
        ),
      );

  @override
  State<CollectionsBrowseScreen> createState() =>
      _CollectionsBrowseScreenState();
}

class _CollectionsBrowseScreenState extends State<CollectionsBrowseScreen>
    with SingleTickerProviderStateMixin {
  static final _logger = LoggingService.logger;
  static const double _loadAhead = 700;

  late final TabController _tabs = TabController(length: 2, vsync: this);
  late final CollectionService _collections = getIt<CollectionService>();
  late final PublisherSearchService _publishers =
      getIt<PublisherSearchService>();

  final TextEditingController _query = TextEditingController();
  Timer? _debounce;
  final ScrollController _scroll = ScrollController();

  List<Publisher> _matches = const [];
  bool _searching = false;

  Publisher? _publisher;
  final List<SeriesCollection> _list = [];
  int _page = 1;
  bool _hasNext = false;
  bool _loadingList = false;
  bool _listFailed = false;
  String? _editionFilter;

  List<Edition>? _editions;
  bool _editionsFailed = false;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(_onTabChange);
    _scroll.addListener(_loadMoreIfNeeded);
    _loadEditions();
    if (widget.initialPublisher != null) {
      _publisher = widget.initialPublisher;
      _loadCollections();
    }
  }

  void _onTabChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChange);
    _scroll.removeListener(_loadMoreIfNeeded);
    _scroll.dispose();
    _debounce?.cancel();
    _query.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadEditions() async {
    setState(() => _editionsFailed = false);
    try {
      final editions = await _collections.fetchEditions();
      if (mounted) setState(() => _editions = editions);
    } catch (e) {
      _logger.warning('Editions failed: $e');
      if (mounted) setState(() => _editionsFailed = true);
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _matches = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String value) async {
    setState(() => _searching = true);
    try {
      final found = await _publishers.searchPublishers(
        query: value.trim(),
        limit: 20,
      );
      if (mounted && value == _query.text) {
        setState(() => _matches = found);
      }
    } catch (e) {
      _logger.warning('Publisher search failed: $e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _choosePublisher(Publisher publisher) {
    FocusScope.of(context).unfocus();
    setState(() {
      _publisher = publisher;
      _list.clear();
      _page = 1;
      _hasNext = false;
      _editionFilter = null;
    });
    _loadCollections();
  }

  void _clearPublisher() {
    setState(() {
      _publisher = null;
      _list.clear();
      _editionFilter = null;
    });
  }

  Future<void> _loadCollections() async {
    final publisher = _publisher;
    if (publisher == null || _loadingList) return;
    setState(() {
      _loadingList = true;
      _listFailed = false;
    });
    try {
      final page = await _collections.fetchPublisherCollections(
        publisher.id,
        page: _page,
      );
      if (!mounted || _publisher != publisher) return;
      setState(() {
        _list.addAll(page.items);
        _hasNext = page.hasNext;
        _page++;
      });
    } catch (e) {
      _logger.warning('Publisher collections failed: $e');
      if (mounted) setState(() => _listFailed = true);
    } finally {
      if (mounted) {
        setState(() => _loadingList = false);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _loadMoreIfNeeded(),
        );
      }
    }
  }

  void _loadMoreIfNeeded() {
    if (!mounted ||
        _publisher == null ||
        !_hasNext ||
        _loadingList ||
        _listFailed ||
        !_scroll.hasClients) {
      return;
    }
    final position = _scroll.position;
    if (position.maxScrollExtent - position.pixels < _loadAhead) {
      _loadCollections();
    }
  }

  void _pickEdition(Edition edition) {
    if (_publisher == null) return;
    setState(() => _editionFilter = edition.name);
    _tabs.animateTo(0);
  }

  void _openCollection(SeriesCollection collection) {
    Navigator.of(context).push(
      AppTransitions.slideRight(CollectionDetailScreen(collection: collection)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return DesktopLayout.isActive(context)
        ? CollectionsDesktopScaffold(
            l10n: l10n,
            publisherName: _publisher?.name,
            activeTab: _tabs.index,
            onTabChanged: (index) {
              _tabs.animateTo(index);
              setState(() {});
            },
            collectionsTab: _collectionsTab(l10n),
            editionsTab: _editionsTab(l10n),
          )
        : CollectionsMobileScaffold(
            l10n: l10n,
            tabs: _tabs,
            collectionsTab: _collectionsTab(l10n),
            editionsTab: _editionsTab(l10n),
          );
  }

  Widget _collectionsTab(LocalizationService l10n) => _publisher == null
      ? CollectionsPublisherPicker(
          l10n: l10n,
          query: _query,
          searching: _searching,
          matches: _matches,
          onQueryChanged: _onQueryChanged,
          onChoosePublisher: _choosePublisher,
        )
      : CollectionsPublisherList(
          l10n: l10n,
          scroll: _scroll,
          publisher: _publisher!,
          list: _list,
          editionFilter: _editionFilter,
          canChangePublisher: widget.initialPublisher == null,
          loadingList: _loadingList,
          listFailed: _listFailed,
          hasNext: _hasNext,
          onChangePublisher: _clearPublisher,
          onEditionFilterChanged: (key) =>
              setState(() => _editionFilter = key.isEmpty ? null : key),
          onOpenCollection: _openCollection,
          onRetry: _loadCollections,
        );

  Widget _editionsTab(LocalizationService l10n) => CollectionsEditionsTab(
    l10n: l10n,
    editionsFailed: _editionsFailed,
    editions: _editions,
    publisher: _publisher,
    editionFilter: _editionFilter,
    onRetry: _loadEditions,
    onPickEdition: _pickEdition,
  );
}

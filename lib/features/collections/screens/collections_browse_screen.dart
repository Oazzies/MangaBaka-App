import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_pill.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';
import 'package:mangabaka_app/features/collections/models/edition.dart';
import 'package:mangabaka_app/features/collections/screens/collection_detail_screen.dart';
import 'package:mangabaka_app/features/collections/services/collection_service.dart';
import 'package:mangabaka_app/features/collections/widgets/collection_card.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';

/// Browse collections and editions.
///
/// Collections belong to a publisher, so the Collections tab starts from one:
/// search for a publisher, then see its collections and narrow them by edition.
/// The Editions tab lists every edition with what it means; choosing one
/// narrows the open publisher's collections to it.
class CollectionsBrowseScreen extends StatefulWidget {
  final Publisher? initialPublisher;

  const CollectionsBrowseScreen({super.key, this.initialPublisher});

  /// Opens the browser over the current screen.
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

  late final TabController _tabs = TabController(length: 2, vsync: this);
  late final CollectionService _collections = getIt<CollectionService>();
  late final PublisherSearchService _publishers =
      getIt<PublisherSearchService>();

  final TextEditingController _query = TextEditingController();
  Timer? _debounce;

  /// Scrolls the open publisher's collections; watched so the next page loads
  /// as the end comes into view.
  final ScrollController _scroll = ScrollController();

  /// How close to the end of the list (in logical pixels) the next page starts
  /// loading — far enough ahead that the user rarely sees the end.
  static const double _loadAhead = 700;

  // Publisher search.
  List<Publisher> _matches = const [];
  bool _searching = false;

  // The open publisher's collections.
  Publisher? _publisher;
  final List<SeriesCollection> _list = [];
  int _page = 1;
  bool _hasNext = false;
  bool _loadingList = false;
  bool _listFailed = false;
  String? _editionFilter;

  // Editions.
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

  // ─── Loading ───────────────────────────────────────────────────────────────

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
        // A page may not fill the window (a short page, or an edition filter
        // hiding most of it), and then there is no scrolling to trigger the
        // next one — so check again once the new items are laid out.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _loadMoreIfNeeded(),
        );
      }
    }
  }

  /// Loads the next page when the end of the list is near, or already in view.
  ///
  /// Stops on a failed load rather than retrying in a loop; the retry button
  /// is the user's to press.
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

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    if (DesktopLayout.isActive(context)) {
      return _buildDesktop(l10n);
    }
    return _buildMobile(l10n);
  }

  Widget _buildDesktop(LocalizationService l10n) {
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
            title: l10n.translate('collections_and_editions'),
            subtitle: _publisher?.name,
            actions: [
              DesktopSegmented<int>(
                value: _tabs.index,
                segments: [
                  (
                    0,
                    l10n.translate('tab_collections'),
                    Icons.collections_bookmark_rounded,
                  ),
                  (1, l10n.translate('editions'), Icons.auto_stories_rounded),
                ],
                onChanged: (index) {
                  _tabs.animateTo(index);
                  setState(() {});
                },
              ),
            ],
          ),
          Expanded(
            child: WidgetUtils.responsiveConstraint(
              maxWidth: 960,
              // Not a TabBarView: its sideways page slide is a phone gesture.
              // With a click and a wide window the tabs fade over one another
              // instead, and each keeps its scroll position.
              Stack(
                children: [
                  for (final (index, tab) in [
                    _collectionsTab(l10n),
                    _editionsTab(l10n),
                  ].indexed)
                    Positioned.fill(
                      child: _DesktopTabLayer(
                        active: _tabs.index == index,
                        child: tab,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(LocalizationService l10n) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: mbScreenAppBar(
        title: l10n.translate('collections_and_editions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.surfaceRaised,
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
              ),
              child: TabBar(
                controller: _tabs,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: context.colors.accent,
                  borderRadius: BorderRadius.circular(AppConstants.pillRadius),
                ),
                indicatorPadding: EdgeInsets.zero,
                labelColor: context.colors.onAccent,
                unselectedLabelColor: context.colors.textMuted,
                labelStyle: AppTypography.display(fontSize: 12),
                unselectedLabelStyle: AppTypography.display(fontSize: 12),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
                tabs: [
                  Tab(
                    height: 36,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.collections_bookmark_rounded,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.translate('tab_collections').toUpperCase()),
                      ],
                    ),
                  ),
                  Tab(
                    height: 36,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_stories_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text(l10n.translate('editions').toUpperCase()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: WidgetUtils.responsiveConstraint(
        maxWidth: 900,
        TabBarView(
          controller: _tabs,
          children: [_collectionsTab(l10n), _editionsTab(l10n)],
        ),
      ),
    );
  }

  Widget _collectionsTab(LocalizationService l10n) {
    return _publisher == null ? _publisherPicker(l10n) : _publisherList(l10n);
  }

  Widget _publisherPicker(LocalizationService l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        TextField(
          controller: _query,
          onChanged: _onQueryChanged,
          textInputAction: TextInputAction.search,
          style: AppTypography.sans(color: context.colors.text),
          decoration: InputDecoration(
            hintText: l10n.translate('search_publishers_hint'),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: MbSpinner(size: 16, strokeWidth: 2),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        if (_matches.isEmpty && _query.text.trim().isEmpty)
          _hint(l10n.translate('collections_pick_publisher'))
        else if (_matches.isEmpty && !_searching)
          _hint(l10n.translate('no_results'))
        else
          for (final p in _matches)
            _PublisherRow(publisher: p, onTap: () => _choosePublisher(p)),
      ],
    );
  }

  Widget _publisherList(LocalizationService l10n) {
    final publisher = _publisher!;
    final filter = _editionFilter;
    final shown = filter == null
        ? _list
        : _list.where((c) => c.editionName == filter).toList();
    final editionNames = {
      for (final c in _list)
        if (c.editionName.isNotEmpty) c.editionName,
    }.toList()..sort();

    // The leading blocks are single list items; the collections follow one per
    // item, so a long list only builds what is on screen.
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(color: context.colors.border),
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
                            color: context.colors.text,
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
                                  color: context.colors.accent.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  publisher.subType.toUpperCase(),
                                  style: AppTypography.monoLabel(
                                    color: context.colors.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (publisher.founded != null)
                              Text(
                                l10n
                                    .translate('publisher_established')
                                    .replaceAll('{year}', publisher.founded.toString()),
                                style: AppTypography.sans(
                                  color: context.colors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (publisher.closed != null)
                              Text(
                                l10n
                                    .translate('publisher_closed')
                                    .replaceAll('{year}', publisher.closed.toString()),
                                style: AppTypography.sans(
                                  color: context.colors.error.withValues(
                                    alpha: 0.8,
                                  ),
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
                  if (widget.initialPublisher == null)
                    TextButton(
                      onPressed: _clearPublisher,
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
                    color: context.colors.textMuted,
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
                  foregroundColor: context.colors.text,
                  side: BorderSide(color: context.colors.border),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MbPill(
                label: l10n.translate('all_editions'),
                selected: filter == null,
                onTap: () => setState(() => _editionFilter = null),
              ),
              for (final name in editionNames)
                MbPill(
                  label: name,
                  selected: filter == name,
                  onTap: () => setState(() => _editionFilter = name),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
      ],
    );

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      // Header, the collections, then one footer item for the loading, retry
      // and empty states.
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
              onTap: () => _openCollection(c),
            ),
          );
        }
        return _listFooter(l10n, shown.isEmpty);
      },
    );
  }

  /// What sits under the collections: a spinner while a page loads, a retry
  /// after a failure, or the empty message. Nothing otherwise — the next page
  /// loads on its own as the end nears.
  Widget _listFooter(LocalizationService l10n, bool empty) {
    if (_loadingList) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: MbSpinner()),
      );
    }
    if (_listFailed) {
      return Center(
        child: TextButton(
          onPressed: _loadCollections,
          child: Text(l10n.translate('retry')),
        ),
      );
    }
    if (empty && !_hasNext) {
      return _hint(l10n.translate('no_collections_available'));
    }
    return const SizedBox.shrink();
  }

  Widget _editionsTab(LocalizationService l10n) {
    if (_editionsFailed) {
      return Center(
        child: TextButton(
          onPressed: _loadEditions,
          child: Text(l10n.translate('retry')),
        ),
      );
    }
    final editions = _editions;
    if (editions == null) {
      return const Center(child: MbSpinner());
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (_publisher == null)
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
        for (final e in editions)
          _EditionRow(
            edition: e,
            selected: _editionFilter == e.name,
            onTap: _publisher == null ? null : () => _pickEdition(e),
          ),
      ],
    );
  }

  Widget _hint(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.sans(color: context.colors.textMuted),
      ),
    ),
  );
}

class _PublisherRow extends StatelessWidget {
  final Publisher publisher;
  final VoidCallback onTap;

  const _PublisherRow({required this.publisher, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    publisher.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      color: context.colors.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.colors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditionRow extends StatelessWidget {
  final Edition edition;
  final bool selected;
  final VoidCallback? onTap;

  const _EditionRow({
    required this.edition,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edition.name.toUpperCase(),
                  style: AppTypography.display(
                    color: selected
                        ? context.colors.accent
                        : context.colors.text,
                    fontSize: 14,
                  ),
                ),
                if (edition.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    edition.description,
                    style: AppTypography.sans(
                      color: context.colors.textMuted,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One tab of the desktop Collections/Editions switcher.
///
/// All tabs stay laid out under one another; the active one fades in with a
/// slight rise while the others fade out and stop taking clicks or focus. The
/// outgoing tab clears quickly and the incoming one waits a beat, so the two
/// are never both half-visible for long.
class _DesktopTabLayer extends StatelessWidget {
  final bool active;
  final Widget child;

  const _DesktopTabLayer({required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !active,
      child: ExcludeFocus(
        excluding: !active,
        child: ExcludeSemantics(
          excluding: !active,
          child: AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: const Duration(milliseconds: 260),
            curve: active
                ? const Interval(0.3, 1, curve: Curves.easeOut)
                : const Interval(0, 0.45, curve: Curves.easeIn),
            child: AnimatedSlide(
              offset: active ? Offset.zero : const Offset(0, 0.02),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

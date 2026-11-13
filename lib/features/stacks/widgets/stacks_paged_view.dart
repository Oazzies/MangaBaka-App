import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_status_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/models/stacks_list_source.dart';
import 'package:mangabaka_app/features/stacks/services/stack_exceptions.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';
import 'package:mangabaka_app/features/stacks/widgets/stacks_grid.dart';
import 'package:mangabaka_app/features/stacks/widgets/stacks_paged_filter_bar.dart';

/// A grid of the stacks from [source], loading the next page as the end
/// comes near, with pull-to-refresh, filters for a series' stacks, and the
/// empty, error and loading states.
class StacksPagedView extends StatefulWidget {
  final StacksListSource source;

  /// Slivers above the grid (a create button on "My stacks").
  final List<Widget> leading;

  const StacksPagedView({
    super.key,
    required this.source,
    this.leading = const [],
  });

  @override
  State<StacksPagedView> createState() => StacksPagedViewState();
}

class StacksPagedViewState extends State<StacksPagedView> {
  static const double _loadAhead = 700;

  late final StackService _service = getIt<StackService>();
  final LocalizationService _l10n = LocalizationService();
  final ScrollController _scroll = ScrollController();

  final List<StackSummary> _items = [];
  int _page = 0;
  bool _hasNext = true;
  bool _loading = false;
  Object? _error;
  StackSort _sort = StackSort.mostVoted;
  StackSpoilerFilter _spoilers = StackSpoilerFilter.exclude;

  /// Bumped on every reset so a page from a superseded query is dropped.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
    if (widget.source.personal) _revision.addListener(reload);
    _loadMore();
  }

  /// Held from initState: the locator may be reset before dispose runs.
  late final ValueNotifier<int> _revision =
      getIt<StackStatusController>().listsRevision;

  @override
  void dispose() {
    if (widget.source.personal) _revision.removeListener(reload);
    _scroll.dispose();
    super.dispose();
  }

  /// Starts again from the first page.
  void reload() {
    if (!mounted) return;
    setState(() {
      _generation++;
      _items.clear();
      _page = 0;
      _hasNext = true;
      _loading = false;
      _error = null;
    });
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasNext) return;
    final generation = _generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.source.load(
        _service,
        _page + 1,
        sort: _sort,
        spoilers: _spoilers,
      );
      if (!mounted || generation != _generation) return;
      final seen = _items.map((s) => s.id).toSet();
      setState(() {
        _page++;
        _items.addAll(page.items.where((s) => seen.add(s.id)));
        _hasNext = page.hasNext;
        _loading = false;
      });
      getIt<StackStatusController>().request(page.items.map((s) => s.id));
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  void _maybeLoadMore() {
    if (!mounted || !_scroll.hasClients || _error != null) return;
    final p = _scroll.position;
    if (p.maxScrollExtent - p.pixels < _loadAhead) _loadMore();
  }

  Future<void> _refresh() async => reload();

  @override
  Widget build(BuildContext context) {
    final desktop = DesktopLayout.isActive(context);
    final pad = desktop
        ? DesktopTokens.pagePadding
        : AppConstants.horizontalPadding;
    final subtitle = widget.source.subtitle(_l10n);

    final scroll = RefreshIndicator(
      color: context.colors.accent,
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scroll,
        slivers: [
          ...widget.leading,
          if (!desktop && subtitle != null)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, 4, pad, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  subtitle,
                  style: AppTypography.sans(
                    color: context.colors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          if (widget.source.filterable)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, 4, pad, 14),
              sliver: SliverToBoxAdapter(
                child: StacksPagedFilterBar(
                  l10n: _l10n,
                  sort: _sort,
                  spoilers: _spoilers,
                  onSortChanged: (s) {
                    if (s == _sort) return;
                    _sort = s;
                    reload();
                  },
                  onSpoilersChanged: (s) {
                    if (s == _spoilers) return;
                    _spoilers = s;
                    reload();
                  },
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(pad, 8, pad, 8),
            sliver: _content(),
          ),
          SliverToBoxAdapter(child: _footer()),
        ],
      ),
    );
    if (!desktop) return scroll;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: DesktopTokens.maxPageWidth),
        child: scroll,
      ),
    );
  }

  Widget _content() {
    if (_items.isEmpty && !_loading && _error == null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Column(
            children: [
              Icon(
                Icons.layers_outlined,
                size: 44,
                color: context.colors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                _l10n.translate('stacks_empty'),
                textAlign: TextAlign.center,
                style: AppTypography.sans(
                  color: context.colors.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SliverStackGrid(
      stacks: _items,
      loading: _loading,
      showVisibility: widget.source.ownerView,
    );
  }

  Widget _footer() {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              stackErrorMessage(_error!, _l10n),
              textAlign: TextAlign.center,
              style: AppTypography.sans(
                color: context.colors.textMuted,
                fontSize: 14,
              ),
            ),
            TextButton(
              onPressed: _loadMore,
              child: Text(_l10n.translate('retry')),
            ),
          ],
        ),
      );
    }
    if (_loading && _items.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: MbSpinner()),
      );
    }
    return const SizedBox(height: 40);
  }
}

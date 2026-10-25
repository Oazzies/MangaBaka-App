import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/network/paged_list.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_dropdown.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_status_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/services/stack_exceptions.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';
import 'package:mangabaka_app/features/stacks/widgets/stacks_grid.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

/// Which stacks a [StacksListScreen] pages through.
sealed class StacksListSource {
  const StacksListSource();

  const factory StacksListSource.newest() = _Newest;
  const factory StacksListSource.featured() = _Featured;
  const factory StacksListSource.series(String seriesId, String seriesTitle) =
      _ForSeries;
  const factory StacksListSource.user(String username, String name) = _ByUser;
  const factory StacksListSource.mine() = _Mine;
  const factory StacksListSource.saved() = _Saved;
  const factory StacksListSource.followed() = _Followed;

  String title(LocalizationService l10n);

  /// Shown above the grid, when there is something to say.
  String? subtitle(LocalizationService l10n) => null;

  /// Whether the series sort and spoiler filters apply.
  bool get filterable => false;

  /// Whether cards show the owner's view (draft / unlisted).
  bool get ownerView => false;

  /// Whether the list is the reader's own (mine, saved, followed), and so
  /// reloads when [StackStatusController.listsRevision] moves.
  bool get personal => false;

  Future<PagedList<StackSummary>> load(
    StackService service,
    int page, {
    StackSort sort = StackSort.mostVoted,
    StackSpoilerFilter spoilers = StackSpoilerFilter.exclude,
  });
}

class _Newest extends StacksListSource {
  const _Newest();
  @override
  String title(LocalizationService l10n) => l10n.translate('stacks_new');
  @override
  Future<PagedList<StackSummary>> load(
    s,
    page, {
    sort = StackSort.mostVoted,
    spoilers = StackSpoilerFilter.exclude,
  }) => s.browse(page: page);
}

class _Featured extends StacksListSource {
  const _Featured();
  @override
  String title(LocalizationService l10n) => l10n.translate('stacks_featured');
  @override
  Future<PagedList<StackSummary>> load(
    s,
    page, {
    sort = StackSort.mostVoted,
    spoilers = StackSpoilerFilter.exclude,
  }) => s.browse(page: page, featured: true);
}

class _ForSeries extends StacksListSource {
  final String seriesId;
  final String seriesTitle;
  const _ForSeries(this.seriesId, this.seriesTitle);
  @override
  String title(LocalizationService l10n) => l10n.translate('stacks_in_these');
  @override
  String? subtitle(LocalizationService l10n) => seriesTitle;
  @override
  bool get filterable => true;
  @override
  Future<PagedList<StackSummary>> load(
    s,
    page, {
    sort = StackSort.mostVoted,
    spoilers = StackSpoilerFilter.exclude,
  }) => s.forSeries(seriesId, page: page, sort: sort, spoilers: spoilers);
}

class _ByUser extends StacksListSource {
  final String username;
  final String name;
  const _ByUser(this.username, this.name);
  @override
  String title(LocalizationService l10n) =>
      l10n.translate('stacks_by_user').replaceAll('{name}', name);
  @override
  Future<PagedList<StackSummary>> load(
    s,
    page, {
    sort = StackSort.mostVoted,
    spoilers = StackSpoilerFilter.exclude,
  }) => s.byUser(username, page: page);
}

class _Mine extends StacksListSource {
  const _Mine();
  @override
  bool get personal => true;
  @override
  String title(LocalizationService l10n) => l10n.translate('stacks_mine');
  @override
  bool get ownerView => true;
  @override
  Future<PagedList<StackSummary>> load(
    s,
    page, {
    sort = StackSort.mostVoted,
    spoilers = StackSpoilerFilter.exclude,
  }) => s.mine(page: page);
}

class _Saved extends StacksListSource {
  const _Saved();
  @override
  bool get personal => true;
  @override
  String title(LocalizationService l10n) => l10n.translate('stacks_saved');
  @override
  Future<PagedList<StackSummary>> load(
    s,
    page, {
    sort = StackSort.mostVoted,
    spoilers = StackSpoilerFilter.exclude,
  }) => s.saved(page: page);
}

class _Followed extends StacksListSource {
  const _Followed();
  @override
  bool get personal => true;
  @override
  String title(LocalizationService l10n) => l10n.translate('stacks_followed');
  @override
  Future<PagedList<StackSummary>> load(
    s,
    page, {
    sort = StackSort.mostVoted,
    spoilers = StackSpoilerFilter.exclude,
  }) => s.followed(page: page);
}

/// Pages through one [StacksListSource] as a full screen.
class StacksListScreen extends StatelessWidget {
  final StacksListSource source;

  const StacksListScreen({super.key, required this.source});

  static Future<void> open(BuildContext context, StacksListSource source) =>
      Navigator.of(
        context,
      ).push(AppTransitions.slideRight(StacksListScreen(source: source)));

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final title = source.title(l10n);
    if (DesktopLayout.isActive(context)) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesktopPageHeader(
              leading: DesktopIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: title,
              subtitle: source.subtitle(l10n) ?? l10n.translate('stacks'),
            ),
            Expanded(child: StacksPagedView(source: source)),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: mbScreenAppBar(title: title),
      body: StacksPagedView(source: source),
    );
  }
}

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
              sliver: SliverToBoxAdapter(child: _filters()),
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

  Widget _filters() {
    // Side by side on a phone, each taking half; wrapping chips on desktop.
    final phone =
        MediaQuery.sizeOf(context).width < 600 &&
        !DesktopLayout.isActive(context);
    final dropdowns = [
      MbDropdown<StackSort>(
        expand: phone,
        label: _l10n.translate('sort_by'),
        icon: Icons.sort_rounded,
        value: _sort,
        options: [
          for (final s in StackSort.values) (s, _l10n.translate(s.labelKey)),
        ],
        onChanged: (s) {
          if (s == _sort) return;
          _sort = s;
          reload();
        },
      ),
      MbDropdown<StackSpoilerFilter>(
        expand: phone,
        label: _l10n.translate('stacks_spoilers'),
        icon: Icons.visibility_off_outlined,
        value: _spoilers,
        options: [
          for (final s in StackSpoilerFilter.values)
            (s, _l10n.translate(s.labelKey)),
        ],
        onChanged: (s) {
          if (s == _spoilers) return;
          _spoilers = s;
          reload();
        },
      ),
    ];
    if (phone) {
      return LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 400
            ? Column(
                children: [
                  dropdowns[0],
                  const SizedBox(height: 8),
                  dropdowns[1],
                ],
              )
            : Row(
                children: [
                  Expanded(child: dropdowns[0]),
                  const SizedBox(width: 8),
                  Expanded(child: dropdowns[1]),
                ],
              ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: dropdowns,
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

import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/json_utils.dart';
import 'package:mangabaka_app/core/utils/markdown_utils.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/widgets/design/mb_dropdown.dart';
import 'package:mangabaka_app/core/widgets/design/mb_progress_bar.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/widgets/description_section.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_status_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_detail.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/screens/stack_editor_screen.dart';
import 'package:mangabaka_app/features/stacks/screens/stacks_list_screen.dart';
import 'package:mangabaka_app/features/stacks/services/stack_exceptions.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';
import 'package:mangabaka_app/features/stacks/utils/stack_format.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_action_bar.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_auth_gate.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_card.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_cover_fan.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_note_text.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:url_launcher/url_launcher.dart';

/// One stack: what it is about, who made it, and its ranked series.
///
/// Paints at once from a listing's [initial] summary, then loads the entries.
/// The owner sees their own drafts and hidden stacks too (read through the
/// owner endpoint), with Edit, visibility and Delete.
///
/// Phone portrait reads top to bottom. From [_twoPaneWidth] up (a phone in
/// landscape, a tablet, the desktop) the details sit in a column beside the
/// entries, so the list keeps the width.
class StackDetailScreen extends StatefulWidget {
  final int stackId;
  final StackSummary? initial;

  /// Read through the owner endpoint first (opened from "My stacks").
  final bool asOwner;

  const StackDetailScreen({
    super.key,
    required this.stackId,
    this.initial,
    this.asOwner = false,
  });

  static Future<void> open(
    BuildContext context, {
    required int id,
    StackSummary? initial,
    bool asOwner = false,
  }) {
    return Navigator.of(context).push(
      AppTransitions.slideRight(
        StackDetailScreen(stackId: id, initial: initial, asOwner: asOwner),
      ),
    );
  }

  @override
  State<StackDetailScreen> createState() => _StackDetailScreenState();
}

class _StackDetailScreenState extends State<StackDetailScreen> {
  static const double _twoPaneWidth = 860;
  static const double _sideWidth = 360;

  late final StackService _service = getIt<StackService>();
  late final ProfileAuthService _auth = getIt<ProfileAuthService>();
  final LocalizationService _l10n = LocalizationService();

  late Future<StackDetail> _detail;
  StackDetail? _loaded;
  StackEntrySort _sort = StackEntrySort.stackFirst;
  bool _spoilersRevealed = false;

  /// Whether the last load came through the owner endpoint.
  bool _ownerView = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _detail = _fetch().then((d) {
      if (mounted) setState(() => _loaded = d);
      getIt<StackStatusController>().refresh([d.id]);
      return d;
    });
  }

  Future<StackDetail> _fetch() async {
    final ownerReadable = stackAccess(_auth) == StackAccess.ready;
    if (widget.asOwner && ownerReadable) {
      _ownerView = true;
      return _service.fetchForEdit(widget.stackId);
    }
    try {
      _ownerView = false;
      return await _service.fetch(widget.stackId);
    } on StackApiException catch (e) {
      // A draft or hidden stack is a 404 publicly but opens for its owner.
      if (e.isNotFound && ownerReadable) {
        _ownerView = true;
        return _service.fetchForEdit(widget.stackId);
      }
      rethrow;
    }
  }

  void _retry() => setState(_load);

  Future<void> _refresh() async {
    setState(_load);
    try {
      await _detail;
    } catch (_) {}
  }

  StackSummary? get _summary => _loaded?.summary ?? widget.initial;

  bool get _isOwner {
    if (_ownerView) return true;
    final mine = _auth.cachedProfile?.preferredUsername;
    final owner = _summary?.owner.username;
    return mine != null &&
        owner != null &&
        mine.toLowerCase() == owner.toLowerCase();
  }

  // ─── Owner actions ─────────────────────────────────────────────────────────

  Future<void> _edit() async {
    final changed = await StackEditorScreen.open(
      context,
      stackId: widget.stackId,
    );
    if (changed == true && mounted) _refresh();
  }

  Future<void> _setVisibility(StackVisibility visibility) async {
    try {
      await _service.setVisibility(widget.stackId, visibility);
      getIt<StackStatusController>().markListsChanged();
      if (!mounted) return;
      AppSnackBar.show(context, _l10n.translate('stacks_visibility_changed'));
      _refresh();
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, stackErrorMessage(e, _l10n), isError: true);
      }
    }
  }

  Future<void> _delete() async {
    final ok = await confirmStackDelete(context, _summary?.title ?? '');
    if (!ok || !mounted) return;
    try {
      await _service.delete(widget.stackId);
      getIt<StackStatusController>().markListsChanged();
      if (!mounted) return;
      AppSnackBar.show(context, _l10n.translate('stacks_deleted'));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, stackErrorMessage(e, _l10n), isError: true);
      }
    }
  }

  /// Everything that goes in the top bar: the owner's Edit and menu, then
  /// save and share.
  List<Widget> _topActions(
    BuildContext context,
    StackSummary s, {
    required bool desktop,
  }) {
    final c = context.colors;
    return [
      if (_isOwner) ...[
        if (desktop)
          DesktopIconButton(
            icon: Icons.edit_rounded,
            tooltip: _l10n.translate('stacks_edit'),
            onPressed: _edit,
          )
        else
          IconButton(
            tooltip: _l10n.translate('stacks_edit'),
            icon: Icon(Icons.edit_rounded, color: c.text),
            onPressed: _edit,
          ),
        PopupMenuButton<String>(
          tooltip: _l10n.translate('stacks_more_actions'),
          color: c.surface,
          icon: Icon(Icons.more_horiz_rounded, color: c.text),
          onSelected: (v) {
            switch (v) {
              case 'delete':
                _delete();
              default:
                _setVisibility(StackVisibility.parse(v));
            }
          },
          itemBuilder: (context) => [
            for (final v in StackVisibility.values)
              if (v != s.visibility)
                PopupMenuItem(
                  value: v.apiValue,
                  child: Text(_l10n.translate('stacks_make_${v.name}')),
                ),
            PopupMenuItem(
              value: 'delete',
              child: Text(
                _l10n.translate('stacks_delete'),
                style: TextStyle(color: c.error),
              ),
            ),
          ],
        ),
      ],
      ...stackBarActions(context, s, desktop: desktop),
    ];
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final desktop = DesktopLayout.isActive(context);
    final body = FutureBuilder<StackDetail>(
      future: _detail,
      builder: (context, snapshot) {
        final summary = _summary;
        if (summary == null && snapshot.hasError) {
          return _ErrorState(error: snapshot.error!, onRetry: _retry);
        }
        if (summary == null) return const Center(child: MbSpinner());
        return DerivedLayoutBuilder<bool>(
          derive: (c) => c.maxWidth >= _twoPaneWidth,
          builder: (context, twoPane) => twoPane
              ? _twoPane(context, summary, snapshot)
              : _onePane(context, summary, snapshot),
        );
      },
    );

    if (desktop) {
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
              title: _summary?.title ?? _l10n.translate('stacks'),
              subtitle: _l10n.translate('stacks'),
              actions: [
                if (_summary != null)
                  ..._topActions(context, _summary!, desktop: true),
                DesktopIconButton(
                  icon: Icons.open_in_new_rounded,
                  tooltip: _l10n.translate('stacks_open_web'),
                  onPressed: _summary == null
                      ? null
                      : () => launchUrl(
                          Uri.parse(_summary!.canonicalUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                ),
              ],
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: mbScreenAppBar(
        title: _l10n.translate('stack'),
        actions: _summary == null
            ? const []
            : _topActions(context, _summary!, desktop: false),
      ),
      body: body,
    );
  }

  Widget _onePane(
    BuildContext context,
    StackSummary summary,
    AsyncSnapshot<StackDetail> snapshot,
  ) {
    return RefreshIndicator(
      color: context.colors.accent,
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.horizontalPadding,
              8,
              AppConstants.horizontalPadding,
              8,
            ),
            sliver: SliverToBoxAdapter(
              child: _Header(
                summary: summary,
                detail: _loaded,
                isOwner: _isOwner,
                stacked: true,
              ),
            ),
          ),
          ..._entrySlivers(context, summary, snapshot),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _twoPane(
    BuildContext context,
    StackSummary summary,
    AsyncSnapshot<StackDetail> snapshot,
  ) {
    final desktop = DesktopLayout.isActive(context);
    final pad = desktop
        ? DesktopTokens.pagePadding
        : AppConstants.horizontalPadding;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: DesktopTokens.maxPageWidth),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _sideWidth,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(pad, 12, 12, 32),
                child: _Header(
                  summary: summary,
                  detail: _loaded,
                  isOwner: _isOwner,
                  stacked: false,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: context.colors.accent,
                onRefresh: _refresh,
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    ..._entrySlivers(
                      context,
                      summary,
                      snapshot,
                      sidePadding: pad,
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Entries ───────────────────────────────────────────────────────────────

  List<StackEntry> _sorted(List<StackEntry> entries) {
    final list = [...entries];
    double rating(StackEntry e) => JsonUtils.toDouble(e.series?.rating) ?? -1;
    switch (_sort) {
      case StackEntrySort.stackFirst:
        list.sort((a, b) => a.rank.compareTo(b.rank));
      case StackEntrySort.stackLast:
        list.sort((a, b) => b.rank.compareTo(a.rank));
      case StackEntrySort.ratingHigh:
        list.sort((a, b) => rating(b).compareTo(rating(a)));
      case StackEntrySort.ratingLow:
        list.sort((a, b) {
          // Unrated and placeholder entries go last either way.
          final ra = rating(a), rb = rating(b);
          if (ra < 0 || rb < 0) return rb.compareTo(ra);
          return ra.compareTo(rb);
        });
    }
    return list;
  }

  List<Widget> _entrySlivers(
    BuildContext context,
    StackSummary summary,
    AsyncSnapshot<StackDetail> snapshot, {
    double sidePadding = AppConstants.horizontalPadding,
  }) {
    final detail = _loaded;
    final pad = EdgeInsets.symmetric(horizontal: sidePadding);
    if (detail == null) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 48),
            child: snapshot.hasError
                ? _ErrorState(error: snapshot.error!, onRetry: _retry)
                : const Center(child: MbSpinner()),
          ),
        ),
      ];
    }

    final toolbar = SliverPadding(
      padding: pad.copyWith(top: 8, bottom: 12),
      sliver: SliverToBoxAdapter(child: _toolbar(context, detail)),
    );

    if (detail.entries.isEmpty) {
      return [
        toolbar,
        SliverToBoxAdapter(
          child: _EmptyEntries(isOwner: _isOwner, onEdit: _edit),
        ),
      ];
    }

    if (summary.isSpoiler && !_spoilersRevealed && !_isOwner) {
      return [
        toolbar,
        SliverPadding(
          padding: pad,
          sliver: SliverToBoxAdapter(
            child: _SpoilerGate(
              onReveal: () => setState(() => _spoilersRevealed = true),
            ),
          ),
        ),
      ];
    }

    return [
      toolbar,
      ListenableBuilder(
        listenable: SettingsManager(),
        builder: (context, _) {
          final style = SettingsManager().resolvedBrowseListStyle;
          final entries = _sorted(detail.entries);
          final landscape =
              MediaQuery.orientationOf(context) == Orientation.landscape;
          final prefix = 'stack_${detail.id}';
          void open(Series s) => Navigator.of(context).push(
            AppTransitions.slideUp(
              SeriesDetailScreen(series: s, heroTagPrefix: prefix),
            ),
          );

          if (style.isGrid) {
            final desktop = DesktopLayout.isActive(context);
            return SliverPadding(
              padding: pad,
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: desktop ? 190 : 160,
                  childAspectRatio: style.childAspectRatio,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate((context, i) {
                  final e = entries[i];
                  final series = e.series;
                  if (series == null) {
                    return _PlaceholderTile(entry: e, compact: true);
                  }
                  return MbEntrance(
                    index: i,
                    child: LayoutBuilder(
                      builder: (context, tileConstraints) => Stack(
                        children: [
                          Positioned.fill(
                            child: MbTappable(
                              pressedScale: 0.98,
                              onTap: () => open(series),
                              onLongPress: e.note == null || landscape
                                  ? null
                                  : () => _showNote(context, e),
                              child: EntryListItem(
                                key: ValueKey('${style.name}_${series.id}'),
                                series: series,
                                ranking: e.rank,
                                heroTagPrefix: prefix,
                                listStyle: style,
                              ),
                            ),
                          ),
                          if (e.note != null)
                            Positioned(
                              right: 6,
                              // Beneath the cover's own badges: at the cover's
                              // bottom edge, which in the compact grid sits
                              // above the title.
                              bottom: style == AppListStyle.compactGrid
                                  ? tileConstraints.maxHeight -
                                        tileConstraints.maxWidth / 0.65 +
                                        6
                                  : 6,
                              child: _NoteMark(
                                note: e.note!,
                                hover: landscape,
                                onTap: () => _showNote(context, e),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }, childCount: entries.length),
              ),
            );
          }

          return SliverPadding(
            padding: pad,
            sliver: SliverList.separated(
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final e = entries[i];
                final series = e.series;
                if (series == null) return _PlaceholderTile(entry: e);
                return MbEntrance(
                  index: i,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MbTappable(
                        pressedScale: 0.98,
                        onTap: () => open(series),
                        child: EntryListItem(
                          key: ValueKey('${style.name}_${series.id}'),
                          series: series,
                          ranking: e.rank,
                          heroTagPrefix: prefix,
                          listStyle: style,
                        ),
                      ),
                      if (e.note != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 12),
                          child: StackNoteText(note: e.note!),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    ];
  }

  void _showNote(BuildContext context, StackEntry entry) {
    showAdaptiveSheet<void>(
      context: context,
      backgroundColor: context.colors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${entry.rank}  ${entry.series?.title ?? ''}',
                style: AppTypography.sans(
                  color: context.colors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              StackNoteText(note: entry.note!, collapsedLines: 1000),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbar(BuildContext context, StackDetail detail) {
    // The list style is the Browse one from Settings, like the Library has.
    return Align(
      alignment: Alignment.centerRight,
      child: MbDropdown<StackEntrySort>(
        label: _l10n.translate('sort_by'),
        icon: Icons.sort_rounded,
        value: _sort,
        options: [
          for (final s in StackEntrySort.values)
            (s, _l10n.translate(s.labelKey)),
        ],
        onChanged: (s) => setState(() => _sort = s),
      ),
    );
  }
}

/// Asks before deleting a stack. Returns whether to go ahead.
Future<bool> confirmStackDelete(BuildContext context, String title) async {
  final l10n = LocalizationService();
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.colors.surface,
      title: Text(l10n.translate('stacks_delete_title')),
      content: Text(
        l10n.translate('stacks_delete_body').replaceAll('{title}', title),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.translate('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l10n.translate('stacks_delete'),
            style: TextStyle(color: context.colors.error),
          ),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Title, author, counts, actions, description and library progress.
///
/// [stacked] lays the fan beside the title (phone portrait); otherwise the
/// fan sits on top of the side column.
class _Header extends StatelessWidget {
  final StackSummary summary;
  final StackDetail? detail;
  final bool isOwner;
  final bool stacked;

  const _Header({
    required this.summary,
    required this.detail,
    required this.isOwner,
    required this.stacked,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    final title = Text(
      summary.title,
      style: AppTypography.sans(
        color: c.text,
        fontSize: stacked ? 22 : 24,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
    );

    final owner = summary.owner;
    final updated = stackTimeAgo(summary.updatedAt, l10n);
    final meta = Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (owner.display.isNotEmpty)
          GestureDetector(
            onTap: owner.username == null
                ? null
                : () => StacksListScreen.open(
                    context,
                    StacksListSource.user(owner.username!, owner.display),
                  ),
            child: Text(
              l10n.translate('stacks_by').replaceAll('{name}', owner.display),
              style: AppTypography.sans(
                color: owner.username == null ? c.textMuted : c.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        _dot(c),
        Text(
          stackCount('entries', summary.entryCount, l10n),
          style: _metaStyle(c),
        ),
        if (updated.isNotEmpty) ...[
          _dot(c),
          Text(
            l10n.translate('stacks_updated').replaceAll('{when}', updated),
            style: _metaStyle(c),
          ),
        ],
      ],
    );

    final badges = <Widget>[
      if (summary.isFeatured)
        StackBadge(
          icon: Icons.star_rounded,
          label: l10n.translate('stacks_badge_featured'),
          color: c.star,
        ),
      if (summary.kind == StackKind.official)
        StackBadge(
          icon: Icons.verified_rounded,
          label: l10n.translate('stacks_badge_official'),
          color: c.accent,
        ),
      if (summary.isSpoiler)
        StackBadge(
          icon: Icons.visibility_off_rounded,
          label: l10n.translate('stacks_badge_spoiler'),
          color: c.warning,
        ),
      if (isOwner)
        StackBadge(
          icon: switch (summary.visibility) {
            StackVisibility.draft => Icons.edit_note_rounded,
            StackVisibility.unlisted => Icons.link_rounded,
            StackVisibility.public => Icons.public_rounded,
          },
          label: l10n.translate(summary.visibility.labelKey),
          color: c.info,
        ),
      if (isOwner && (detail?.isHidden ?? false))
        StackBadge(
          icon: Icons.block_rounded,
          label: l10n.translate('stacks_badge_hidden'),
          color: c.error,
        ),
      if (isOwner && (detail?.isDelisted ?? false))
        StackBadge(
          icon: Icons.visibility_off_outlined,
          label: l10n.translate('stacks_badge_delisted'),
          color: c.warning,
        ),
    ];

    final fan = StackCoverFan(
      covers: summary.covers,
      contentRating: summary.contentRating,
    );

    final description = detail?.description;
    final draftHint =
        isOwner &&
        summary.visibility == StackVisibility.draft &&
        detail != null &&
        detail!.liveEntries.length < StackLimits.publishMin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stacked)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 108, child: fan),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 8), meta],
                ),
              ),
            ],
          )
        else ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: fan,
          ),
          const SizedBox(height: 18),
          title,
          const SizedBox(height: 8),
          meta,
        ],
        if (badges.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: badges),
        ],
        const SizedBox(height: 16),
        StackActionBar(
          stack: summary,
          commentsEnabled: detail?.isCommentsEnabled ?? true,
        ),
        if (draftHint) ...[
          const SizedBox(height: 14),
          _Hint(
            icon: Icons.info_outline_rounded,
            text: l10n
                .translate('stacks_publish_needs')
                .replaceAll('{n}', '${StackLimits.publishMin}'),
          ),
        ],
        if (detail != null) ...[
          const SizedBox(height: 14),
          _LibraryProgress(
            stackId: summary.id,
            total: detail!.liveEntries.length,
          ),
        ],
        if (description != null) ...[
          const SizedBox(height: 18),
          DescriptionSection(
            description: stackMarkdown(description),
            expandIfFits: !stacked,
          ),
        ],
      ],
    );
  }

  static TextStyle _metaStyle(MbPalette c) =>
      AppTypography.sans(color: c.textMuted, fontSize: 13);

  static Widget _dot(MbPalette c) =>
      Text('·', style: AppTypography.sans(color: c.textMuted, fontSize: 13));
}

/// "4 of 10 in your library", from the live status; a sign-in nudge when
/// signed out.
class _LibraryProgress extends StatelessWidget {
  final int stackId;
  final int total;

  const _LibraryProgress({required this.stackId, required this.total});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    final access = stackAccess();
    if (access != StackAccess.ready) {
      return Text(
        l10n.translate(
          access == StackAccess.signedOut
              ? 'stacks_library_sign_in'
              : 'stacks_library_reconnect',
        ),
        style: AppTypography.sans(color: c.textMuted, fontSize: 13),
      );
    }
    final controller = getIt<StackStatusController>();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final status = controller.of(stackId);
        if (status == null || total == 0) return const SizedBox.shrink();
        final have = status.libraryCount.clamp(0, total);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n
                  .translate('stacks_library_progress')
                  .replaceAll('{n}', '$have')
                  .replaceAll('{total}', '$total'),
              style: AppTypography.sans(
                color: c.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            MbProgressBar(value: have / total),
          ],
        );
      },
    );
  }
}

class _Hint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Hint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c.info),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.sans(
                color: c.text,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpoilerGate extends StatelessWidget {
  final VoidCallback onReveal;

  const _SpoilerGate({required this.onReveal});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(Icons.visibility_off_rounded, color: c.warning, size: 32),
          const SizedBox(height: 10),
          Text(
            l10n.translate('stacks_spoiler_title'),
            textAlign: TextAlign.center,
            style: AppTypography.sans(
              color: c.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.translate('stacks_spoiler_body'),
            textAlign: TextAlign.center,
            style: AppTypography.sans(color: c.textMuted, fontSize: 13.5),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onReveal,
            icon: const Icon(Icons.visibility_rounded),
            label: Text(l10n.translate('stacks_spoiler_reveal')),
          ),
        ],
      ),
    );
  }
}

/// An entry whose series was merged away or removed: it keeps its rank.
class _PlaceholderTile extends StatelessWidget {
  final StackEntry entry;
  final bool compact;

  const _PlaceholderTile({required this.entry, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    final text = l10n.translate(
      entry.issue == StackEntryIssue.deleted
          ? 'stacks_entry_deleted'
          : 'stacks_entry_merged',
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: compact
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '#${entry.rank}',
                  style: AppTypography.display(color: c.textMuted),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: AppTypography.sans(color: c.textMuted, fontSize: 12),
                ),
              ],
            )
          : Row(
              children: [
                Text(
                  '#${entry.rank}',
                  style: AppTypography.display(color: c.textMuted),
                ),
                const SizedBox(width: 14),
                Icon(Icons.link_off_rounded, color: c.textMuted, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: AppTypography.sans(color: c.textMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
    );
  }
}

/// The mark on a grid cover that says it carries a curator's note: a small
/// solid accent dot. In landscape the note shows on hover (or tap on touch),
/// like a tooltip; otherwise a tap opens it.
class _NoteMark extends StatelessWidget {
  final String note;
  final bool hover;
  final VoidCallback onTap;

  const _NoteMark({
    required this.note,
    required this.hover,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mark = Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
      child: Icon(Icons.format_quote_rounded, size: 15, color: c.onAccent),
    );
    if (!hover) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(padding: const EdgeInsets.all(4), child: mark),
      );
    }
    return Tooltip(
      richMessage: TextSpan(
        text: MarkdownUtils.toPlainText(stackMarkdown(note)),
      ),
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      waitDuration: const Duration(milliseconds: 120),
      showDuration: const Duration(seconds: 12),
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: false,
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.shadowAt(0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: AppTypography.sans(color: c.text, fontSize: 13, height: 1.4),
      child: Padding(padding: const EdgeInsets.all(4), child: mark),
    );
  }
}

class _EmptyEntries extends StatelessWidget {
  final bool isOwner;
  final VoidCallback onEdit;

  const _EmptyEntries({required this.isOwner, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.layers_clear_rounded, size: 40, color: c.textMuted),
          const SizedBox(height: 10),
          Text(
            l10n.translate('stacks_empty_entries'),
            textAlign: TextAlign.center,
            style: AppTypography.sans(color: c.textMuted, fontSize: 14),
          ),
          if (isOwner) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.translate('stacks_add_series')),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers_rounded, size: 40, color: c.textMuted),
            const SizedBox(height: 12),
            Text(
              stackErrorMessage(error, l10n),
              textAlign: TextAlign.center,
              style: AppTypography.sans(color: c.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: Text(l10n.translate('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

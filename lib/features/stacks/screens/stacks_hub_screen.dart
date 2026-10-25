import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/network/paged_list.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_status_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/screens/my_stacks_screen.dart';
import 'package:mangabaka_app/features/stacks/screens/stack_editor_screen.dart';
import 'package:mangabaka_app/features/stacks/screens/stacks_list_screen.dart';
import 'package:mangabaka_app/features/stacks/services/stack_exceptions.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_auth_gate.dart';
import 'package:mangabaka_app/features/stacks/widgets/stacks_grid.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

/// The front door to Stacks: staff picks, the reader's own, saved and
/// followed stacks, and the newest from the community.
class StacksHubScreen extends StatefulWidget {
  const StacksHubScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(AppTransitions.slideRight(const StacksHubScreen()));

  @override
  State<StacksHubScreen> createState() => _StacksHubScreenState();
}

class _StacksHubScreenState extends State<StacksHubScreen> {
  late final StackService _service = getIt<StackService>();
  late final ProfileAuthService _auth = getIt<ProfileAuthService>();
  final LocalizationService _l10n = LocalizationService();

  late Future<PagedList<StackSummary>> _featured;
  late Future<PagedList<StackSummary>> _newest;
  Future<PagedList<StackSummary>>? _mine;
  Future<PagedList<StackSummary>>? _saved;
  Future<PagedList<StackSummary>>? _followed;
  StackAccess _access = StackAccess.signedOut;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuth);
    _revision.addListener(_onListsChanged);
    _load();
  }

  /// Held from initState: the locator may be reset before dispose runs.
  late final ValueNotifier<int> _revision =
      getIt<StackStatusController>().listsRevision;

  void _onListsChanged() {
    if (!mounted || _access != StackAccess.ready) return;
    setState(() {
      _mine = _track(_service.mine(limit: 12));
      _saved = _track(_service.saved(limit: 12));
      _followed = _track(_service.followed(limit: 12));
    });
  }

  @override
  void dispose() {
    _revision.removeListener(_onListsChanged);
    _auth.removeListener(_onAuth);
    super.dispose();
  }

  void _onAuth() {
    if (!mounted) return;
    if (stackAccess(_auth) != _access) setState(_load);
  }

  Future<PagedList<StackSummary>> _track(Future<PagedList<StackSummary>> f) =>
      f.then((page) {
        getIt<StackStatusController>().request(page.items.map((s) => s.id));
        return page;
      })..ignore();

  void _load() {
    _access = stackAccess(_auth);
    _featured = _track(_service.browse(featured: true, limit: 12));
    _newest = _track(_service.browse(limit: 24));
    final ready = _access == StackAccess.ready;
    _mine = ready ? _track(_service.mine(limit: 12)) : null;
    _saved = ready ? _track(_service.saved(limit: 12)) : null;
    _followed = ready ? _track(_service.followed(limit: 12)) : null;
  }

  Future<void> _refresh() async {
    setState(_load);
    try {
      await Future.wait([_featured, _newest]);
    } catch (_) {}
  }

  Future<void> _create() async {
    if (!await ensureStackAccess(context)) return;
    if (!mounted) return;
    await StackEditorScreen.open(context);
  }

  Widget _rail(
    String title,
    Future<PagedList<StackSummary>>? future, {
    VoidCallback? onViewAll,
    bool showVisibility = false,
    Widget? trailing,
  }) {
    if (future == null) return const SizedBox.shrink();
    return FutureBuilder<PagedList<StackSummary>>(
      future: future,
      builder: (context, snap) => StacksRail(
        title: title,
        stacks: snap.data?.items ?? const [],
        loading: snap.connectionState != ConnectionState.done,
        onViewAll: onViewAll,
        showVisibility: showVisibility,
        trailing: trailing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = DesktopLayout.isActive(context);
    final pad = desktop
        ? DesktopTokens.pagePadding
        : AppConstants.horizontalPadding;
    final gap = desktop ? DesktopTokens.sectionGap - 12 : 8.0;

    Widget section(Widget child) => SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(
          left: desktop ? pad : 0,
          right: desktop ? pad : 0,
          bottom: gap,
        ),
        child: child,
      ),
    );

    final slivers = <Widget>[
      SliverToBoxAdapter(child: SizedBox(height: desktop ? 4 : 8)),
      if (_access != StackAccess.ready)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
          sliver: SliverToBoxAdapter(
            child: StackAccessPrompt(
              access: _access,
              signedOutMessage: _l10n.translate('stacks_hub_sign_in_body'),
              onReady: () => setState(_load),
            ),
          ),
        ),
      section(
        _rail(
          _l10n.translate('stacks_mine'),
          _mine,
          showVisibility: true,
          onViewAll: () => MyStacksScreen.open(context),
        ),
      ),
      section(
        _rail(
          _l10n.translate('stacks_featured'),
          _featured,
          onViewAll: () =>
              StacksListScreen.open(context, const StacksListSource.featured()),
        ),
      ),
      section(
        _rail(
          _l10n.translate('stacks_followed'),
          _followed,
          onViewAll: () =>
              StacksListScreen.open(context, const StacksListSource.followed()),
        ),
      ),
      section(
        _rail(
          _l10n.translate('stacks_saved'),
          _saved,
          onViewAll: () =>
              StacksListScreen.open(context, const StacksListSource.saved()),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          desktop ? pad : 0,
          0,
          desktop ? pad : 0,
          0,
        ),
        sliver: SliverToBoxAdapter(
          child: desktop
              ? DesktopSectionTitle(
                  title: _l10n.translate('stacks_new'),
                  trailing: DesktopPillButton(
                    label: _l10n.translate('view_all'),
                    onPressed: () => StacksListScreen.open(
                      context,
                      const StacksListSource.newest(),
                    ),
                  ),
                )
              : MbSectionHeader(
                  title: _l10n.translate('stacks_new'),
                  onAction: () => StacksListScreen.open(
                    context,
                    const StacksListSource.newest(),
                  ),
                ),
        ),
      ),
      FutureBuilder<PagedList<StackSummary>>(
        future: _newest,
        builder: (context, snap) {
          if (snap.hasError) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      stackErrorMessage(snap.error!, _l10n),
                      textAlign: TextAlign.center,
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(_load),
                      child: Text(_l10n.translate('retry')),
                    ),
                  ],
                ),
              ),
            );
          }
          return SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            sliver: SliverStackGrid(
              stacks: snap.data?.items ?? const [],
              loading: snap.connectionState != ConnectionState.done,
            ),
          );
        },
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 48)),
    ];

    final scroll = RefreshIndicator(
      color: context.colors.accent,
      onRefresh: _refresh,
      child: CustomScrollView(slivers: slivers),
    );

    if (desktop) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesktopPageHeader(
              leading: Navigator.of(context).canPop()
                  ? DesktopIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.of(context).maybePop(),
                    )
                  : null,
              title: _l10n.translate('stacks'),
              subtitle: _l10n.translate('stacks_tagline'),
              actions: [
                DesktopPillButton(
                  label: _l10n.translate('stacks_create'),
                  icon: Icons.add_rounded,
                  primary: true,
                  onPressed: _create,
                ),
              ],
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: DesktopTokens.maxPageWidth,
                  ),
                  child: scroll,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: mbScreenAppBar(
        title: _l10n.translate('stacks'),
        actions: [
          IconButton(
            tooltip: _l10n.translate('stacks_create'),
            icon: Icon(Icons.add_rounded, color: context.colors.text),
            onPressed: _create,
          ),
        ],
      ),
      body: scroll,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_status_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_detail.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/screens/stack_editor_screen.dart';
import 'package:mangabaka_app/features/stacks/services/stack_exceptions.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_auth_gate.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_detail_components.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_detail_entries.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_detail_panes.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:url_launcher/url_launcher.dart';

export 'package:mangabaka_app/features/stacks/widgets/stack_detail_components.dart'
    show confirmStackDelete;

/// One stack: what it is about, who made it, and its ranked series.
///
/// Paints at once from a listing's [initial] summary, then loads the entries.
/// The owner sees their own drafts and hidden stacks too (read through the
/// owner endpoint), with Edit, visibility and Delete.
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

  late final StackService _service = getIt<StackService>();
  late final ProfileAuthService _auth = getIt<ProfileAuthService>();
  final LocalizationService _l10n = LocalizationService();

  late Future<StackDetail> _detail;
  StackDetail? _loaded;
  StackEntrySort _sort = StackEntrySort.stackFirst;
  bool _spoilersRevealed = false;
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
    } catch (e, st) {
      LoggingService.logger.warning('Failed to refresh stack detail', e, st);
    }
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

  List<Widget> _topActions(
    BuildContext context,
    StackSummary s, {
    required bool desktop,
  }) => buildStackDetailTopActions(
    context,
    s,
    isOwner: _isOwner,
    desktop: desktop,
    l10n: _l10n,
    onEdit: _edit,
    onDelete: _delete,
    onSetVisibility: _setVisibility,
  );

  @override
  Widget build(BuildContext context) {
    final desktop = DesktopLayout.isActive(context);
    final body = FutureBuilder<StackDetail>(
      future: _detail,
      builder: (context, snapshot) {
        final summary = _summary;
        if (summary == null && snapshot.hasError) {
          return StackErrorState(error: snapshot.error!, onRetry: _retry);
        }
        if (summary == null) return const Center(child: MbSpinner());
        return DerivedLayoutBuilder<bool>(
          derive: (c) => c.maxWidth >= _twoPaneWidth,
          builder: (context, twoPane) {
            final pad = DesktopLayout.isActive(context)
                ? DesktopTokens.pagePadding
                : AppConstants.horizontalPadding;
            return twoPane
                ? StackDetailTwoPane(
                    summary: summary,
                    detail: _loaded,
                    isOwner: _isOwner,
                    onRefresh: _refresh,
                    entries: _entries(
                      context,
                      summary,
                      snapshot,
                      sidePadding: pad,
                    ),
                  )
                : StackDetailOnePane(
                    summary: summary,
                    detail: _loaded,
                    isOwner: _isOwner,
                    onRefresh: _refresh,
                    entries: _entries(context, summary, snapshot),
                  );
          },
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

  List<Widget> _entries(
    BuildContext context,
    StackSummary summary,
    AsyncSnapshot<StackDetail> snapshot, {
    double sidePadding = AppConstants.horizontalPadding,
  }) => buildStackDetailEntrySlivers(
    context,
    summary: summary,
    detail: _loaded,
    snapshot: snapshot,
    isOwner: _isOwner,
    spoilersRevealed: _spoilersRevealed,
    sort: _sort,
    l10n: _l10n,
    onRetry: _retry,
    onEdit: _edit,
    onRevealSpoilers: () => setState(() => _spoilersRevealed = true),
    onSortChanged: (s) => setState(() => _sort = s),
    sidePadding: sidePadding,
  );
}

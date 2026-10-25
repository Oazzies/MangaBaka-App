import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/content_rating_filter.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/core/widgets/design/mb_cover.dart';
import 'package:mangabaka_app/core/widgets/design/mb_dropdown.dart';
import 'package:mangabaka_app/core/widgets/design/mb_pill.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_editor_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_detail.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/screens/stack_detail_screen.dart';
import 'package:mangabaka_app/features/stacks/services/stack_exceptions.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_series_picker.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

/// Create a stack, or edit one the reader owns: its details, its ranked
/// series with notes, who can see it, and deleting it.
///
/// A phone shows Details and Series as two tabs. From [_splitWidth] up the
/// details sit beside the series list, and on a wide desktop window the
/// series search stays open in a third column.
///
/// Pops with true when something was saved or deleted.
class StackEditorScreen extends StatefulWidget {
  final int? stackId;

  /// Series to start a new stack with (from "New stack" on a series page).
  final Series? initialSeries;

  const StackEditorScreen({super.key, this.stackId, this.initialSeries});

  static Future<bool?> open(
    BuildContext context, {
    int? stackId,
    Series? initialSeries,
  }) => Navigator.of(context).push<bool>(
    AppTransitions.slideUp(
      StackEditorScreen(stackId: stackId, initialSeries: initialSeries),
    ),
  );

  @override
  State<StackEditorScreen> createState() => _StackEditorScreenState();
}

class _StackEditorScreenState extends State<StackEditorScreen>
    with SingleTickerProviderStateMixin {
  static const double _splitWidth = 840;
  static const double _searchPanelWidth = 1320;

  late final StackEditorController _c = StackEditorController(
    stackId: widget.stackId,
  );
  // Made up front: created lazily, a wide layout that never shows the tabs
  // would first build it in dispose(), when vsync can no longer be read.
  late final TabController _tabs;
  final LocalizationService _l10n = LocalizationService();
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _c.addListener(_changed);
    final initial = widget.initialSeries;
    if (initial != null) {
      _c.add(initial);
    }
    _c.load();
  }

  @override
  void dispose() {
    _c.removeListener(_changed);
    _c.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  // ─── Saving ────────────────────────────────────────────────────────────────

  String _problemText(StackEditorProblem p) => switch (p) {
    StackEditorProblem.titleMissing => _l10n.translate('stacks_problem_title'),
    StackEditorProblem.titleTooLong =>
      _l10n
          .translate('stacks_problem_title_long')
          .replaceAll('{n}', '${StackLimits.titleMax}'),
    StackEditorProblem.descriptionTooLong =>
      _l10n
          .translate('stacks_problem_description_long')
          .replaceAll('{n}', '${StackLimits.descriptionMax}'),
    StackEditorProblem.noteTooLong =>
      _l10n
          .translate('stacks_problem_note_long')
          .replaceAll('{n}', '${StackLimits.noteMax}'),
    StackEditorProblem.tooManyEntries =>
      _l10n
          .translate('stacks_problem_too_many')
          .replaceAll('{n}', '${StackLimits.entriesMax}'),
    StackEditorProblem.tooFewToPublish =>
      _l10n
          .translate('stacks_publish_needs')
          .replaceAll('{n}', '${StackLimits.publishMin}'),
    StackEditorProblem.ratingBelowMinimum => _l10n.translate(
      'stacks_error_rating_below_minimum',
    ),
  };

  Future<void> _save({bool overwrite = false}) async {
    final problems = _c.problems;
    if (problems.isNotEmpty) {
      setState(() => _showErrors = true);
      AppSnackBar.show(context, _problemText(problems.first), isError: true);
      return;
    }
    if (_c.ratingTooLow && !overwrite) {
      final raise = await _askRaiseRating();
      if (raise == null) return;
      if (raise) _c.setRating(_c.suggestedRating);
    }
    try {
      final saved = await _c.save(overwrite: overwrite);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        _l10n.translate(_c.isNew ? 'stacks_created' : 'stacks_saved_changes'),
      );
      final nav = Navigator.of(context);
      nav.pop(true);
      if (widget.stackId == null) {
        // Show the new stack where it lives.
        nav.push(
          AppTransitions.slideRight(
            StackDetailScreen(
              stackId: saved.id,
              initial: saved.summary,
              asOwner: true,
            ),
          ),
        );
      }
    } on StackApiException catch (e) {
      if (!mounted) return;
      if (e.isStaleToken) {
        await _onStale();
        return;
      }
      if (e.code == StackErrorCode.ratingBelowFloor) {
        _c.setRating(_c.suggestedRating);
      }
      AppSnackBar.show(context, stackErrorMessage(e, _l10n), isError: true);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, stackErrorMessage(e, _l10n), isError: true);
      }
    }
  }

  /// Null: cancel. True: raise it. False: keep it and try anyway.
  Future<bool?> _askRaiseRating() {
    final suggested = _l10n.translate(_c.suggestedRating);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(_l10n.translate('stacks_rating_raise_title')),
        content: Text(
          _l10n
              .translate('stacks_rating_raise_body')
              .replaceAll('{rating}', suggested),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_l10n.translate('stacks_rating_keep')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              _l10n
                  .translate('stacks_rating_raise')
                  .replaceAll('{rating}', suggested),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onStale() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(_l10n.translate('stacks_stale_title')),
        content: Text(_l10n.translate('stacks_stale_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('reload'),
            child: Text(_l10n.translate('stacks_stale_reload')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('overwrite'),
            child: Text(_l10n.translate('stacks_stale_overwrite')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'reload') {
      await _c.reload();
    } else if (choice == 'overwrite') {
      await _save(overwrite: true);
    }
  }

  Future<void> _delete() async {
    final id = widget.stackId;
    if (id == null) return;
    if (!await confirmStackDelete(context, _c.title.text)) return;
    try {
      await getIt<StackService>().delete(id);
      if (!mounted) return;
      AppSnackBar.show(context, _l10n.translate('stacks_deleted'));
      // Leave the editor and the (now gone) stack page under it.
      final nav = Navigator.of(context);
      nav.pop(true);
      if (nav.canPop()) nav.pop(true);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, stackErrorMessage(e, _l10n), isError: true);
      }
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_c.dirty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(_l10n.translate('stacks_discard_title')),
        content: Text(_l10n.translate('stacks_discard_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_l10n.translate('stacks_keep_editing')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              _l10n.translate('stacks_discard'),
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  void _toggleSeries(Series s) {
    final i = _c.entries.indexWhere((e) => e.seriesId == s.id);
    if (i >= 0) {
      _c.removeAt(i);
    } else if (!_c.add(s)) {
      AppSnackBar.show(
        context,
        _l10n.translate('stacks_error_stack_full'),
        isError: true,
      );
    }
  }

  void _openPicker() => showStackSeriesPicker(
    context,
    isAdded: _c.containsSeries,
    onToggle: _toggleSeries,
  );

  Future<void> _editNote(int index) async {
    final entry = _c.entries[index];
    final result = await showAdaptiveSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (context) => _NoteSheet(entry: entry),
    );
    if (result != null) _c.setNote(index, result);
  }

  Future<void> _replaceMerged(int index) async {
    final target = _c.entries[index].mergedWith;
    if (target == null) return;
    try {
      final series = await getIt<SeriesService>().fetchSeries(target);
      _c.replace(index, series);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, stackErrorMessage(e, _l10n), isError: true);
      }
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  String get _screenTitle =>
      _l10n.translate(_c.isNew ? 'stacks_new_stack' : 'stacks_edit_stack');

  @override
  Widget build(BuildContext context) {
    final desktop = DesktopLayout.isActive(context);

    Widget body;
    if (_c.loading) {
      body = const Center(child: MbSpinner());
    } else if (_c.loadError != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              stackErrorMessage(_c.loadError!, _l10n),
              textAlign: TextAlign.center,
              style: AppTypography.sans(color: context.colors.textMuted),
            ),
            TextButton(
              onPressed: _c.load,
              child: Text(_l10n.translate('retry')),
            ),
          ],
        ),
      );
    } else {
      body = DerivedLayoutBuilder<int>(
        derive: (c) => c.maxWidth >= _searchPanelWidth && desktop
            ? 3
            : c.maxWidth >= _splitWidth
            ? 2
            : 1,
        builder: (context, columns) => switch (columns) {
          1 => _tabbed(context),
          _ => _split(context, withSearch: columns == 3),
        },
      );
    }

    final saveButton = _c.saving
        ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(width: 22, height: 22, child: MbSpinner()),
          )
        : null;

    final Widget scaffold;
    if (desktop) {
      scaffold = Scaffold(
        backgroundColor: context.colors.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesktopPageHeader(
              leading: DesktopIconButton(
                icon: Icons.close_rounded,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: _screenTitle,
              subtitle: _c.title.text.trim().isEmpty
                  ? null
                  : _c.title.text.trim(),
              actions: [
                if (!_c.isNew)
                  DesktopPillButton(
                    label: _l10n.translate('stacks_delete'),
                    icon: Icons.delete_outline_rounded,
                    danger: true,
                    onPressed: _delete,
                  ),
                saveButton ??
                    DesktopPillButton(
                      label: _l10n.translate('save'),
                      icon: Icons.check_rounded,
                      primary: true,
                      onPressed: _c.loading ? null : _save,
                    ),
              ],
            ),
            Expanded(child: body),
          ],
        ),
      );
    } else {
      scaffold = Scaffold(
        backgroundColor: context.colors.background,
        appBar: mbScreenAppBar(
          title: _screenTitle,
          actions: [
            saveButton ??
                TextButton(
                  onPressed: _c.loading ? null : _save,
                  child: Text(
                    _l10n.translate('save'),
                    style: AppTypography.sans(
                      color: context.colors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
          ],
        ),
        body: body,
      );
    }

    return PopScope(
      canPop: !_c.dirty || _c.saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop(false);
        }
      },
      child: scaffold,
    );
  }

  Widget _tabbed(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          labelColor: c.text,
          unselectedLabelColor: c.textMuted,
          indicatorColor: c.accent,
          dividerColor: c.border,
          tabs: [
            Tab(text: _l10n.translate('stacks_tab_details')),
            Tab(
              text: _l10n
                  .translate('stacks_tab_series')
                  .replaceAll('{n}', '${_c.entries.length}'),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.horizontalPadding),
                child: _details(context),
              ),
              _entries(context, pad: AppConstants.horizontalPadding),
            ],
          ),
        ),
      ],
    );
  }

  Widget _split(BuildContext context, {required bool withSearch}) {
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
              width: 380,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(pad, 12, 12, 32),
                child: _details(context),
              ),
            ),
            Expanded(child: _entries(context, pad: 12, showAdd: !withSearch)),
            if (withSearch)
              SizedBox(
                width: 360,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 12, pad, 16),
                  child: DesktopCard(
                    padding: const EdgeInsets.all(14),
                    child: StackSeriesSearch(
                      isAdded: _c.containsSeries,
                      onToggle: _toggleSeries,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Details ───────────────────────────────────────────────────────────────

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 18),
    child: Text(
      text.toUpperCase(),
      style: AppTypography.display(
        color: context.colors.textMuted,
        fontSize: 12,
      ),
    ),
  );

  // The app's input theme is a full pill, which on a field stretched to
  // several lines turns into a bulging oval. Every state border is set here
  // because the theme's enabled/focused ones win over `border`.
  InputDecoration _input(String hint, {String? error}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      hintText: hint,
      errorText: error,
      filled: true,
      fillColor: context.colors.surfaceRaised,
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      errorBorder: border,
      focusedErrorBorder: border,
    );
  }

  Widget _details(BuildContext context) {
    final c = context.colors;
    final problems = _showErrors ? _c.problems : const <StackEditorProblem>[];
    final titleError = problems.contains(StackEditorProblem.titleMissing)
        ? _problemText(StackEditorProblem.titleMissing)
        : null;
    final publishBlocked = _c.liveCount < StackLimits.publishMin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(_l10n.translate('stacks_field_title')),
        TextField(
          controller: _c.title,
          maxLength: StackLimits.titleMax,
          style: AppTypography.sans(
            color: c.text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: _input(
            _l10n.translate('stacks_title_hint'),
            error: titleError,
          ),
        ),
        _label(_l10n.translate('stacks_field_description')),
        TextField(
          controller: _c.description,
          maxLength: StackLimits.descriptionMax,
          minLines: 4,
          maxLines: 12,
          style: AppTypography.sans(color: c.text, fontSize: 14, height: 1.4),
          decoration: _input(
            _l10n.translate('stacks_description_hint'),
          ).copyWith(helperText: _l10n.translate('stacks_markdown_hint')),
        ),
        _label(_l10n.translate('stacks_field_visibility')),
        Row(
          children: [
            for (final v in StackVisibility.values) ...[
              if (v.index > 0) const SizedBox(width: 8),
              Expanded(
                child: MbPill(
                  label: _l10n.translate(v.labelKey),
                  selected: _c.visibility == v,
                  expand: true,
                  onTap: () => _c.setVisibility(v),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _l10n.translate('stacks_visibility_${_c.visibility.name}_hint'),
          style: AppTypography.sans(
            color: c.textMuted,
            fontSize: 12.5,
            height: 1.35,
          ),
        ),
        if (_c.visibility.isListed && publishBlocked)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _l10n
                  .translate('stacks_publish_needs')
                  .replaceAll('{n}', '${StackLimits.publishMin}'),
              style: AppTypography.sans(color: c.warning, fontSize: 12.5),
            ),
          ),
        _label(_l10n.translate('stacks_field_rating')),
        Align(
          alignment: Alignment.centerLeft,
          child: MbDropdown<String>(
            label: _l10n.translate('stacks_field_rating'),
            icon: Icons.shield_outlined,
            value: _c.contentRating,
            options: [
              for (final r in ContentRatingFilter.all) (r, _l10n.translate(r)),
            ],
            onChanged: _c.setRating,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _c.ratingTooLow
              ? _l10n
                    .translate('stacks_rating_warning')
                    .replaceAll('{rating}', _l10n.translate(_c.suggestedRating))
              : _l10n.translate('stacks_rating_hint'),
          style: AppTypography.sans(
            color: _c.ratingTooLow ? c.warning : c.textMuted,
            fontSize: 12.5,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _c.isSpoiler,
          onChanged: _c.isSpoilerLocked ? null : _c.setSpoiler,
          activeTrackColor: c.accent,
          title: Text(
            _l10n.translate('stacks_field_spoiler'),
            style: AppTypography.sans(
              color: c.text,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            _l10n.translate(
              _c.isSpoilerLocked
                  ? 'stacks_spoiler_locked'
                  : 'stacks_spoiler_hint',
            ),
            style: AppTypography.sans(color: c.textMuted, fontSize: 12.5),
          ),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _c.commentsEnabled,
          onChanged: _c.setComments,
          activeTrackColor: c.accent,
          title: Text(
            _l10n.translate('stacks_field_comments'),
            style: AppTypography.sans(
              color: c.text,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            _l10n.translate('stacks_comments_hint'),
            style: AppTypography.sans(color: c.textMuted, fontSize: 12.5),
          ),
        ),
        if (!_c.isNew && !DesktopLayout.isActive(context)) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _delete,
            icon: Icon(Icons.delete_outline_rounded, color: c.error),
            label: Text(
              _l10n.translate('stacks_delete'),
              style: TextStyle(color: c.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: c.error.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Entries ───────────────────────────────────────────────────────────────

  Widget _entries(
    BuildContext context, {
    required double pad,
    bool showAdd = true,
  }) {
    final c = context.colors;
    final desktop = DesktopLayout.isActive(context);
    final header = Padding(
      padding: EdgeInsets.fromLTRB(pad, 12, pad, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _l10n
                  .translate('stacks_entries_count')
                  .replaceAll('{n}', '${_c.entries.length}')
                  .replaceAll('{max}', '${StackLimits.entriesMax}'),
              style: AppTypography.sans(color: c.textMuted, fontSize: 13),
            ),
          ),
          if (showAdd)
            MbPrimaryButton(
              label: _l10n.translate('stacks_add_series'),
              expand: false,
              icon: Icons.add_rounded,
              onPressed: _c.entries.length >= StackLimits.entriesMax
                  ? null
                  : _openPicker,
            ),
        ],
      ),
    );

    if (_c.entries.isEmpty) {
      return Column(
        children: [
          header,
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.playlist_add_rounded,
                      size: 44,
                      color: c.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _l10n
                          .translate('stacks_editor_empty')
                          .replaceAll('{n}', '${StackLimits.publishMin}'),
                      textAlign: TextAlign.center,
                      style: AppTypography.sans(
                        color: c.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        header,
        Expanded(
          child: ReorderableListView.builder(
            padding: EdgeInsets.fromLTRB(pad, 0, pad, 48),
            buildDefaultDragHandles: false,
            itemCount: _c.entries.length,
            onReorderItem: _c.reorder,
            itemBuilder: (context, i) {
              final e = _c.entries[i];
              final row = _EntryRow(
                index: i,
                entry: e,
                count: _c.entries.length,
                desktop: desktop,
                onNote: () => _editNote(i),
                onRemove: () => _c.removeAt(i),
                onMove: (d) => _c.move(i, d),
                onReplace: e.mergedWith == null
                    ? null
                    : () => _replaceMerged(i),
              );
              if (desktop) return KeyedSubtree(key: e.key, child: row);
              return Dismissible(
                key: e.key,
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: c.error.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: c.error),
                ),
                onDismissed: (_) => _c.removeAt(i),
                child: row,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  final int index;
  final EditableStackEntry entry;
  final int count;
  final bool desktop;
  final VoidCallback onNote;
  final VoidCallback onRemove;
  final ValueChanged<int> onMove;
  final VoidCallback? onReplace;

  const _EntryRow({
    required this.index,
    required this.entry,
    required this.count,
    required this.desktop,
    required this.onNote,
    required this.onRemove,
    required this.onMove,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    final series = entry.series;
    final note = entry.note.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.unavailable
              ? c.warning.withValues(alpha: 0.5)
              : c.border,
        ),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 12,
                ),
                child: Icon(Icons.drag_indicator_rounded, color: c.textMuted),
              ),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              '#${index + 1}',
              style: AppTypography.display(color: c.accent, fontSize: 15),
            ),
          ),
          MbCover(
            url: series?.coverUrl ?? '',
            width: 42,
            radius: 6,
            memCacheWidth: 96,
            blurred: WidgetUtils.isRatingBlurred(series?.contentRating ?? ''),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sans(
                    color: c.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                if (entry.unavailable)
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: c.warning,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          l10n.translate(
                            entry.issue == StackEntryIssue.deleted
                                ? 'stacks_entry_deleted'
                                : 'stacks_entry_merged',
                          ),
                          style: AppTypography.sans(
                            color: c.warning,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (onReplace != null)
                        TextButton(
                          onPressed: onReplace,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(l10n.translate('stacks_entry_replace')),
                        ),
                    ],
                  )
                else
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onNote,
                    child: note.isEmpty
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_comment_outlined,
                                size: 14,
                                color: c.accent,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                l10n.translate('stacks_note_add'),
                                style: AppTypography.sans(
                                  color: c.accent,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  width: 2.5,
                                  decoration: BoxDecoration(
                                    color: c.accent.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    note,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.sans(
                                      color: c.textMuted,
                                      fontSize: 12.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
              ],
            ),
          ),
          if (desktop) ...[
            IconButton(
              tooltip: l10n.translate('stacks_move_up'),
              icon: Icon(Icons.keyboard_arrow_up_rounded, color: c.textMuted),
              onPressed: index == 0 ? null : () => onMove(-1),
            ),
            IconButton(
              tooltip: l10n.translate('stacks_move_down'),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.textMuted),
              onPressed: index == count - 1 ? null : () => onMove(1),
            ),
            IconButton(
              tooltip: l10n.translate('stacks_remove'),
              icon: Icon(Icons.close_rounded, color: c.textMuted, size: 20),
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}

/// The note editor: a sheet headed by the entry it is for, with a roomy field
/// and a running count against [StackLimits.noteMax]. Pops the new text.
class _NoteSheet extends StatefulWidget {
  final EditableStackEntry entry;

  const _NoteSheet({required this.entry});

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final TextEditingController _text = TextEditingController(
    text: widget.entry.note,
  );
  final LocalizationService _l10n = LocalizationService();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final series = widget.entry.series;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  MbCover(
                    url: series?.coverUrl ?? '',
                    width: 40,
                    radius: 6,
                    memCacheWidth: 96,
                    blurred: WidgetUtils.isRatingBlurred(
                      series?.contentRating ?? '',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _l10n.translate('stacks_note_edit'),
                          style: AppTypography.display(
                            color: c.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.entry.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.sans(
                            color: c.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _text,
                autofocus: true,
                minLines: 4,
                maxLines: 8,
                maxLength: StackLimits.noteMax,
                style: AppTypography.sans(
                  color: c.text,
                  fontSize: 14,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: _l10n.translate('stacks_note_hint'),
                  helperText: _l10n.translate('stacks_markdown_hint'),
                  filled: true,
                  fillColor: c.surfaceRaised,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: c.accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(_l10n.translate('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MbPrimaryButton(
                      label: _l10n.translate('save'),
                      onPressed: () => Navigator.of(context).pop(_text.text),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_editor_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/screens/stack_detail_screen.dart';
import 'package:mangabaka_app/features/stacks/services/stack_exceptions.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_editor_body.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_editor_dialogs.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_editor_layout.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_editor_note_sheet.dart';
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

  Future<void> _save({bool overwrite = false}) async {
    final problems = _c.problems;
    if (problems.isNotEmpty) {
      setState(() => _showErrors = true);
      AppSnackBar.show(
        context,
        stackEditorProblemText(problems.first, _l10n),
        isError: true,
      );
      return;
    }
    if (_c.ratingTooLow && !overwrite) {
      final raise = await askRaiseStackRatingDialog(
        context,
        suggestedRatingKey: _c.suggestedRating,
        l10n: _l10n,
      );
      if (raise == null || !mounted) return;
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

  Future<void> _onStale() async {
    final choice = await askStaleStackDialog(context, _l10n);
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
    return confirmDiscardStackEditsDialog(context, _l10n);
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
      builder: (context) => StackEditorNoteSheet(entry: entry),
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

  String get _screenTitle =>
      _l10n.translate(_c.isNew ? 'stacks_new_stack' : 'stacks_edit_stack');

  @override
  Widget build(BuildContext context) {
    final desktop = DesktopLayout.isActive(context);
    final body = StackEditorBody(
      desktop: desktop,
      controller: _c,
      tabs: _tabs,
      l10n: _l10n,
      showErrors: _showErrors,
      onDelete: _delete,
      onAdd: _openPicker,
      onEditNote: _editNote,
      onReplaceMerged: _replaceMerged,
      onToggleSeries: _toggleSeries,
    );
    final saveButton = _c.saving
        ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(width: 22, height: 22, child: MbSpinner()),
          )
        : null;

    final Widget scaffold = desktop
        ? StackEditorDesktopScaffold(
            title: _screenTitle,
            subtitle: _c.title.text.trim().isEmpty
                ? null
                : _c.title.text.trim(),
            isNew: _c.isNew,
            loading: _c.loading,
            l10n: _l10n,
            body: body,
            saveButton: saveButton,
            onDelete: _delete,
            onSave: _save,
          )
        : StackEditorMobileScaffold(
            title: _screenTitle,
            loading: _c.loading,
            l10n: _l10n,
            body: body,
            saveButton: saveButton,
            onSave: _save,
          );

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
}

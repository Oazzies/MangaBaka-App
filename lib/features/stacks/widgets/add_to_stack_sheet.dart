import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_status_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_draft.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/models/stack_status.dart';
import 'package:mangabaka_app/features/stacks/screens/stack_editor_screen.dart';
import 'package:mangabaka_app/features/stacks/services/stack_exceptions.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';
import 'package:mangabaka_app/features/stacks/utils/stack_format.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_auth_gate.dart';

/// Puts [series] into one of the reader's stacks, or takes it out, or starts
/// a new stack with it. A bottom sheet on a phone, a dialog on desktop.
Future<void> showAddToStackSheet(BuildContext context, Series series) async {
  if (!await ensureStackAccess(context)) return;
  if (!context.mounted) return;
  final content = _AddToStack(series: series);
  if (DesktopLayout.isActive(context)) {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: context.colors.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
          child: content,
        ),
      ),
    );
    return;
  }
  await showAdaptiveSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.colors.surface,
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: SafeArea(child: content),
    ),
  );
}

class _AddToStack extends StatefulWidget {
  final Series series;

  const _AddToStack({required this.series});

  @override
  State<_AddToStack> createState() => _AddToStackState();
}

class _AddToStackState extends State<_AddToStack> {
  late final StackService _service = getIt<StackService>();
  final LocalizationService _l10n = LocalizationService();
  late Future<List<MySeriesStack>> _stacks;
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _stacks = _service.myStacksForSeries(widget.series.id);
  }

  void _reload() =>
      setState(() => _stacks = _service.myStacksForSeries(widget.series.id));

  Future<void> _toggle(MySeriesStack stack) async {
    if (_busy.contains(stack.id)) return;
    setState(() => _busy.add(stack.id));
    try {
      if (stack.contains) {
        await _remove(stack);
        _toast(
          _l10n
              .translate('stacks_removed_from')
              .replaceAll('{title}', stack.title),
        );
      } else {
        await _add(stack);
        _toast(
          _l10n.translate('stacks_added_to').replaceAll('{title}', stack.title),
        );
      }
      getIt<StackStatusController>().markListsChanged();
      _reload();
    } catch (e) {
      _toast(stackErrorMessage(e, _l10n), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(stack.id));
    }
  }

  Future<void> _add(MySeriesStack stack) async {
    try {
      await _service.addEntry(stack.id, widget.series.id);
    } on StackApiException catch (e) {
      // The series is rated above what the stack allows: offer to raise it.
      if (e.code != StackErrorCode.ratingBelowFloor || !mounted) rethrow;
      final rating = widget.series.contentRating.toLowerCase();
      final raise = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: context.colors.surface,
          title: Text(_l10n.translate('stacks_rating_raise_title')),
          content: Text(
            _l10n
                .translate('stacks_rating_raise_body')
                .replaceAll('{rating}', _l10n.translate(rating)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(_l10n.translate('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                _l10n
                    .translate('stacks_rating_raise')
                    .replaceAll('{rating}', _l10n.translate(rating)),
              ),
            ),
          ],
        ),
      );
      if (raise != true) rethrow;
      await _service.addEntry(
        stack.id,
        widget.series.id,
        contentRating: rating,
      );
    }
  }

  /// There is no remove-one endpoint: the stack is read and written back
  /// without the series.
  Future<void> _remove(MySeriesStack stack) async {
    final detail = await _service.fetchForEdit(stack.id);
    final draft = StackDraft.fromDetail(detail);
    final kept = StackDraft(
      title: draft.title,
      description: draft.description,
      contentRating: draft.contentRating,
      isSpoiler: draft.isSpoiler,
      isCommentsEnabled: draft.isCommentsEnabled,
      // Taking a public stack under the minimum would be refused; drop it to
      // a draft rather than fail.
      visibility:
          draft.visibility.isListed &&
              draft.entries.length - 1 < StackLimits.publishMin
          ? StackVisibility.draft
          : draft.visibility,
      entries: [
        for (final e in draft.entries)
          if (e.seriesId != widget.series.id) e,
      ],
    );
    await _service.update(stack.id, kept, detail.token ?? '');
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    AppSnackBar.show(context, message, isError: error);
  }

  Future<void> _newStack() async {
    final nav = Navigator.of(context);
    nav.pop();
    await StackEditorScreen.open(nav.context, initialSeries: widget.series);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _l10n.translate('stacks_add_to'),
            style: AppTypography.sans(
              color: c.text,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.series.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sans(color: c.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: FutureBuilder<List<MySeriesStack>>(
              future: _stacks,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: MbSpinner()),
                  );
                }
                if (snap.hasError) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stackErrorMessage(snap.error!, _l10n),
                        textAlign: TextAlign.center,
                        style: AppTypography.sans(color: c.textMuted),
                      ),
                      TextButton(
                        onPressed: _reload,
                        child: Text(_l10n.translate('retry')),
                      ),
                    ],
                  );
                }
                final stacks = snap.data ?? const [];
                if (stacks.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      _l10n.translate('stacks_none_yet'),
                      textAlign: TextAlign.center,
                      style: AppTypography.sans(
                        color: c.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: stacks.length,
                  itemBuilder: (context, i) => _row(context, stacks[i]),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _newStack,
            icon: const Icon(Icons.add_rounded),
            label: Text(_l10n.translate('stacks_new_with_series')),
            style: OutlinedButton.styleFrom(
              foregroundColor: c.accent,
              side: BorderSide(color: c.accent.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, MySeriesStack stack) {
    final c = context.colors;
    final busy = _busy.contains(stack.id);
    final enabled = stack.contains || stack.canAdd;
    final subtitle = [
      _l10n.translate(stack.visibility.labelKey),
      stackCount('entries', stack.entryCount, _l10n),
      if (stack.contains)
        _l10n.translate('stacks_at_rank').replaceAll('{n}', '${stack.rank}'),
      if (!stack.contains && !stack.canAdd)
        _l10n.translate('stacks_cannot_add'),
    ].join(' · ');
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      enabled: enabled && !busy,
      onTap: () => _toggle(stack),
      leading: Icon(
        Icons.layers_rounded,
        color: stack.contains ? c.accent : c.textMuted,
      ),
      title: Text(
        stack.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.sans(
          color: c.text,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.sans(color: c.textMuted, fontSize: 12.5),
      ),
      trailing: busy
          ? const SizedBox(width: 22, height: 22, child: MbSpinner())
          : Icon(
              stack.contains
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              color: stack.contains ? c.accent : c.textMuted,
            ),
    );
  }
}

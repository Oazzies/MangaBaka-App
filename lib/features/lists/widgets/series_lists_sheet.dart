import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/lists/controllers/library_lists_controller.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';
import 'package:mangabaka_app/features/lists/services/library_lists_service.dart';
import 'package:mangabaka_app/features/lists/widgets/library_list_flows.dart';
import 'package:mangabaka_app/features/lists/widgets/no_tap_flash.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

Future<void> showSeriesListsSheet(
  BuildContext context, {
  required LibraryListsService service,
  required LibraryService library,
  required Series series,
}) => showAdaptiveSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: context.colors.surface,
  constraints: const BoxConstraints(maxWidth: 480),
  builder: (sheet) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(sheet).height * 0.75,
    ),
    child: SafeArea(
      child: SeriesListsSheet(
        service: service,
        library: library,
        series: series,
      ),
    ),
  ),
);

/// Toggles take effect at once; there is nothing to save.
class SeriesListsSheet extends StatefulWidget {
  final LibraryListsService service;
  final LibraryService library;
  final Series series;

  const SeriesListsSheet({
    super.key,
    required this.service,
    required this.library,
    required this.series,
  });

  @override
  State<SeriesListsSheet> createState() => _SeriesListsSheetState();
}

class _SeriesListsSheetState extends State<SeriesListsSheet> {
  late final LibraryListsController _lists = LibraryListsController(
    service: widget.service,
    library: widget.library,
    watchEntries: false,
  );
  late final LibraryListFlows _flows = LibraryListFlows(_lists);
  final LocalizationService _l10n = LocalizationService();

  @override
  void dispose() {
    _lists.dispose();
    super.dispose();
  }

  /// An l10n key. Shown in the sheet: a toast would render under the modal route.
  String? _error;

  Future<void> _toggle(LibraryList list, {required bool on}) async {
    setState(() => _error = null);
    final error = await _lists.setMembership(
      widget.series.id,
      list.id,
      member: !on,
    );
    if (mounted) setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListenableBuilder(
      listenable: _lists,
      builder: (context, _) {
        final memberOf = _lists.listIdsOf(widget.series.id);
        final full = memberOf.length >= LibraryListRules.listsPerSeriesMax;
        final all = [
          ..._lists.all,
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _l10n.translate('lists').toUpperCase(),
                style: AppTypography.display(color: c.text, fontSize: 18),
              ),
              const SizedBox(height: 2),
              Text(
                widget.series.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sans(color: c.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: !_lists.isLoaded
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: MbSpinner()),
                      )
                    : all.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          _l10n.translate('lists_empty'),
                          textAlign: TextAlign.center,
                          style: AppTypography.sans(
                            color: c.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : NoTapFlash(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: all.length,
                          itemBuilder: (context, i) {
                            final list = all[i];
                            final on = memberOf.contains(list.id);
                            final busy = _lists.isBusy(list.id);
                            return ListTile(
                              key: ValueKey('series_list_${list.id}'),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              enabled: !busy && (on || !full),
                              onTap: () => _toggle(list, on: on),
                              leading: Icon(
                                list.isPrivate
                                    ? Icons.lock_rounded
                                    : Icons.format_list_bulleted_rounded,
                                color: on ? c.accent : c.textMuted,
                              ),
                              title: Text(
                                list.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.sans(
                                  color: c.text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: MbSpinner(),
                                    )
                                  : Icon(
                                      on
                                          ? Icons.check_circle_rounded
                                          : Icons.add_circle_outline_rounded,
                                      color: on ? c.accent : c.textMuted,
                                    ),
                            );
                          },
                        ),
                      ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _l10n.translate(_error!),
                    key: const ValueKey('series_lists_error'),
                    style: AppTypography.sans(color: c.error, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('series_lists_new'),
                onPressed: full
                    ? null
                    : () =>
                          _flows.create(context, addSeriesId: widget.series.id),
                icon: const Icon(Icons.add_rounded),
                label: Text(_l10n.translate('lists_new_with_series')),
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
      },
    );
  }
}

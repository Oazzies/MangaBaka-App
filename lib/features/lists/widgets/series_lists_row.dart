import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';
import 'package:mangabaka_app/features/lists/services/library_lists_service.dart';

/// The lists a library series is on, in the series page's library card.
class SeriesListsRow extends StatefulWidget {
  final LibraryListsService service;
  final String seriesId;
  final VoidCallback onTap;

  const SeriesListsRow({
    super.key,
    required this.service,
    required this.seriesId,
    required this.onTap,
  });

  @override
  State<SeriesListsRow> createState() => _SeriesListsRowState();
}

class _SeriesListsRowState extends State<SeriesListsRow> {
  late Stream<List<LibraryList>> _lists = widget.service.watchLists();
  late Stream<Set<int>> _ids = widget.service.watchListIdsForSeries(
    widget.seriesId,
  );

  @override
  void didUpdateWidget(SeriesListsRow old) {
    super.didUpdateWidget(old);
    if (old.seriesId != widget.seriesId || old.service != widget.service) {
      _lists = widget.service.watchLists();
      _ids = widget.service.watchListIdsForSeries(widget.seriesId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = LocalizationService();
    return StreamBuilder<List<LibraryList>>(
      stream: _lists,
      builder: (context, listsSnap) => StreamBuilder<Set<int>>(
        stream: _ids,
        builder: (context, idsSnap) {
          final ids = idsSnap.data ?? const <int>{};
          final on =
              [
                for (final l in listsSnap.data ?? const <LibraryList>[])
                  if (ids.contains(l.id)) l,
              ]..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );
          return Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.border, width: 1)),
            ),
            child: InkWell(
              key: const ValueKey('series_lists_row'),
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.translate('lists').toUpperCase(),
                            style: AppTypography.displayLabel(
                              color: c.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Icon(
                          on.isEmpty
                              ? Icons.playlist_add_rounded
                              : Icons.edit_rounded,
                          size: 16,
                          color: c.textMuted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (on.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        l10n.translate('lists_series_placeholder'),
                        style: AppTypography.sans(
                          color: c.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [for (final l in on) _ListChip(list: l)],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ListChip extends StatelessWidget {
  final LibraryList list;

  const _ListChip({required this.list});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (list.isPrivate) ...[
            Icon(Icons.lock_rounded, size: 12, color: c.textMuted),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              list.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sans(
                color: c.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

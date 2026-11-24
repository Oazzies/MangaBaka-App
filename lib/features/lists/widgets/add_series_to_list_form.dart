import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/search_utils.dart';
import 'package:mangabaka_app/core/widgets/adaptive_form.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/lists/controllers/library_lists_controller.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';
import 'package:mangabaka_app/features/lists/widgets/global_series_for_list.dart';
import 'package:mangabaka_app/features/lists/widgets/list_form_header.dart';
import 'package:mangabaka_app/features/lists/widgets/list_search_field.dart';
import 'package:mangabaka_app/features/lists/widgets/no_tap_flash.dart';
import 'package:mangabaka_app/features/lists/widgets/series_pick_row.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';

/// Without [search] there is no way out to the whole catalogue.
Future<void> showAddSeriesToList(
  BuildContext context,
  LibraryListsController lists,
  LibraryList list, {
  SeriesSearchService? search,
}) => showAdaptiveForm<void>(
  context: context,
  title: LocalizationService().translate('lists_add_series_title'),
  scrollable: false,
  constraints: const BoxConstraints(maxWidth: 560),
  builder: (_) => AddSeriesToListForm(lists: lists, list: list, search: search),
);

/// Library entries not on [list] yet; a series must be in the library to go on a list.
class AddSeriesToListForm extends StatefulWidget {
  final LibraryListsController lists;
  final LibraryList list;
  final SeriesSearchService? search;

  const AddSeriesToListForm({
    super.key,
    required this.lists,
    required this.list,
    this.search,
  });

  @override
  State<AddSeriesToListForm> createState() => _AddSeriesToListFormState();
}

class _AddSeriesToListFormState extends State<AddSeriesToListForm> {
  final LocalizationService _l10n = LocalizationService();
  final Set<String> _picked = {};
  String _query = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.lists.addListener(_onLists);
  }

  @override
  void dispose() {
    widget.lists.removeListener(_onLists);
    super.dispose();
  }

  void _onLists() {
    if (mounted) setState(() {});
  }

  List<LibraryEntry> get _candidates {
    final onList = {
      for (final e in widget.lists.entriesOn(widget.list.id)) e.series.id,
    };
    final q = SearchUtils.prepare(_query);
    final out = [
      for (final e in widget.lists.libraryEntries)
        if (!onList.contains(e.series.id) &&
            (q.isEmpty ||
                q.matches(e.series.title) ||
                q.matches(e.series.romanizedTitle) ||
                q.matches(e.series.nativeTitle)))
          e,
    ];
    out.sort(
      (a, b) =>
          a.series.title.toLowerCase().compareTo(b.series.title.toLowerCase()),
    );
    return out;
  }

  void _toggle(String seriesId) => setState(() {
    if (!_picked.remove(seriesId)) _picked.add(seriesId);
  });

  Future<void> _add() async {
    if (_picked.isEmpty || _busy) return;
    setState(() => _busy = true);
    final count = _picked.length;
    final (failed, error) = await widget.lists.setMembershipMany(
      widget.list.id,
      _picked.toList(),
      member: true,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    final added = count - failed;
    AppSnackBar.show(
      context,
      error != null
          ? _l10n.translate(error)
          : _l10n
                .translate('lists_added_many')
                .replaceAll('{count}', '$added')
                .replaceAll('{name}', widget.list.name),
      isError: error != null,
    );
    if (added > 0) Navigator.of(context).pop();
  }

  void _searchAll() => showGlobalSeriesForList(
    context,
    lists: widget.lists,
    list: widget.list,
    search: widget.search!,
    initialQuery: _query,
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final page = AdaptiveFormPage.isPage(context);
    final candidates = _candidates;
    final searchAll = widget.search != null;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
          child: ListFormHeader(
            title: _l10n.translate('lists_add_series_title'),
            subtitle: widget.list.name,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: ListSearchField(
            hint: _l10n.translate('lists_search_library'),
            // On a phone the keyboard would cover the list it filters.
            autofocus: !page,
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: candidates.isEmpty && !searchAll
              ? Center(
                  child: Text(
                    _l10n.translate('no_results'),
                    style: AppTypography.sans(color: c.textMuted, fontSize: 15),
                  ),
                )
              : NoTapFlash(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: candidates.length + (searchAll ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == candidates.length) {
                        return _SearchAllRow(
                          query: _query.trim(),
                          l10n: _l10n,
                          onTap: _searchAll,
                        );
                      }
                      final entry = candidates[i];
                      return SeriesPickRow(
                        series: entry.series,
                        meta: _l10n.translate(entry.state),
                        metaColor: c.forState(entry.state),
                        trailing: PickMark(
                          on: _picked.contains(entry.series.id),
                          offIcon: Icons.circle_outlined,
                        ),
                        onTap: _busy ? null : () => _toggle(entry.series.id),
                      );
                    },
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: MbPrimaryButton(
            key: const ValueKey('add_series_submit'),
            label: _picked.isEmpty
                ? _l10n.translate('lists_add_series')
                : _l10n
                      .translate('lists_add_n')
                      .replaceAll('{count}', '${_picked.length}'),
            icon: Icons.playlist_add_rounded,
            busy: _busy,
            onPressed: _picked.isEmpty ? null : _add,
          ),
        ),
      ],
    );
    if (page) return SafeArea(top: false, child: body);
    final height = MediaQuery.sizeOf(context).height * 0.8;
    return SizedBox(height: height.clamp(320.0, 640.0), child: body);
  }
}

class _SearchAllRow extends StatelessWidget {
  final String query;
  final LocalizationService l10n;
  final VoidCallback onTap;

  const _SearchAllRow({
    required this.query,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      key: const ValueKey('add_series_search_all'),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: SizedBox(
        width: 36,
        child: Icon(Icons.search_rounded, color: c.accent),
      ),
      title: Text(
        query.isEmpty
            ? l10n.translate('lists_search_all')
            : l10n
                  .translate('lists_search_all_for')
                  .replaceAll('{query}', query),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.sans(
          color: c.accent,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: c.textMuted),
    );
  }
}

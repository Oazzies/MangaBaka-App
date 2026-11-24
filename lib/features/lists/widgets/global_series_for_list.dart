import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/adaptive_form.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/features/lists/controllers/library_lists_controller.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';
import 'package:mangabaka_app/features/lists/widgets/add_to_library_sheet.dart';
import 'package:mangabaka_app/features/lists/widgets/list_form_header.dart';
import 'package:mangabaka_app/features/lists/widgets/list_search_field.dart';
import 'package:mangabaka_app/features/lists/widgets/no_tap_flash.dart';
import 'package:mangabaka_app/features/lists/widgets/series_pick_row.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/features/series/utils/series_labels.dart';

Future<void> showGlobalSeriesForList(
  BuildContext context, {
  required LibraryListsController lists,
  required LibraryList list,
  required SeriesSearchService search,
  String initialQuery = '',
}) => showAdaptiveForm<void>(
  context: context,
  title: LocalizationService().translate('lists_add_series_global_title'),
  scrollable: false,
  constraints: const BoxConstraints(maxWidth: 560),
  builder: (_) => GlobalSeriesForList(
    lists: lists,
    list: list,
    search: search,
    initialQuery: initialQuery,
  ),
);

/// Every series on MangaBaka. One outside the library joins it first, with a status.
class GlobalSeriesForList extends StatefulWidget {
  final LibraryListsController lists;
  final LibraryList list;
  final SeriesSearchService search;
  final String initialQuery;

  const GlobalSeriesForList({
    super.key,
    required this.lists,
    required this.list,
    required this.search,
    this.initialQuery = '',
  });

  @override
  State<GlobalSeriesForList> createState() => _GlobalSeriesForListState();
}

class _GlobalSeriesForListState extends State<GlobalSeriesForList> {
  static const _minQuery = 2;

  final LocalizationService _l10n = LocalizationService();
  final Set<String> _busy = {};
  Timer? _debounce;
  List<Series> _results = const [];
  late String _query = widget.initialQuery.trim();
  bool _loading = false;
  bool _failed = false;
  int _generation = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.lists.addListener(_onLists);
    if (_query.length >= _minQuery) {
      _loading = true;
      _fetch(_query);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.lists.removeListener(_onLists);
    super.dispose();
  }

  void _onLists() {
    if (mounted) setState(() {});
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  void _search(String value) {
    _query = value.trim();
    if (_query.length < _minQuery) {
      _generation++;
      setState(() {
        _results = const [];
        _loading = false;
        _failed = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _failed = false;
    });
    _fetch(_query);
  }

  Future<void> _fetch(String query) async {
    final generation = ++_generation;
    try {
      final results = await widget.search.searchSeriesByName(query);
      if (!mounted || generation != _generation) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e, st) {
      LoggingService.logger.warning('Lists: series search failed', e, st);
      if (!mounted || generation != _generation) return;
      setState(() {
        _results = const [];
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _tap(Series series, {required bool onList}) async {
    final lists = widget.lists;
    String? state;
    if (!onList && lists.entryFor(series.id) == null) {
      state = await showAddToLibrarySheet(context, series);
      if (state == null || !mounted) return;
    }
    setState(() {
      _busy.add(series.id);
      _error = null;
    });
    final error = state == null
        ? await lists.setMembership(series.id, widget.list.id, member: !onList)
        : await lists.addToLibraryAndList(
            series.id,
            widget.list.id,
            state: state,
          );
    if (!mounted) return;
    setState(() {
      _busy.remove(series.id);
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
          child: ListFormHeader(
            title: _l10n.translate('lists_add_series_global_title'),
            subtitle: widget.list.name,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: ListSearchField(
            hint: _l10n.translate('lists_search_all'),
            initial: widget.initialQuery,
            autofocus: true,
            onChanged: _onChanged,
          ),
        ),
        Expanded(child: _resultsView(context)),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              _l10n.translate(_error!),
              key: const ValueKey('global_series_error'),
              style: AppTypography.sans(color: c.error, fontSize: 13),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
    if (AdaptiveFormPage.isPage(context)) {
      return SafeArea(top: false, child: body);
    }
    final height = MediaQuery.sizeOf(context).height * 0.8;
    return SizedBox(height: height.clamp(320.0, 640.0), child: body);
  }

  Widget _resultsView(BuildContext context) {
    final c = context.colors;
    if (_results.isEmpty) {
      if (_loading) return const Center(child: MbSpinner());
      final message = _failed
          ? 'error_network'
          : _query.length >= _minQuery
          ? 'no_results'
          : null;
      if (message == null) return const SizedBox.shrink();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _l10n.translate(message),
            textAlign: TextAlign.center,
            style: AppTypography.sans(color: c.textMuted, fontSize: 14),
          ),
        ),
      );
    }
    return NoTapFlash(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _results.length,
        itemBuilder: (context, i) => _row(context, _results[i]),
      ),
    );
  }

  Widget _row(BuildContext context, Series series) {
    final c = context.colors;
    final entry = widget.lists.entryFor(series.id);
    final onList = widget.lists.listIdsOf(series.id).contains(widget.list.id);
    final busy = _busy.contains(series.id);
    return SeriesPickRow(
      key: ValueKey('global_series_${series.id}'),
      series: series,
      meta: entry != null
          ? _l10n.translate(entry.state)
          : SeriesLabels.summary(series),
      metaColor: entry != null ? c.forState(entry.state) : null,
      trailing: PickMark(
        on: onList,
        busy: busy,
        offIcon: Icons.add_circle_outline_rounded,
      ),
      onTap: busy ? null : () => _tap(series, onList: onList),
    );
  }
}

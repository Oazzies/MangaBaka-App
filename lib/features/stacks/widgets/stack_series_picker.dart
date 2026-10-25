import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_cover.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';

/// Search MangaBaka for series to put in a stack.
///
/// [isAdded] says which results are already in; tapping one calls [onToggle]
/// and the row's check follows. Used inline (the desktop editor's side
/// panel) or in [showStackSeriesPicker].
class StackSeriesSearch extends StatefulWidget {
  final bool Function(String seriesId) isAdded;
  final void Function(Series series) onToggle;
  final bool autofocus;

  const StackSeriesSearch({
    super.key,
    required this.isAdded,
    required this.onToggle,
    this.autofocus = false,
  });

  @override
  State<StackSeriesSearch> createState() => _StackSeriesSearchState();
}

class _StackSeriesSearchState extends State<StackSeriesSearch> {
  final TextEditingController _query = TextEditingController();
  final LocalizationService _l10n = LocalizationService();
  Timer? _debounce;
  List<Series> _results = const [];
  bool _loading = false;
  bool _failed = false;
  int _generation = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String value) async {
    final q = value.trim();
    final generation = ++_generation;
    if (q.length < 2) {
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
    try {
      final results = await getIt<SeriesSearchService>().searchSeriesByName(q);
      if (!mounted || generation != _generation) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _query,
          autofocus: widget.autofocus,
          onChanged: _onChanged,
          onSubmitted: _search,
          textInputAction: TextInputAction.search,
          style: AppTypography.sans(color: c.text, fontSize: 15),
          decoration: InputDecoration(
            hintText: _l10n.translate('stacks_search_series'),
            prefixIcon: Icon(Icons.search_rounded, color: c.textMuted),
            filled: true,
            fillColor: c.surfaceRaised,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: MbSpinner());
    String? message;
    if (_failed) {
      message = _l10n.translate('stacks_error_network');
    } else if (_results.isEmpty) {
      message = _l10n.translate(
        _query.text.trim().length < 2
            ? 'stacks_search_hint'
            : 'stacks_search_empty',
      );
    }
    if (message != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.sans(
              color: context.colors.textMuted,
              fontSize: 13.5,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, i) {
        final s = _results[i];
        final added = widget.isAdded(s.id);
        return _ResultRow(
          series: s,
          added: added,
          onTap: () {
            widget.onToggle(s);
            setState(() {});
          },
        );
      },
    );
  }
}

class _ResultRow extends StatelessWidget {
  final Series series;
  final bool added;
  final VoidCallback onTap;

  const _ResultRow({
    required this.series,
    required this.added,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final meta = [
      if (series.type.isNotEmpty) series.type,
      if (series.year.isNotEmpty) series.year,
      if (series.authors.isNotEmpty) series.authors.first,
    ].join(' · ');
    return Material(
      color: added ? c.accent.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              MbCover(
                url: series.coverUrl,
                width: 40,
                radius: 6,
                memCacheWidth: 96,
                blurred: WidgetUtils.isRatingBlurred(series.contentRating),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sans(
                        color: c.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.sans(
                          color: c.textMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                added
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                color: added ? c.accent : c.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [StackSeriesSearch] in a tall bottom sheet on a phone, a dialog on
/// desktop.
Future<void> showStackSeriesPicker(
  BuildContext context, {
  required bool Function(String seriesId) isAdded,
  required void Function(Series series) onToggle,
}) {
  final l10n = LocalizationService();
  Widget content(BuildContext context) =>
      StackSeriesSearch(isAdded: isAdded, onToggle: onToggle, autofocus: true);

  if (DesktopLayout.isActive(context)) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: context.colors.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.translate('stacks_add_series'),
                        style: AppTypography.sans(
                          color: context.colors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.translate('done')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(child: content(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  return showAdaptiveSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.colors.surface,
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 8,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.translate('stacks_add_series'),
                      style: AppTypography.sans(
                        color: context.colors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.translate('done')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(child: content(context)),
            ],
          ),
        ),
      ),
    ),
  );
}

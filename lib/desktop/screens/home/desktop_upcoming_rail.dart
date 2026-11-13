import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/home/services/home_service.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/models/series_work.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/desktop/widgets/series_hover_preview.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';

part 'desktop_upcoming_headers_part.dart';
part 'desktop_upcoming_cards_part.dart';

class DesktopUpcomingRail extends StatefulWidget {
  /// Space above the title; the docked rail leaves room for the window
  /// controls floating over it, the overlay version sits below the header.
  final double topPadding;

  const DesktopUpcomingRail({super.key, this.topPadding = 56});

  @override
  State<DesktopUpcomingRail> createState() => _DesktopUpcomingRailState();
}

class _DesktopUpcomingRailState extends State<DesktopUpcomingRail> {
  final HomeService _home = HomeService();
  List<SeriesWork> _works = const [];
  Set<String> _librarySeriesIds = const {};
  Map<String, String> _seriesCovers = const {};
  bool _loading = true;
  bool _onlyLibrary = false;
  bool _libraryResolved = false;
  int _page = 1;
  bool _hasMore = false;
  bool _loadingMore = false;
  final Set<String> _collapsedDateGroups = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _libraryResolved = false;
    });
    final works = await _home.fetchUpcomingWorks(page: 1, perPage: 40);
    if (!mounted) return;
    setState(() {
      _works = works;
      _page = 1;
      _hasMore = works.length >= 25;
      _loading = false;
    });
    await _resolveLibrary();
  }

  /// Works out which releases are in the library, asking the database only
  /// about their series. Until it answers, a library-only view shows a spinner.
  Future<void> _resolveLibrary() async {
    final works = _works;
    final ids = {
      for (final w in works)
        if (w.seriesId != null) w.seriesId.toString(),
    };
    var covers = const <String, String>{};
    try {
      covers = await getIt<LibraryService>().database.libraryEntriesDao
          .libraryCoversFor(ids);
    } catch (e, st) {
      // Library marks are decoration; the rail renders without them.
      LoggingService.logger.fine('Upcoming rail library lookup failed', e, st);
    }
    if (!mounted) return;
    setState(() {
      _librarySeriesIds = covers.keys.toSet();
      _seriesCovers = {
        for (final e in covers.entries)
          if (e.value.isNotEmpty) e.key: e.value,
      };
      _libraryResolved = true;
    });
  }

  /// Reaches one page further into the future. The API only lists releases
  /// from today onward, so there is no way to page back into the past.
  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    final next = await _home.fetchUpcomingWorks(page: _page + 1);
    if (!mounted) return;
    final known = {for (final w in _works) w.id};
    setState(() {
      _works = [
        ..._works,
        for (final w in next)
          if (!known.contains(w.id)) w,
      ];
      _page++;
      _hasMore = next.length >= 25;
      _loadingMore = false;
      _libraryResolved = false;
    });
    await _resolveLibrary();
  }

  /// One header per release day, then that day's releases â€” the date is what
  /// this rail is for, so it leads instead of trailing each card in small text.
  Widget _groupedList(List<SeriesWork> works, LocalizationService l10n) {
    final groups = _groupByDate(works);
    final rows = <Widget>[];
    for (final group in groups) {
      final dateKey = _dateGroupKey(group.date);
      final isCollapsed = _collapsedDateGroups.contains(dateKey);

      rows.add(
        _DateHeader(
          date: group.date,
          first: rows.isEmpty,
          l10n: l10n,
          isCollapsed: isCollapsed,
          onToggle: () {
            setState(() {
              if (isCollapsed) {
                _collapsedDateGroups.remove(dateKey);
              } else {
                _collapsedDateGroups.add(dateKey);
              }
            });
          },
        ),
      );

      if (!isCollapsed) {
        for (final work in group.works) {
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _UpcomingWorkCard(
                work: work,
                inLibrary:
                    work.seriesId != null &&
                    _librarySeriesIds.contains(work.seriesId.toString()),
                fallbackCoverUrl: work.seriesId != null
                    ? _seriesCovers[work.seriesId!.toString()]
                    : null,
              ),
            ),
          );
        }
      }
    }
    if (_hasMore && !_onlyLibrary) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: _loadingMore
              ? const Center(child: MbSpinner())
              : DesktopPillButton(
                  label: l10n.translate('upcoming_load_more'),
                  icon: Icons.expand_more_rounded,
                  onPressed: _loadMore,
                ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: rows,
    );
  }

  String _dateGroupKey(DateTime? date) {
    if (date == null) return 'tba';
    return '${date.year}-${date.month}-${date.day}';
  }

  /// Chronological groups; works with no parseable date collect at the end.
  List<_DateGroup> _groupByDate(List<SeriesWork> works) {
    final byDay = <DateTime, List<SeriesWork>>{};
    final undated = <SeriesWork>[];
    for (final w in works) {
      final d = _parseDay(w.releaseDate);
      if (d == null) {
        undated.add(w);
      } else {
        byDay.putIfAbsent(d, () => []).add(w);
      }
    }
    final days = byDay.keys.toList()..sort();
    return [
      for (final d in days) _DateGroup(d, byDay[d]!),
      if (undated.isNotEmpty) _DateGroup(null, undated),
    ];
  }

  static DateTime? _parseDay(String raw) {
    if (raw.length < 10) return null;
    final d = DateTime.tryParse(raw.substring(0, 10));
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final displayedWorks = _onlyLibrary
        ? _works.where((w) {
            final sid = w.seriesId?.toString();
            return sid != null && _librarySeriesIds.contains(sid);
          }).toList()
        : _works;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, widget.topPadding, 28, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('upcoming_releases').toUpperCase(),
                style: AppTypography.display(
                  color: context.colors.text,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              DesktopSegmented<bool>(
                value: _onlyLibrary,
                segments: [
                  (false, l10n.translate('all'), null),
                  (true, l10n.translate('library'), null),
                ],
                onChanged: (val) => setState(() => _onlyLibrary = val),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: context.colors.border),
        Expanded(
          child: _loading || (_onlyLibrary && !_libraryResolved)
              ? const Center(child: MbSpinner())
              : displayedWorks.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _onlyLibrary
                          ? l10n.translate('no_upcoming_in_library')
                          : l10n.translate('no_results'),
                      textAlign: TextAlign.center,
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              : _groupedList(displayedWorks, l10n),
        ),
      ],
    );
  }
}

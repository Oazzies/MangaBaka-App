import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

class DesktopUpcomingRail extends StatefulWidget {
  const DesktopUpcomingRail({super.key});

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
  final Set<String> _collapsedDateGroups = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final works = await _home.fetchUpcomingWorks(page: 1, perPage: 40);

    // Load user's library series IDs and covers from local database
    final lib = getIt<LibraryService>();
    final Set<String> libraryIds = {};
    final Map<String, String> seriesCovers = {};
    try {
      final entries = await lib.database.libraryEntriesDao
          .watchAllEntriesWithSeries()
          .first;
      for (final e in entries) {
        libraryIds.add(e.series.id);
        final cover = e.series.coverUrl;
        if (cover.isNotEmpty) {
          seriesCovers[e.series.id] = cover;
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _works = works;
      _librarySeriesIds = libraryIds;
      _seriesCovers = seriesCovers;
      _loading = false;
    });
  }

  /// One header per release day, then that day's releases — the date is what
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
          padding: const EdgeInsets.fromLTRB(20, 56, 28, 16),
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
          child: _loading
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

class _DateGroup {
  final DateTime? date;
  final List<SeriesWork> works;

  const _DateGroup(this.date, this.works);
}

/// Day heading: a big "25 SEP" with the weekday and distance beside it.
class _DateHeader extends StatelessWidget {
  final DateTime? date;
  final bool first;
  final LocalizationService l10n;
  final bool isCollapsed;
  final VoidCallback onToggle;

  const _DateHeader({
    required this.date,
    required this.first,
    required this.l10n,
    required this.isCollapsed,
    required this.onToggle,
  });

  String _relative(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = d.difference(today).inDays;
    if (days == 0) return l10n.translate('upcoming_today');
    if (days == 1) return l10n.translate('upcoming_tomorrow');
    return DateFormat('EEEE').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final d = date;
    final isToday =
        d != null && _relative(d) == l10n.translate('upcoming_today');
    return Transform.translate(
      offset: const Offset(-8, 0),
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, first ? 12 : 22, 4, 10),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.only(right: 4, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  isCollapsed ? Icons.chevron_right : Icons.expand_more,
                  size: 20,
                  color: context.colors.textMuted,
                ),
                const SizedBox(width: 2),
                Text(
                  d == null
                      ? l10n.translate('upcoming_date_tba').toUpperCase()
                      : DateFormat('d MMM').format(d).toUpperCase(),
                  style: AppTypography.display(
                    color: isToday
                        ? context.colors.accent
                        : context.colors.text,
                    fontSize: d == null ? 14 : 22,
                    height: 1,
                  ),
                ),
                if (d != null) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      _relative(d).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.monoLabel(
                        color: context.colors.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpcomingWorkCard extends StatelessWidget {
  final SeriesWork work;
  final bool inLibrary;
  final String? fallbackCoverUrl;

  const _UpcomingWorkCard({
    required this.work,
    required this.inLibrary,
    this.fallbackCoverUrl,
  });

  void _openSeries(BuildContext context) async {
    if (work.seriesId == null) return;
    SeriesHoverPreviewController.instance.hide();
    final seriesService = getIt<SeriesService>();
    try {
      final series = await seriesService.fetchSeries(work.seriesId.toString());
      if (!context.mounted) return;
      Navigator.of(
        context,
      ).push(AppTransitions.slideRight(SeriesDetailScreen(series: series)));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final title = work.seriesTitle ?? work.subTitle;
    // The release date is carried by the group header above the card.
    final subtitle = work.sequenceString.isNotEmpty
        ? 'Vol. ${work.sequenceString}'
        : '';

    final card = DesktopCard(
      showBorder: false,
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: work.seriesId != null ? () => _openSeries(context) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 68,
                child: _UpcomingWorkCover(
                  work: work,
                  fallbackCoverUrl: fallbackCoverUrl,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(
                      color: context.colors.text,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (inLibrary) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        LocalizationService().translate('upcoming_in_library').toUpperCase(),
                        style: AppTypography.monoLabel(
                          color: context.colors.accent,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (work.seriesId == null) return card;

    final initialSeries = Series(
      id: work.seriesId.toString(),
      state: '',
      title: title,
      nativeTitle: '',
      romanizedTitle: '',
      secondaryTitles: const [],
      coverUrl: work.imageUrl ?? fallbackCoverUrl ?? '',
      rawCoverUrl: work.imageUrl ?? fallbackCoverUrl ?? '',
      authors: const [],
      artists: const [],
      description: '',
      year: '',
      status: '',
      isLicensed: '',
      hasAnime: '',
      contentRating: '',
      type: '',
      rating: '',
      finalVolume: '',
      totalChapters: '',
      links: const [],
      publishers: const [],
      genres: const [],
      tags: const [],
      lastUpdated: '',
    );

    return SeriesHoverPreview(
      series: initialSeries,
      seriesId: work.seriesId.toString(),
      child: card,
    );
  }
}

class _UpcomingWorkCover extends StatefulWidget {
  final SeriesWork work;
  final String? fallbackCoverUrl;

  const _UpcomingWorkCover({required this.work, this.fallbackCoverUrl});

  @override
  State<_UpcomingWorkCover> createState() => _UpcomingWorkCoverState();
}

class _UpcomingWorkCoverState extends State<_UpcomingWorkCover> {
  String? _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _UpcomingWorkCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.work.id != widget.work.id ||
        oldWidget.work.imageUrl != widget.work.imageUrl ||
        oldWidget.fallbackCoverUrl != widget.fallbackCoverUrl) {
      _resolve();
    }
  }

  void _resolve() {
    if (widget.work.imageUrl != null && widget.work.imageUrl!.isNotEmpty) {
      _resolvedUrl = widget.work.imageUrl;
      return;
    }
    if (widget.fallbackCoverUrl != null &&
        widget.fallbackCoverUrl!.isNotEmpty) {
      _resolvedUrl = widget.fallbackCoverUrl;
      return;
    }
    final sid = widget.work.seriesId;
    if (sid != null) {
      final seriesService = getIt<SeriesService>();
      final cached = seriesService.cache[sid.toString()];
      if (cached != null) {
        final cover = cached.coverUrl;
        if (cover.isNotEmpty) {
          _resolvedUrl = cover;
          return;
        }
      }
      seriesService
          .fetchSeries(sid.toString())
          .then((s) {
            if (mounted) {
              final cover = s.coverUrl;
              if (cover.isNotEmpty) {
                setState(() => _resolvedUrl = cover);
              }
            }
          })
          .catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resolvedUrl != null && _resolvedUrl!.isNotEmpty) {
      return WidgetUtils.networkImage(url: _resolvedUrl!, fit: BoxFit.cover);
    }
    return Container(
      color: context.colors.surfaceRaised,
      child: Icon(
        Icons.book_outlined,
        size: 20,
        color: context.colors.textMuted,
      ),
    );
  }
}

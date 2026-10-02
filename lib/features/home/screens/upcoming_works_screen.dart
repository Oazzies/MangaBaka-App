import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_pill.dart';
import 'package:mangabaka_app/core/widgets/design/mb_refresh_indicator.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/features/home/services/home_service.dart';
import 'package:mangabaka_app/features/home/services/upcoming_loader.dart';
import 'package:mangabaka_app/features/series/models/series_work.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

/// Opens the series a release belongs to, if it has one.
Future<void> openUpcomingSeries(BuildContext context, SeriesWork work) async {
  if (work.seriesId == null) return;
  try {
    final series = await getIt<SeriesService>().fetchSeries('${work.seriesId}');
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).push(AppTransitions.slideUp(SeriesDetailScreen(series: series)));
  } catch (_) {}
}

/// Releases coming up, grouped by day, with a switch to show only the ones
/// from the user's library. The phone's counterpart of the desktop Home's
/// upcoming sidebar.
class UpcomingWorksScreen extends StatefulWidget {
  /// Data the Home rail already loaded, shown immediately while a refresh runs.
  final UpcomingData? initial;

  const UpcomingWorksScreen({super.key, this.initial});

  static void open(BuildContext context, {UpcomingData? initial}) {
    Navigator.of(context).push(
      AppTransitions.slideRight(UpcomingWorksScreen(initial: initial)),
    );
  }

  @override
  State<UpcomingWorksScreen> createState() => _UpcomingWorksScreenState();
}

class _UpcomingWorksScreenState extends State<UpcomingWorksScreen> {
  final HomeService _home = HomeService();
  late UpcomingData _data = widget.initial ?? UpcomingData.empty;
  late bool _loading = widget.initial == null;
  bool _onlyLibrary = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _home.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await UpcomingData.load(_home);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  bool _loadingMore = false;

  /// Reaches one page further into the future.
  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    final data = await _data.loadMore(_home);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loadingMore = false;
    });
  }

  /// Chronological days; works with no parseable date collect at the end.
  List<({DateTime? day, List<SeriesWork> works})> _groups(
    List<SeriesWork> works,
  ) {
    final byDay = <DateTime, List<SeriesWork>>{};
    final undated = <SeriesWork>[];
    for (final w in works) {
      final d = UpcomingData.dayOf(w);
      if (d == null) {
        undated.add(w);
      } else {
        byDay.putIfAbsent(d, () => []).add(w);
      }
    }
    final days = byDay.keys.toList()..sort();
    return [
      for (final d in days) (day: d, works: byDay[d]!),
      if (undated.isNotEmpty) (day: null, works: undated),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final works = _onlyLibrary
        ? _data.works.where(_data.isInLibrary).toList()
        : _data.works;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: mbScreenAppBar(title: l10n.translate('upcoming_releases')),
      body: WidgetUtils.responsiveConstraint(
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.horizontalPadding,
                8,
                AppConstants.horizontalPadding,
                8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: MbPill(
                      label: l10n.translate('all'),
                      selected: !_onlyLibrary,
                      expand: true,
                      onTap: () => setState(() => _onlyLibrary = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MbPill(
                      label: l10n.translate('library'),
                      selected: _onlyLibrary,
                      expand: true,
                      onTap: () => setState(() => _onlyLibrary = true),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: MbSpinner())
                  : MbRefreshIndicator(
                      onRefresh: _load,
                      child: works.isEmpty
                          ? _empty(l10n)
                          : _list(works, l10n),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(LocalizationService l10n) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      const SizedBox(height: 96),
      Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          _onlyLibrary
              ? l10n.translate('no_upcoming_in_library')
              : l10n.translate('no_results'),
          textAlign: TextAlign.center,
          style: AppTypography.sans(color: context.colors.textMuted),
        ),
      ),
    ],
  );

  Widget _list(List<SeriesWork> works, LocalizationService l10n) {
    final rows = <Widget>[];
    for (final group in _groups(works)) {
      rows.add(_DayHeader(day: group.day, first: rows.isEmpty, l10n: l10n));
      for (final work in group.works) {
        rows.add(
          _WorkRow(
            work: work,
            cover: _data.coverFor(work),
            inLibrary: _data.isInLibrary(work),
            onTap: work.seriesId == null
                ? null
                : () => openUpcomingSeries(context, work),
          ),
        );
      }
    }
    if (_data.hasMore && !_onlyLibrary) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _loadingMore
              ? const Center(child: MbSpinner())
              : MbPill(
                  label: l10n.translate('upcoming_load_more'),
                  expand: true,
                  icon: Icons.expand_more_rounded,
                  onTap: _loadMore,
                ),
        ),
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppConstants.horizontalPadding,
        0,
        AppConstants.horizontalPadding,
        // Clear of Android's system navigation area.
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: rows,
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime? day;
  final bool first;
  final LocalizationService l10n;

  const _DayHeader({
    required this.day,
    required this.first,
    required this.l10n,
  });

  String _relative(DateTime d) {
    final now = DateTime.now();
    final days = d.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days == 0) return l10n.translate('upcoming_today');
    if (days == 1) return l10n.translate('upcoming_tomorrow');
    return DateFormat('EEEE').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final d = day;
    final isToday = d != null && _relative(d) == l10n.translate('upcoming_today');
    return Padding(
      padding: EdgeInsets.fromLTRB(0, first ? 8 : 20, 0, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            d == null
                ? l10n.translate('upcoming_date_tba').toUpperCase()
                : DateFormat('d MMM').format(d).toUpperCase(),
            style: AppTypography.display(
              color: isToday ? context.colors.accent : context.colors.text,
              fontSize: d == null ? 14 : 20,
            ),
          ),
          if (d != null) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _relative(d).toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.monoLabel(
                  color: context.colors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkRow extends StatelessWidget {
  final SeriesWork work;
  final String? cover;
  final bool inLibrary;
  final VoidCallback? onTap;

  const _WorkRow({
    required this.work,
    required this.cover,
    required this.inLibrary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = work.seriesTitle ?? work.subTitle;
    final volume = work.sequenceString.isNotEmpty
        ? 'Vol. ${work.sequenceString}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 52,
                    height: 76,
                    child: cover == null
                        ? ColoredBox(
                            color: context.colors.surfaceRaised,
                            child: Icon(
                              Icons.book_outlined,
                              size: 20,
                              color: context.colors.textMuted,
                            ),
                          )
                        : WidgetUtils.networkImage(
                            url: cover!,
                            fit: BoxFit.cover,
                            memCacheWidth: 160,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.sans(
                          color: context.colors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (volume.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          volume,
                          style: AppTypography.sans(
                            color: context.colors.textMuted,
                            fontSize: 12.5,
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
                            LocalizationService()
                                .translate('upcoming_in_library')
                                .toUpperCase(),
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
        ),
      ),
    );
  }
}

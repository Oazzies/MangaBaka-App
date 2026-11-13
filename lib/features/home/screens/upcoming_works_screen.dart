import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
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
import 'package:mangabaka_app/features/home/widgets/upcoming_work_row.dart';
import 'package:mangabaka_app/features/series/models/series_work.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';

/// Opens the series a release belongs to, if it has one.
Future<void> openUpcomingSeries(BuildContext context, SeriesWork work) async {
  if (work.seriesId == null) return;
  try {
    final series = await getIt<SeriesService>().fetchSeries('${work.seriesId}');
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).push(AppTransitions.slideUp(SeriesDetailScreen(series: series)));
  } catch (e, st) {
    LoggingService.logger.warning(
      'Opening series ${work.seriesId} failed',
      e,
      st,
    );
    if (context.mounted) {
      AppSnackBar.show(
        context,
        LocalizationService().translate('open_series_failed'),
        isError: true,
      );
    }
  }
}

/// Releases coming up, grouped by day, with a switch to show only the ones
/// from the user's library. The phone's counterpart of the desktop Home's
/// upcoming sidebar.
class UpcomingWorksScreen extends StatefulWidget {
  /// Data the Home rail already loaded, shown immediately while a refresh runs.
  final UpcomingData? initial;

  /// Replaces the network and database load.
  @visibleForTesting
  final Future<UpcomingData> Function()? loader;

  const UpcomingWorksScreen({super.key, this.initial, this.loader});

  static void open(BuildContext context, {UpcomingData? initial}) {
    Navigator.of(
      context,
    ).push(AppTransitions.slideRight(UpcomingWorksScreen(initial: initial)));
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
    final data = await (widget.loader?.call() ?? UpcomingData.load(_home));
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
    _resolveLibrary();
  }

  /// Fills in the library marks in the background; the list is usable meanwhile.
  Future<void> _resolveLibrary() async {
    final resolved = await _data.withLibrary();
    if (!mounted) return;
    setState(() => _data = resolved);
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
    _resolveLibrary();
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
    // Until the library marks are in, a library-only list would be wrong, so
    // it waits behind the spinner instead.
    final waitingForLibrary = _onlyLibrary && !_data.libraryReady;
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
              child: _loading || waitingForLibrary
                  ? const Center(child: MbSpinner())
                  : MbRefreshIndicator(
                      onRefresh: _load,
                      child: works.isEmpty ? _empty(l10n) : _list(works, l10n),
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
      rows.add(
        UpcomingDayHeader(day: group.day, first: rows.isEmpty, l10n: l10n),
      );
      for (final work in group.works) {
        rows.add(
          UpcomingWorkRow(
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

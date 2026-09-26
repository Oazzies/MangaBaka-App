import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_cover_card.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/desktop/widgets/series_hover_preview.dart';
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:mangabaka_app/features/news/services/news_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// News on desktop: a multi-column feed filterable by source, with a side
/// column ranking the series the loaded stories mention most.
class DesktopNewsScreen extends StatefulWidget {
  static final GlobalKey<DesktopNewsScreenState> stateKey =
      GlobalKey<DesktopNewsScreenState>();

  const DesktopNewsScreen({super.key});

  @override
  State<DesktopNewsScreen> createState() => DesktopNewsScreenState();
}

class DesktopNewsScreenState extends State<DesktopNewsScreen>
    implements DesktopRefreshable {
  static final _logger = LoggingService.logger;

  /// Width of the "in the news" column; hidden below [_asideMinWidth].
  static const double _asideWidth = 320;
  static const double _asideMinWidth = 1100;

  /// Narrowest a feed column gets before the feed drops a column.
  static const double _minColumnWidth = 380;

  late final NewsService _service;
  final ScrollController _scroll = ScrollController();
  final List<News> _news = [];

  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  /// Null shows every source.
  String? _source;

  @override
  void initState() {
    super.initState();
    _service = getIt<NewsService>();
    _scroll.addListener(_onScroll);
    _loadCachedThenFetch();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadCachedThenFetch() async {
    final cached = await _service.getCachedNews();
    if (mounted && cached.isNotEmpty) {
      setState(() => _news.addAll(cached));
    }
    await _fetch(initial: true);
  }

  @override
  Future<void> refresh() => _fetch(initial: true);

  Future<void> _fetch({bool initial = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = initial ? 1 : _page;
      final items = await _service.fetchNews(
        page: page,
        limit: AppConstants.defaultPageLimit,
      );
      if (!mounted) return;
      setState(() {
        if (initial) _news.clear();
        _news.addAll(items);
        _page = page + 1;
        _hasMore = items.length == AppConstants.defaultPageLimit;
        _loading = false;
      });
      // A first page that does not fill the window leaves nothing to scroll.
      WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
    } catch (e) {
      _logger.severe('Desktop news fetch failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = LocalizationService().translate('failed_to_load');
      });
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients || !_hasMore || _loading) return;
    final p = _scroll.position;
    if (p.pixels >= p.maxScrollExtent - 600) _fetch();
  }

  List<News> get _visible => _source == null
      ? _news
      : _news.where((n) => n.source == _source).toList();

  /// Series mentioned across the loaded stories, most-mentioned first.
  ///
  /// Keyed by title: separate volumes or editions of one work are separate
  /// series, but listing the same name three times reads as a bug.
  List<(Series, int)> _mentioned() {
    final counts = <String, (Series, int)>{};
    for (final n in _news) {
      final seen = <String>{};
      for (final s in n.series) {
        final key = s.title.trim().toLowerCase();
        if (!seen.add(key)) continue;
        final prev = counts[key];
        counts[key] = (prev?.$1 ?? s, (prev?.$2 ?? 0) + 1);
      }
    }
    final list = counts.values.toList()..sort((a, b) => b.$2.compareTo(a.$2));
    return list.take(12).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), SettingsManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();
        return DerivedLayoutBuilder<bool>(
          derive: (constraints) => constraints.maxWidth >= _asideMinWidth,
          builder: (context, showAside) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _feed(l10n)),
                if (showAside)
                  Container(
                    width: _asideWidth,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: context.colors.border),
                      ),
                    ),
                    child: _aside(l10n),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _feed(LocalizationService l10n) {
    final sources = <String>{for (final n in _news) n.source}
      ..removeWhere((s) => s.isEmpty);
    final visible = _visible;

    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverToBoxAdapter(
          child: DesktopPageHeader(
            title: l10n.translate('news'),
            subtitle: l10n.translate('news_subtitle'),
            actions: [
              DesktopIconButton(
                icon: Icons.refresh_rounded,
                filled: true,
                tooltip: '${l10n.translate('retry')}  (Ctrl+R)',
                onPressed: refresh,
              ),
            ],
          ),
        ),
        if (sources.length > 1)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesktopTokens.pagePadding,
                0,
                DesktopTokens.pagePadding,
                18,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: DesktopSegmented<String?>(
                  value: _source,
                  segments: [
                    (null, l10n.translate('all_sources'), null),
                    for (final s in sources) (s, s, null),
                  ],
                  onChanged: (s) => setState(() => _source = s),
                ),
              ),
            ),
          ),
        if (visible.isEmpty && !_loading)
          SliverFillRemaining(
            hasScrollBody: false,
            child: DesktopEmptyState(
              icon: Icons.newspaper_rounded,
              message: _error ?? l10n.translate('no_results'),
              action: _error == null
                  ? null
                  : DesktopPillButton(
                      label: l10n.translate('retry'),
                      icon: Icons.refresh_rounded,
                      onPressed: refresh,
                    ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesktopTokens.pagePadding,
            ),
            // Rebuilt only when the column count changes; between those a
            // resize just re-lays the cards out.
            sliver: DerivedSliverLayoutBuilder<int>(
              derive: (constraints) =>
                  (constraints.crossAxisExtent / _minColumnWidth).floor().clamp(
                    1,
                    3,
                  ),
              builder: (context, columns) {
                const gap = 16.0;
                return SliverToBoxAdapter(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var c = 0; c < columns; c++) ...[
                        if (c > 0) const SizedBox(width: gap),
                        Expanded(
                          child: Column(
                            children: [
                              for (var i = c; i < visible.length; i += columns)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: gap),
                                  child: _NewsCard(
                                    key: ValueKey('news_${visible[i].id}'),
                                    news: visible[i],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        if (_loading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _aside(LocalizationService l10n) {
    final mentioned = _mentioned();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      children: [
        DesktopSectionTitle(title: l10n.translate('in_the_news'), fontSize: 17),
        if (mentioned.isEmpty)
          Text(
            l10n.translate('no_results'),
            style: AppTypography.sans(
              color: context.colors.textMuted,
              fontSize: 13,
            ),
          ),
        for (final (series, count) in mentioned)
          _MentionRow(series: series, count: count),
      ],
    );
  }
}

String _formatDate(String date) {
  if (date.isEmpty) return '';
  try {
    return DateFormat('MMM d, yyyy').format(DateTime.parse(date));
  } catch (_) {
    return date;
  }
}

class _NewsCard extends StatelessWidget {
  final News news;

  const _NewsCard({super.key, required this.news});

  static const double _coverWidth = 72;
  static const double _coverSpacing = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();

    return DesktopHoverSurface(
      onTap: () => launchUrl(Uri.parse(news.url)),
      idleColor: context.colors.surface,
      hoverColor: context.colors.surfaceRaised,
      borderRadius: BorderRadius.circular(DesktopTokens.panelRadius),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 28),
                child: Row(
                  children: [
                    if (news.source.isNotEmpty)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.accent.withValues(
                              alpha: 0.14,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppConstants.pillRadius,
                            ),
                          ),
                          child: Text(
                            news.source.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.monoLabel(
                              color: context.colors.accent,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ),
                    if (news.source.isNotEmpty) const SizedBox(width: 10),
                    Text(
                      _formatDate(news.publishedAt),
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                news.title,
                style: AppTypography.sans(
                  color: context.colors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              if (news.author.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '${l10n.translate('by_author')} ${news.author}',
                  style: AppTypography.sans(
                    color: context.colors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
              if (news.series.isNotEmpty) ...[
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final total = news.series.length;
                    // How many cover-sized slots actually fit on one row.
                    final perRow =
                        ((constraints.maxWidth + _coverSpacing) /
                                (_coverWidth + _coverSpacing))
                            .floor()
                            .clamp(1, total);
                    // If everything fits, no overflow tile is needed; otherwise
                    // the last slot on the row becomes the "+x" tile instead of
                    // wrapping it alone onto a second row.
                    final showCount = total <= perRow ? total : perRow - 1;
                    final extra = total - showCount;
                    return Wrap(
                      spacing: _coverSpacing,
                      runSpacing: _coverSpacing,
                      children: [
                        for (final s in news.series.take(showCount))
                          DesktopCoverCard(
                            series: s,
                            width: _coverWidth,
                            showTitle: false,
                            heroTag: 'news_${news.id}',
                          ),
                        if (extra > 0)
                          Container(
                            width: _coverWidth,
                            height: 108,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: context.colors.surfaceRaised,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+$extra',
                              style: AppTypography.display(
                                color: context.colors.textMuted,
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: context.colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MentionRow extends StatelessWidget {
  final Series series;
  final int count;

  const _MentionRow({required this.series, required this.count});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SeriesHoverPreview(
        series: series,
        child: DesktopHoverSurface(
          onTap: () => openSeriesDetail(context, series, heroTag: 'news_aside'),
          borderRadius: BorderRadius.circular(10),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: WidgetUtils.networkImage(
                  url: series.coverUrl,
                  blurred: WidgetUtils.isRatingBlurred(series.contentRating),
                  width: 40,
                  height: 60,
                  memCacheWidth: 100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.getDisplayTitle(
                        SettingsManager().defaultTitleLanguage,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sans(
                        color: context.colors.text,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n
                          .translate('mention_count')
                          .replaceAll('{count}', '$count'),
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

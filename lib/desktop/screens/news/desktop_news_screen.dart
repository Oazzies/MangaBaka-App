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
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';

part 'desktop_news_aside_part.dart';
part 'desktop_news_cards_part.dart';

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
    } catch (e, st) {
      _logger.severe('Desktop news fetch failed', e, st);
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
                Expanded(child: _feed(l10n, showAside: showAside)),
                if (showAside)
                  Container(
                    width: _asideWidth,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: context.colors.border),
                      ),
                    ),
                    child: _NewsAsidePanel(mentioned: _mentioned()),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _feed(LocalizationService l10n, {required bool showAside}) {
    final sources = <String>{for (final n in _news) n.source}
      ..removeWhere((s) => s.isEmpty);
    final visible = _visible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopPageHeader(
          title: l10n.translate('news'),
          subtitle: l10n.translate('news_subtitle'),
          // With the aside beside it, the window controls float over the
          // aside, so the header's own actions need not dodge them (as on
          // Home).
          reserveWindowControls: !showAside,
          actions: [
            DesktopIconButton(
              icon: Icons.refresh_rounded,
              filled: true,
              tooltip: '${l10n.translate('retry')}  (Ctrl+R)',
              onPressed: refresh,
            ),
          ],
        ),
        Expanded(
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
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
                _NewsMasonrySliver(
                  visible: visible,
                  minColumnWidth: _minColumnWidth,
                ),
              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: MbSpinner()),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ],
    );
  }
}

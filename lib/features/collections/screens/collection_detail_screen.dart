import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/features/collections/services/collection_service.dart';
import 'package:mangabaka_app/features/collections/widgets/collection_card.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';
import 'package:mangabaka_app/features/series/models/series_work.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// A collection opened into its works: the collection's summary, then every
/// release in it (volumes, boxed sets, extras) as a cover grid.
class CollectionDetailScreen extends StatefulWidget {
  final SeriesCollection collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  static final _logger = LoggingService.logger;

  late final CollectionService _service;
  final ScrollController _scroll = ScrollController();
  final List<SeriesWork> _works = [];

  int _page = 1;
  bool _hasNext = true;
  bool _loading = true;
  bool _inFlight = false;
  bool _failed = false;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _service = getIt<CollectionService>();
    _scroll.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (!_hasNext || _inFlight) return;
    _inFlight = true;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final page = await _service.fetchCollectionWorks(
        widget.collection.id,
        page: _page,
      );
      if (!mounted) return;
      setState(() {
        _works.addAll(page.items);
        _hasNext = page.hasNext;
        _page++;
        _loading = false;
      });
    } catch (e) {
      _logger.warning('Collection works failed: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _openSeries() async {
    final id = widget.collection.seriesId;
    if (id.isEmpty || _opening) return;
    setState(() => _opening = true);
    try {
      final series = await getIt<SeriesService>().fetchSeries(id);
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(AppTransitions.slideRight(SeriesDetailScreen(series: series)));
    } catch (_) {
      // The series page is a convenience here; the works are the point.
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final col = widget.collection;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: mbScreenAppBar(title: l10n.translate('tab_collections')),
      body: WidgetUtils.responsiveConstraint(
        maxWidth: 1100,
        CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CollectionCard(collection: col),
                    if (col.seriesId.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _opening ? null : _openSeries,
                          child: Text(
                            l10n.translate('open_series').toUpperCase(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_works.isEmpty && !_loading && !_failed)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    l10n.translate('no_works_available'),
                    style: AppTypography.sans(color: context.colors.textMuted),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 156,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.5,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _WorkTile(work: _works[i]),
                    childCount: _works.length,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator()
                      : _failed
                      ? TextButton(
                          onPressed: _loadMore,
                          child: Text(l10n.translate('retry')),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkTile extends StatelessWidget {
  final SeriesWork work;

  const _WorkTile({required this.work});

  @override
  Widget build(BuildContext context) {
    final label = work.sequenceString.isNotEmpty
        ? 'Vol. ${work.sequenceString}'
        : (work.subTitle.isNotEmpty ? work.subTitle : work.countType);
    final cover = work.imageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 2 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: cover != null && cover.isNotEmpty
                ? WidgetUtils.networkImage(
                    url: cover,
                    fit: BoxFit.cover,
                    memCacheWidth: 300,
                  )
                : Container(
                    color: context.colors.surfaceRaised,
                    child: Icon(
                      Icons.book_outlined,
                      color: context.colors.textMuted,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.display(
            color: context.colors.text,
            fontSize: 13,
          ),
        ),
        if (work.releaseDate.isNotEmpty)
          Text(
            work.releaseDate,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sans(
              color: context.colors.textMuted,
              fontSize: 12,
            ),
          ),
        if (work.priceString != null)
          Text(
            work.priceString!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sans(
              color: context.colors.textMuted,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}

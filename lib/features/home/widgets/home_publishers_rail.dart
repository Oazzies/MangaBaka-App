import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_carousel.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/screens/publisher_detail_screen.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:mangabaka_app/features/publisher/utils/format_count.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_logo.dart';

/// A discovery extra: it disappears on failure or an empty result rather than showing an error.
class HomePublishersRail extends StatefulWidget {
  final PublisherSearchService service;

  final double horizontalPadding;

  const HomePublishersRail({
    super.key,
    required this.service,
    this.horizontalPadding = AppConstants.horizontalPadding,
  });

  @override
  State<HomePublishersRail> createState() => _HomePublishersRailState();
}

class _HomePublishersRailState extends State<HomePublishersRail> {
  static const int _count = 16;

  List<Publisher>? _publishers;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final found = await widget.service.searchPublishers(
        limit: _count,
        sortBy: PublisherSearchService.sortSeriesCountDesc,
      );
      if (mounted) setState(() => _publishers = found);
    } catch (e) {
      LoggingService.logger.warning('Popular publishers rail failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final publishers = _publishers;
    if (publishers == null || publishers.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = LocalizationService();

    if (DesktopLayout.isActive(context)) {
      return DesktopCarousel(
        title: l10n.translate('popular_publishers'),
        itemCount: publishers.length,
        itemWidth: 236,
        stretch: true,
        itemHeight: (_) => 92,
        itemBuilder: (context, i) =>
            _DesktopPublisherCard(publisher: publishers[i], l10n: l10n),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MbSectionHeader(title: l10n.translate('popular_publishers')),
        SizedBox(
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
            itemCount: publishers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => MbEntrance(
              index: i,
              child: _PublisherCard(publisher: publishers[i], l10n: l10n),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PublisherCard extends StatelessWidget {
  final Publisher publisher;
  final LocalizationService l10n;

  const _PublisherCard({required this.publisher, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      child: MbTappable(
        pressedScale: 0.95,
        onTap: () => PublisherDetailScreen.open(
          context,
          id: publisher.id,
          publisher: publisher,
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PublisherLogoView(publisher: publisher, size: 44),
              const SizedBox(height: 8),
              Text(
                publisher.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sans(
                  color: context.colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (publisher.seriesCount != null)
                Text(
                  l10n
                      .translate('publisher_series_count')
                      .replaceAll(
                        '{count}',
                        formatCount(publisher.seriesCount!),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sans(
                    color: context.colors.textMuted,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopPublisherCard extends StatelessWidget {
  final Publisher publisher;
  final LocalizationService l10n;

  const _DesktopPublisherCard({required this.publisher, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return DesktopHoverSurface(
      onTap: () => PublisherDetailScreen.open(
        context,
        id: publisher.id,
        publisher: publisher,
      ),
      idleColor: context.colors.surface,
      borderRadius: BorderRadius.circular(DesktopTokens.panelRadius),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          PublisherLogoView(publisher: publisher, size: 60),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  publisher.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sans(
                    color: context.colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (publisher.seriesCount != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n
                        .translate('publisher_series_count')
                        .replaceAll(
                          '{count}',
                          formatCount(publisher.seriesCount!),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.displayLabel(
                      color: context.colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

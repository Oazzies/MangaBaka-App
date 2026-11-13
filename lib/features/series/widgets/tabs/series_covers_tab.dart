import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series_cover.dart';
import 'package:mangabaka_app/features/series/widgets/series_section_header.dart';
import 'package:mangabaka_app/features/series/widgets/tabs/series_cover_item.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class SeriesCoversTab extends StatelessWidget {
  final List<SeriesCover>? covers;
  final double horizontalPadding;
  final String? contentRating;

  const SeriesCoversTab({
    super.key,
    this.covers,
    this.horizontalPadding = 16.0,
    this.contentRating,
  });

  @override
  Widget build(BuildContext context) {
    if (covers == null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: _buildCoverSkeleton(),
      );
    }
    final l10n = LocalizationService();
    if (covers == null || covers!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(l10n.translate('no_covers_available')),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SeriesSectionHeader(title: l10n.translate('tab_covers')),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            itemCount: covers!.length,
            itemBuilder: (context, index) {
              final cover = covers![index];
              final url =
                  cover.url ?? cover.urlX350 ?? cover.urlX250 ?? cover.urlX150;
              final title = _formatCoverTitle(cover);

              return HoverableCoverItem(
                cover: cover,
                allCovers: covers!,
                url: url,
                title: title,
                contentRating: contentRating,
                allTitles: covers!.map((c) => _formatCoverTitle(c)).toList(),
                allNotes: covers!.map((c) => c.note).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCoverSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SeriesSectionHeader(
          title: LocalizationService().translate('tab_covers'),
        ),
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 150,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.65,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            return Container(
                  decoration: BoxDecoration(
                    color: context.colors.surfaceRaised,
                    borderRadius: BorderRadius.circular(8),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: 1500.ms,
                  color: context.colors.surfaceRaised,
                );
          },
        ),
      ],
    );
  }

  String _getLanguageBadge(String lang) {
    switch (lang.toLowerCase()) {
      case 'en':
        return 'EN';
      case 'ko':
        return 'KO';
      case 'pt-br':
        return 'BR';
      case 'es':
        return 'ES';
      case 'ja':
        return 'JA';
      case 'zh':
        return 'ZH';
      case 'fr':
        return 'FR';
      case 'de':
        return 'DE';
      case 'it':
        return 'IT';
      case 'ru':
        return 'RU';
      case 'pt':
        return 'PT';
      default:
        return lang.toUpperCase();
    }
  }

  String _formatCoverTitle(SeriesCover cover) {
    String typeStr;
    final type = cover.type ?? '';
    switch (type) {
      case 'volume':
        typeStr = 'Front';
        break;
      case 'volume_back':
        typeStr = 'Back';
        break;
      case 'other':
        typeStr = 'Other';
        break;
      case 'magazine':
        typeStr = 'Magazine';
        break;
      case 'dust_jacket':
        typeStr = 'Dust Jacket';
        break;
      case 'obi':
        typeStr = 'Obi';
        break;
      case 'wrap_around':
        typeStr = 'Wrap Around';
        break;
      default:
        typeStr = type.isNotEmpty
            ? type[0].toUpperCase() + type.substring(1).replaceAll('_', ' ')
            : 'Cover';
    }

    final langBadge = _getLanguageBadge(cover.language ?? '');
    String title = langBadge.isNotEmpty ? '[$langBadge] $typeStr' : typeStr;

    if (type == 'volume' || type == 'volume_back') {
      title += ' (Volume)';
    }

    final index = cover.index ?? '';
    if (index.isNotEmpty) {
      title += ' $index';
    }

    return title;
  }
}

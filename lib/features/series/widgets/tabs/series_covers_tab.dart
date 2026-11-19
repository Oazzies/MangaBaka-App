import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series_cover.dart';
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

  static const _typeKeys = {
    'volume': 'cover_type_front',
    'volume_back': 'cover_type_back',
    'other': 'cover_type_other',
    'magazine': 'cover_type_magazine',
    'dust_jacket': 'cover_type_dust_jacket',
    'obi': 'cover_type_obi',
    'wrap_around': 'cover_type_wrap_around',
  };

  static const _gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 150,
    mainAxisSpacing: 16,
    crossAxisSpacing: 16,
    childAspectRatio: 0.65,
  );

  @override
  Widget build(BuildContext context) {
    if (covers == null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: _buildCoverSkeleton(),
      );
    }
    final l10n = LocalizationService();
    if (covers!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(l10n.translate('no_covers_available')),
        ),
      );
    }

    final titles = [for (final c in covers!) _formatCoverTitle(l10n, c)];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: _gridDelegate,
        itemCount: covers!.length,
        itemBuilder: (context, index) {
          final cover = covers![index];
          final url =
              cover.url ?? cover.urlX350 ?? cover.urlX250 ?? cover.urlX150;

          return HoverableCoverItem(
            cover: cover,
            allCovers: covers!,
            url: url,
            title: titles[index],
            contentRating: contentRating,
            allTitles: titles,
            allNotes: covers!.map((c) => c.note).toList(),
          );
        },
      ),
    );
  }

  Widget _buildCoverSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: _gridDelegate,
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
              decoration: BoxDecoration(
                color: context.colors.surfaceRaised,
                borderRadius: BorderRadius.circular(8),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 1500.ms, color: context.colors.surfaceRaised);
      },
    );
  }

  String _getLanguageBadge(String lang) {
    switch (lang.toLowerCase()) {
      case 'pt-br':
        return 'BR';
      default:
        return lang.toUpperCase();
    }
  }

  String _typeLabel(LocalizationService l10n, String type) {
    final key = _typeKeys[type];
    if (key != null) return l10n.translate(key);
    if (type.isEmpty) return l10n.translate('cover_type_cover');
    return type[0].toUpperCase() + type.substring(1).replaceAll('_', ' ');
  }

  String _formatCoverTitle(LocalizationService l10n, SeriesCover cover) {
    final type = cover.type ?? '';
    var label = _typeLabel(l10n, type);
    if (type == 'volume' || type == 'volume_back') {
      label = l10n.translate('cover_title_volume').replaceAll('{type}', label);
    }

    final langBadge = _getLanguageBadge(cover.language ?? '');
    var title = langBadge.isNotEmpty ? '[$langBadge] $label' : label;

    final index = cover.index ?? '';
    if (index.isNotEmpty) {
      title += ' $index';
    }

    return title;
  }
}

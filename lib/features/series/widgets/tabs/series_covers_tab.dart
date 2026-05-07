import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/series/models/series_cover.dart';
import 'package:bakahyou/features/series/screens/full_screen_image_screen.dart';
import 'package:bakahyou/features/series/widgets/series_section_header.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SeriesCoversTab extends StatelessWidget {
  final List<SeriesCover>? covers;
  final double horizontalPadding;

  const SeriesCoversTab({super.key, this.covers, this.horizontalPadding = 16.0});

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
      return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text(l10n.translate('no_covers_available'))));
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
              final url = cover.url ?? cover.urlX350 ?? cover.urlX250 ?? cover.urlX150;
              final title = _formatCoverTitle(cover);
              
              return GestureDetector(
                onTap: () {
                  if (url != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImageScreen(
                          imageUrl: url,
                          heroTag: url,
                          title: title,
                          note: cover.note,
                        ),
                      ),
                    );
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: url != null
                            ? Hero(
                                tag: url,
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(color: AppConstants.secondaryBackground, child: const Icon(Icons.broken_image)),
                                ),
                              )
                            : Container(color: AppConstants.secondaryBackground, child: const Icon(Icons.broken_image)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppConstants.textColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
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
        const SeriesSectionHeader(title: 'Covers'),
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
                color: AppConstants.tertiaryBackground,
                borderRadius: BorderRadius.circular(8),
              ),
            ).animate(onPlay: (controller) => controller.repeat())
             .shimmer(duration: 1500.ms, color: AppConstants.borderColor.withValues(alpha: 0.3));
          },
        ),
      ],
    );
  }

  String _getLanguageBadge(String lang) {
    switch (lang.toLowerCase()) {
      case 'en': return 'EN';
      case 'ko': return 'KO';
      case 'pt-br': return 'BR';
      case 'es': return 'ES';
      case 'ja': return 'JA';
      case 'zh': return 'ZH';
      case 'fr': return 'FR';
      case 'de': return 'DE';
      case 'it': return 'IT';
      case 'ru': return 'RU';
      case 'pt': return 'PT';
      default: return lang.toUpperCase();
    }
  }

  String _formatCoverTitle(SeriesCover cover) {
    String typeStr;
    final type = cover.type ?? '';
    switch (type) {
      case 'volume': typeStr = 'Front'; break;
      case 'volume_back': typeStr = 'Back'; break;
      case 'other': typeStr = 'Other'; break;
      case 'magazine': typeStr = 'Magazine'; break;
      case 'dust_jacket': typeStr = 'Dust Jacket'; break;
      case 'obi': typeStr = 'Obi'; break;
      case 'wrap_around': typeStr = 'Wrap Around'; break;
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

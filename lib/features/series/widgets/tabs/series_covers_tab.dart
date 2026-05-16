import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/models/series_cover.dart';
import 'package:mangabaka_app/features/series/screens/full_screen_image_screen.dart';
import 'package:mangabaka_app/features/series/widgets/series_section_header.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
              
              return _HoverableCoverItem(
                cover: cover,
                url: url,
                title: title,
                contentRating: contentRating,
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
        SeriesSectionHeader(title: LocalizationService().translate('tab_covers')),
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

/// A cover grid item that shows an accent border on hover.
class _HoverableCoverItem extends StatefulWidget {
  final SeriesCover cover;
  final String? url;
  final String title;
  final String? contentRating;

  const _HoverableCoverItem({
    required this.cover,
    required this.url,
    required this.title,
    this.contentRating,
  });

  @override
  State<_HoverableCoverItem> createState() => _HoverableCoverItemState();
}

class _HoverableCoverItemState extends State<_HoverableCoverItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.url != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          if (widget.url != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImageScreen(
                  imageUrl: widget.url!,
                  heroTag: widget.url!,
                  title: widget.title,
                  note: widget.cover.note,
                ),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: _hovered && widget.url != null
                      ? Border.all(
                          color: AppConstants.accentColor.withValues(alpha: 0.6),
                          width: 2,
                        )
                      : Border.all(color: Colors.transparent, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: widget.url != null
                      ? Hero(
                          tag: widget.url!,
                          child: ListenableBuilder(
                            listenable: SettingsManager(),
                            builder: (context, _) {
                              final isBlurred = widget.contentRating != null &&
                                  SettingsManager().blurredContentRatings.contains(widget.contentRating!.toLowerCase());
                              return WidgetUtils.networkImage(
                                url: widget.url!,
                                fit: BoxFit.cover,
                                memCacheWidth: 300,
                                blurred: isBlurred,
                              );
                            },
                          ),
                        )
                      : Container(
                          color: AppConstants.secondaryBackground,
                          child: const Icon(Icons.broken_image),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/series/models/series_work.dart';
import 'package:bakahyou/features/series/widgets/series_section_header.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';

class SeriesWorksTab extends StatelessWidget {
  final List<SeriesWork>? works;
  final double horizontalPadding;

  const SeriesWorksTab({
    super.key, 
    this.works,
    this.horizontalPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    if (works == null) return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
    if (works!.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text(l10n.translate('no_works_available'))));
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SeriesSectionHeader(title: l10n.translate('tab_works')),
          ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: works!.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final w = works![index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.secondaryBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppConstants.borderColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 90,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: w.imageUrl != null && w.imageUrl!.isNotEmpty
                            ? Image.network(
                                w.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => _buildPlaceholder(),
                              )
                            : _buildPlaceholder(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  w.subTitle.isNotEmpty ? w.subTitle : l10n.translate('volume_title').replaceAll('{index}', w.sequenceString),
                                  style: TextStyle(color: AppConstants.textColor, fontWeight: FontWeight.bold, fontSize: 15),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (w.priceString != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    w.priceString!,
                                    style: TextStyle(color: AppConstants.accentColor, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.translate('release_date').replaceAll('{date}', w.releaseDate),
                            style: TextStyle(color: AppConstants.textMutedColor, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.description_outlined, size: 14, color: AppConstants.textMutedColor),
                              const SizedBox(width: 4),
                              Text(l10n.translate('pages_count').replaceAll('{count}', w.pages.toString()), style: TextStyle(color: AppConstants.textMutedColor, fontSize: 12)),
                              const SizedBox(width: 12),
                              Icon(Icons.label_outline, size: 14, color: AppConstants.textMutedColor),
                              const SizedBox(width: 4),
                              Text(w.countType, style: TextStyle(color: AppConstants.textMutedColor, fontSize: 12)),
                            ],
                          ),
                        ],
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

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 90,
      color: AppConstants.tertiaryBackground,
      child: Icon(
        Icons.broken_image,
        color: AppConstants.textMutedColor,
        size: 24,
      ),
    );
  }
}

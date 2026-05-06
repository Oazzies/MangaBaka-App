import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/series/models/series_collection.dart';
import 'package:bakahyou/features/series/widgets/series_section_header.dart';

class SeriesCollectionsTab extends StatelessWidget {
  final List<SeriesCollection>? collections;
  final double horizontalPadding;

  const SeriesCollectionsTab({
    super.key, 
    this.collections,
    this.horizontalPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    if (collections == null) return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
    if (collections!.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No collections available.')));
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SeriesSectionHeader(title: 'Collections'),
          ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: collections!.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final col = collections![index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.secondaryBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppConstants.borderColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                col.title,
                                style: TextStyle(color: AppConstants.textColor, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${col.publisherName} • ${col.editionName}',
                                style: TextStyle(color: AppConstants.textMutedColor, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppConstants.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${col.countMain} Vols',
                            style: TextStyle(color: AppConstants.accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildMiniBadge(col.format),
                        _buildMiniBadge(col.medium),
                        _buildMiniBadge(col.status),
                      ],
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

  Widget _buildMiniBadge(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.tertiaryBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: AppConstants.textMutedColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}

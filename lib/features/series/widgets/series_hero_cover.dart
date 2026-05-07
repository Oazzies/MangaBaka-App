import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/series/screens/full_screen_image_screen.dart';

class SeriesHeroCover extends StatelessWidget {
  final Series series;
  final double height;
  final double width;

  const SeriesHeroCover({
    super.key,
    required this.series,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'series_cover_${series.id}',
      child: GestureDetector(
        onTap: () {
          final imageUrl = series.rawCoverUrl.isNotEmpty ? series.rawCoverUrl : series.coverUrl;
          if (imageUrl.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImageScreen(
                  imageUrl: imageUrl,
                  heroTag: 'series_cover_${series.id}',
                ),
              ),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryBackground.withValues(alpha: 0.6),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: series.coverUrl.isNotEmpty 
              ? Image.network(
                  series.coverUrl,
                  height: height,
                  width: width,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  cacheWidth: 400,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                )
              : _buildPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppConstants.secondaryBackground,
      child: Icon(
        Icons.broken_image,
        color: AppConstants.textMutedColor,
        size: width > 50 ? 40 : 24,
      ),
    );
  }
}

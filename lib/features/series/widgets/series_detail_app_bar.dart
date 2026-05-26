import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';

class SeriesDetailAppBar extends StatelessWidget {
  final Series series;
  final bool isWide;
  final bool isLoaded;
  final VoidCallback onBack;

  const SeriesDetailAppBar({
    super.key,
    required this.series,
    required this.isWide,
    required this.isLoaded,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final double height = isWide ? 500.0 : 380.0;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(color: AppConstants.secondaryBackground),
          ),
          Positioned.fill(
            child: WidgetUtils.networkImage(
              url: series.rawCoverUrl.isNotEmpty ? series.rawCoverUrl : series.coverUrl,
              fit: BoxFit.cover,
              memCacheWidth: isWide ? 1200 : 800,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppConstants.primaryBackground.withValues(alpha: 0),
                    AppConstants.primaryBackground.withValues(alpha: 1),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: MediaQuery.of(context).padding.top + 8,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    iconSize: 20,
                    color: Colors.white,
                    onPressed: onBack,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

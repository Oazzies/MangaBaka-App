import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SeriesDetailSkeleton extends StatelessWidget {
  final bool isWide;

  const SeriesDetailSkeleton({super.key, this.isWide = false});

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 300),
          const SizedBox(width: 48),
          Expanded(child: _buildBody()),
        ],
      );
    }
    return _buildBody();
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metadata Chips placeholder
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _skeletonBox(width: 80, height: 24),
            _skeletonBox(width: 60, height: 24),
            _skeletonBox(width: 100, height: 24),
          ],
        ),
        const SizedBox(height: 16),
        // Action Bar placeholder
        _skeletonBox(width: double.infinity, height: 50),
        const SizedBox(height: 20),
        // Description placeholder
        _skeletonBox(width: 150, height: 22),
        const SizedBox(height: 16),
        _skeletonBox(width: double.infinity, height: 14),
        const SizedBox(height: 8),
        _skeletonBox(width: double.infinity, height: 14),
        const SizedBox(height: 8),
        _skeletonBox(width: 200, height: 14),
        const SizedBox(height: 32),
        // Grid items
        _skeletonBox(width: 120, height: 22),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(6, (_) => _skeletonBox(width: 90, height: 35)),
        ),
      ],
    ).animate(onPlay: (controller) => controller.repeat())
     .shimmer(duration: 1500.ms, color: AppConstants.borderColor.withValues(alpha: 0.3));
  }

  Widget _skeletonBox({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppConstants.tertiaryBackground,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';

class SeriesDetailSkeleton extends StatefulWidget {
  final bool isWide;

  const SeriesDetailSkeleton({super.key, this.isWide = false});

  @override
  State<SeriesDetailSkeleton> createState() => _SeriesDetailSkeletonState();
}

class _SeriesDetailSkeletonState extends State<SeriesDetailSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isWide) {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.3 + (_controller.value * 0.4);
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Column(
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
      ),
    );
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

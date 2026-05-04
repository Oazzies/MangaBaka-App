import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SeriesListSkeleton extends StatelessWidget {
  final bool isGrid;

  const SeriesListSkeleton({super.key, required this.isGrid});

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          childAspectRatio: 0.65,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 10,
        itemBuilder: (context, index) => _buildGridSkeleton(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 10,
      itemBuilder: (context, index) => _buildListSkeleton(),
    );
  }

  Widget _buildGridSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: double.infinity, height: 14, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(width: 80, height: 12, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat())
     .shimmer(duration: 1500.ms, color: Colors.white10.withValues(alpha: 0.1));
  }

  Widget _buildListSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 120, // Adjusted to match EntryListItem
      decoration: BoxDecoration(
        color: AppConstants.secondaryBackground,
        borderRadius: BorderRadius.circular(12), // Match EntryListItem card
      ),
      child: Row(
        children: [
          Container(
            width: 80, // Adjusted to match EntryListItem
            decoration: const BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 200, height: 16, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(width: 120, height: 14, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
                  const Spacer(),
                  Row(
                    children: [
                      Container(width: 60, height: 28, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16))),
                      const SizedBox(width: 8),
                      Container(width: 60, height: 28, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat())
     .shimmer(duration: 1500.ms, color: Colors.white10.withValues(alpha: 0.1));
  }
}

import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/widgets/mini_badge.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class RatingChip extends StatelessWidget {
  final List<dynamic> sources;

  const RatingChip({required this.sources, super.key});

  double? _calculateAverageRating() {
    final ratings = sources
        .map((source) => source['rating_normalized'])
        .where((r) => r != null)
        .map((r) => r is num ? r.toDouble() : double.tryParse(r.toString()))
        .where((r) => r != null)
        .cast<double>()
        .toList();

    if (ratings.isEmpty) return null;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  @override
  Widget build(BuildContext context) {
    final avg = _calculateAverageRating();
    if (avg == null) return const SizedBox.shrink();

    return MiniBadge(
      text: '${avg.toStringAsFixed(1)} / 100',
      icon: Icons.star,
      color: AppConstants.accentColor,
      backgroundColor: AppConstants.accentColor.withValues(alpha: 0.1),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/widgets/chip.dart';
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
    if (avg == null) return SizedBox.shrink();

    return ChipBase(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 18, color: AppConstants.textColor),
          SizedBox(width: 4),
          Text(
            '${avg.toStringAsFixed(1)} / 100',
            style: TextStyle(color: AppConstants.textColor),
          ),
        ],
      ),
    );
  }
}

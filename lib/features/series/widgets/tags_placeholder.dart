import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class TagsPlaceholder extends StatelessWidget {
  const TagsPlaceholder({super.key});

  static const List<List<double>> _rows = [
    [90, 130, 70],
    [110, 80, 150],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in _rows) ...[
          Row(
            children: [
              for (final width in row) ...[
                Container(
                  width: width,
                  height: 26,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceRaised.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(
                      AppConstants.pillRadius,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          if (row != _rows.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

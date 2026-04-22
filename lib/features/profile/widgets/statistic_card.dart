import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class StatisticCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const StatisticCard({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppConstants.textColor, size: 22),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: AppConstants.textMutedColor, fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

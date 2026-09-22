import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class StandoutPickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String title;
  final String value;
  final VoidCallback onTap;

  const StandoutPickCard({
    super.key,
    required this.icon,
    required this.label,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.colors.text, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.sans(
              color: context.colors.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Text(
              title,
              style: AppTypography.display(
                color: context.colors.accent,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.sans(
              color: context.colors.text,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

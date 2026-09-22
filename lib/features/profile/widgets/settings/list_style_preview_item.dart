import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_style_preview_thumbnails.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class ListStylePreviewItem extends StatelessWidget {
  final AppListStyle style;
  final bool isSelected;
  final VoidCallback onTap;
  final String label;

  const ListStylePreviewItem({
    super.key,
    required this.style,
    required this.isSelected,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 108,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 160,
              decoration: BoxDecoration(
                color: context.colors.background,
                borderRadius: BorderRadius.circular(AppConstants.denseRadius),
                border: Border.all(
                  color: isSelected
                      ? context.colors.accent
                      : context.colors.border.withValues(alpha: 0.5),
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  isSelected
                      ? (AppConstants.denseRadius - 3)
                      : (AppConstants.denseRadius - 1),
                ),
                child: Container(
                  padding: EdgeInsets.all(isSelected ? 6 : 8),
                  child: ListStylePreviewThumbnails(style: style),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.sans(
                color: isSelected
                    ? context.colors.text
                    : context.colors.textMuted,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

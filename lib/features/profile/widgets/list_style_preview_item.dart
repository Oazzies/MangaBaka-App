import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/settings/settings_enums.dart';

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
                color: AppConstants.primaryBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppConstants.accentColor : AppConstants.borderColor.withValues(alpha: 0.5),
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppConstants.accentColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isSelected ? 13 : 15),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: _buildPreviewContent(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppConstants.textColor : AppConstants.textMutedColor,
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

  Widget _buildPreviewContent() {
    switch (style) {
      case AppListStyle.comfortable:
        return Column(
          children: List.generate(2, (index) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 52,
            decoration: BoxDecoration(
              color: AppConstants.secondaryBackground,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppConstants.borderColor.withValues(alpha: 0.1), width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: AppConstants.tertiaryBackground,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 32, height: 4, color: AppConstants.textMutedColor.withValues(alpha: 0.3)),
                        const SizedBox(height: 3),
                        Container(width: 24, height: 3, color: AppConstants.textMutedColor.withValues(alpha: 0.1)),
                        const Spacer(),
                        Row(
                          children: [
                            Container(width: 9, height: 6, decoration: BoxDecoration(color: AppConstants.textMutedColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(1), border: Border.all(color: AppConstants.textMutedColor.withValues(alpha: 0.1), width: 0.5))),
                            const SizedBox(width: 2),
                            Container(width: 9, height: 6, decoration: BoxDecoration(color: AppConstants.textMutedColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(1), border: Border.all(color: AppConstants.textMutedColor.withValues(alpha: 0.1), width: 0.5))),
                            const SizedBox(width: 2),
                            Container(width: 9, height: 6, decoration: BoxDecoration(color: AppConstants.textMutedColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(1), border: Border.all(color: AppConstants.textMutedColor.withValues(alpha: 0.1), width: 0.5))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )),
        );
      case AppListStyle.compact:
        return Column(
          children: List.generate(3, (index) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            height: 36,
            decoration: BoxDecoration(
              color: AppConstants.secondaryBackground,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppConstants.borderColor.withValues(alpha: 0.1), width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: AppConstants.tertiaryBackground,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 32, height: 4, color: AppConstants.textMutedColor.withValues(alpha: 0.3)),
                      const SizedBox(height: 3),
                      Container(width: 28, height: 3, color: AppConstants.textMutedColor.withValues(alpha: 0.1)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        );
      case AppListStyle.minimalList:
        return Column(
          children: List.generate(4, (index) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            height: 28,
            decoration: BoxDecoration(
              color: AppConstants.secondaryBackground,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppConstants.borderColor.withValues(alpha: 0.1), width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: AppConstants.tertiaryBackground,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 32, height: 4, color: AppConstants.textMutedColor.withValues(alpha: 0.3)),
              ],
            ),
          )),
        );
      case AppListStyle.coverOnlyGrid:
        return GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.7,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(4, (index) => Container(
            decoration: BoxDecoration(
              color: AppConstants.secondaryBackground,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppConstants.borderColor.withValues(alpha: 0.1), width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(color: AppConstants.tertiaryBackground),
            ),
          )),
        );
      case AppListStyle.compactGrid:
        return GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.62,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(4, (index) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppConstants.secondaryBackground,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppConstants.borderColor.withValues(alpha: 0.1), width: 0.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(color: AppConstants.tertiaryBackground),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(child: Container(width: 30, height: 3, color: AppConstants.textMutedColor.withValues(alpha: 0.2))),
            ],
          )),
        );
    }
  }

}

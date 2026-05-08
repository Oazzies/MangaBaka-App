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
                  padding: EdgeInsets.all(isSelected ? 6 : 8),
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
        return ListView(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(5, (index) => Container(
            margin: const EdgeInsets.only(bottom: 5),
            height: 25,
            decoration: BoxDecoration(
              color: AppConstants.secondaryBackground,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: AppConstants.borderColor.withValues(alpha: 0.1), width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: AppConstants.tertiaryBackground,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppConstants.textMutedColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 22,
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppConstants.accentColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 6,
                            color: AppConstants.textMutedColor.withValues(alpha: 0.2),
                          ),
                          const SizedBox(width: 2),
                          Container(
                            width: 8,
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppConstants.textMutedColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        );
      case AppListStyle.compact:
        return ListView(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(6, (index) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            height: 20,
            decoration: BoxDecoration(
              color: AppConstants.secondaryBackground,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: AppConstants.borderColor.withValues(alpha: 0.1), width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 15,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: AppConstants.tertiaryBackground,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 28, height: 3, decoration: BoxDecoration(color: AppConstants.textMutedColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(1.5))),
                      const SizedBox(height: 3),
                      Container(width: 32, height: 2, decoration: BoxDecoration(color: AppConstants.textMutedColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(1))),
                    ],
                  ),
                ),
              ],
            ),
          )),
        );
      case AppListStyle.minimalList:
        return ListView(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(8, (index) => Container(
            margin: const EdgeInsets.only(bottom: 3),
            height: 16,
            decoration: BoxDecoration(
              color: AppConstants.secondaryBackground,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: AppConstants.borderColor.withValues(alpha: 0.1), width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: AppConstants.tertiaryBackground,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(2)),
                  ),
                ),
                const SizedBox(width: 6),
                Container(width: 34, height: 3, decoration: BoxDecoration(color: AppConstants.textMutedColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(1.5))),
              ],
            ),
          )),
        );
      case AppListStyle.coverOnlyGrid:
        return GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 0.7,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(12, (index) => Container(
            decoration: BoxDecoration(
              color: AppConstants.secondaryBackground,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: AppConstants.borderColor.withValues(alpha: 0.1), width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Container(color: AppConstants.tertiaryBackground),
            ),
          )),
        );
      case AppListStyle.compactGrid:
        return GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 0.62,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(12, (index) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppConstants.secondaryBackground,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: AppConstants.borderColor.withValues(alpha: 0.1), width: 0.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(color: AppConstants.tertiaryBackground),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Center(child: Container(width: 16, height: 2, decoration: BoxDecoration(color: AppConstants.textMutedColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(1)))),
            ],
          )),
        );
    }
  }

}

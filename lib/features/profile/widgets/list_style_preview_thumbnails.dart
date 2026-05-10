import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/settings/settings_enums.dart';

class ListStylePreviewThumbnails extends StatelessWidget {
  final AppListStyle style;

  const ListStylePreviewThumbnails({super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case AppListStyle.comfortable:
        return _buildComfortable();
      case AppListStyle.compact:
        return _buildCompact();
      case AppListStyle.minimalList:
        return _buildMinimal();
      case AppListStyle.coverOnlyGrid:
        return _buildCoverOnlyGrid();
      case AppListStyle.compactGrid:
        return _buildCompactGrid();
    }
  }

  Widget _buildComfortable() {
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
                  Container(width: 30, height: 3, decoration: BoxDecoration(color: AppConstants.textMutedColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(1.5))),
                  const SizedBox(height: 3),
                  Container(width: 22, height: 2, decoration: BoxDecoration(color: AppConstants.accentColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(1))),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 6, color: AppConstants.textMutedColor.withValues(alpha: 0.2)),
                      const SizedBox(width: 2),
                      Container(width: 8, height: 2, decoration: BoxDecoration(color: AppConstants.textMutedColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(1))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildCompact() {
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
  }

  Widget _buildMinimal() {
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
  }

  Widget _buildCoverOnlyGrid() {
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
  }

  Widget _buildCompactGrid() {
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

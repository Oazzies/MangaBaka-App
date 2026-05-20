import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';

class BrowseTypeTabs extends StatelessWidget {
  final BrowseType selectedType;
  final Function(BrowseType) onTypeChanged;

  const BrowseTypeTabs({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          _buildTab(context, BrowseType.series, l10n.translate('series')),
          _buildTab(
            context,
            BrowseType.publishers,
            l10n.translate('publishers'),
          ),
          _buildTab(context, BrowseType.staff, l10n.translate('staff')),
          _buildTab(
            context,
            BrowseType.characters,
            l10n.translate('characters'),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, BrowseType type, String label) {
    final isSelected = selectedType == type;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onTypeChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppConstants.accentColor.withValues(alpha: 0.12)
                : AppConstants.tertiaryBackground,
            borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppConstants.accentColor
                  : AppConstants.textMutedColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

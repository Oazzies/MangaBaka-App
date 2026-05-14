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
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppConstants.borderColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildTab(context, BrowseType.series, l10n.translate('series')),
          _buildTab(context, BrowseType.publishers, l10n.translate('publishers')),
          _buildTab(context, BrowseType.staff, l10n.translate('staff')),
          _buildTab(context, BrowseType.characters, l10n.translate('characters')),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, BrowseType type, String label) {
    final isSelected = selectedType == type;
    
    return GestureDetector(
      onTap: () => onTypeChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppConstants.accentColor : AppConstants.textMutedColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: 3,
              width: isSelected ? 24 : 0,
              decoration: BoxDecoration(
                color: AppConstants.accentColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.accentColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

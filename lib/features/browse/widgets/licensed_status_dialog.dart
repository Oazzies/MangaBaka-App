import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';

class LicensedStatusDialog {
  static void show({
    required BuildContext context,
    required LocalizationService l10n,
    required SearchFilters currentFilters,
    required ValueChanged<bool?> onStatusSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return Container(
          decoration: BoxDecoration(
            color: AppConstants.secondaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Text(
                l10n.translate('licensed_status'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _SelectionTile(
                label: l10n.translate('any'),
                isSelected: currentFilters.isLicensed == null,
                onTap: () {
                  onStatusSelected(null);
                  Navigator.pop(dialogContext);
                },
              ),
              _SelectionTile(
                label: l10n.translate('yes'),
                isSelected: currentFilters.isLicensed == true,
                onTap: () {
                  onStatusSelected(true);
                  Navigator.pop(dialogContext);
                },
              ),
              _SelectionTile(
                label: l10n.translate('no'),
                isSelected: currentFilters.isLicensed == false,
                onTap: () {
                  onStatusSelected(false);
                  Navigator.pop(dialogContext);
                },
                isLast: true,
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildHeader() {
    return Center(
      child: Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: AppConstants.borderColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLast;

  const _SelectionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: AppConstants.borderColor.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppConstants.textColor : AppConstants.textMutedColor,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppConstants.accentColor : AppConstants.borderColor.withValues(alpha: 0.3),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

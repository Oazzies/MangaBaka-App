import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/browse/models/browse_type.dart';

/// Series / publishers / staff switcher, styled like the library's status
/// tabs: display-caps labels on a row of pills, the selected one filled with
/// the accent.
class BrowseTypeTabs extends StatelessWidget {
  final BrowseType selectedType;
  final Function(BrowseType) onTypeChanged;

  const BrowseTypeTabs({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  static const _tabs = [
    BrowseType.series,
    BrowseType.publishers,
    BrowseType.staff,
    // BrowseType.characters,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();

    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final type in _tabs)
              _Pill(
                label: l10n.translate(type.name),
                selected: selectedType == type,
                onTap: () => onTypeChanged(type),
              ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: selected ? context.colors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: AppTypography.display(
              fontSize: 13,
              color: selected ? context.colors.onAccent : context.colors.text,
            ),
            child: Text(label.toUpperCase()),
          ),
        ),
      ),
    );
  }
}

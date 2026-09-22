import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

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

  Alignment _indicatorAlignment() {
    final index = _tabs.indexOf(selectedType).clamp(0, _tabs.length - 1);
    // Map index 0..n-1 to alignment x -1..1
    final x = _tabs.length > 1 ? (index / (_tabs.length - 1)) * 2 - 1 : 0.0;
    return Alignment(x, 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();

    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / _tabs.length;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          height: 38,
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: context.colors.surfaceRaised, width: 1.5),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                alignment: _indicatorAlignment(),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: tabWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: context.colors.accent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              Row(
                children: _tabs.map((type) {
                  final isSelected = selectedType == type;
                  final label = l10n.translate(type.name);
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTypeChanged(type),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeInOut,
                          style: AppTypography.sans(
                            color: isSelected
                                ? context.colors.background
                                : context.colors.text,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          child: Text(label),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

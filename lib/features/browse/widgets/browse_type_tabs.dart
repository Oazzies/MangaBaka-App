import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/browse/models/browse_type.dart';

class BrowseTypeTabs extends StatelessWidget {
  final BrowseType selectedType;
  final Function(BrowseType) onTypeChanged;

  /// False pins the selection: the other tabs stay visible but take no taps.
  final bool enabled;

  const BrowseTypeTabs({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    this.enabled = true,
  });

  static const _tabs = [
    BrowseType.series,
    BrowseType.publishers,
    BrowseType.staff,
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
                onTap: enabled ? () => onTypeChanged(type) : null,
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
  final VoidCallback? onTap;

  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final idleText = onTap == null
        ? context.colors.textMuted.withValues(alpha: 0.5)
        : context.colors.text;
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
              color: selected ? context.colors.onAccent : idleText,
            ),
            child: Text(label.toUpperCase()),
          ),
        ),
      ),
    );
  }
}

import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

enum TriState { off, include, exclude }

class TriStateChip extends StatelessWidget {
  final String label;
  final TriState state;
  final ValueChanged<TriState> onChanged;

  const TriStateChip({
    super.key,
    required this.label,
    required this.state,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    Color textColor = context.colors.text;
    IconData? icon;

    switch (state) {
      case TriState.include:
        backgroundColor = context.colors.accent.withValues(alpha: 0.2);
        textColor = context.colors.accent;
        icon = Icons.check;
        break;
      case TriState.exclude:
        backgroundColor = context.colors.error.withValues(alpha: 0.2);
        textColor = context.colors.error;
        icon = Icons.close;
        break;
      case TriState.off:
        backgroundColor = context.colors.border.withValues(alpha: 0.25);
        textColor = context.colors.textMuted;
        icon = null;
        break;
    }

    return ActionChip(
      label: Text(label, style: AppTypography.sans(color: textColor)),
      backgroundColor: backgroundColor,
      side: BorderSide.none,
      avatar: icon != null ? Icon(icon, size: 16, color: textColor) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      ),
      onPressed: () {
        if (state == TriState.off) {
          onChanged(TriState.include);
        } else if (state == TriState.include) {
          onChanged(TriState.exclude);
        } else {
          onChanged(TriState.off);
        }
      },
    );
  }
}

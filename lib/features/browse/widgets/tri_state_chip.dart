import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';

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
    Color textColor = AppConstants.textColor;
    IconData? icon;

    switch (state) {
      case TriState.include:
        backgroundColor = AppConstants.accentColor.withValues(alpha: 0.2);
        textColor = AppConstants.accentColor;
        icon = Icons.check;
        break;
      case TriState.exclude:
        backgroundColor = AppConstants.errorColor.withValues(alpha: 0.2);
        textColor = AppConstants.errorColor;
        icon = Icons.close;
        break;
      case TriState.off:
        backgroundColor = AppConstants.borderColor.withValues(alpha: 0.25);
        textColor = AppConstants.textMutedColor;
        icon = null;
        break;
    }

    return ActionChip(
      label: Text(label, style: TextStyle(color: textColor)),
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

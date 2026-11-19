import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class SettingsStepperRow extends StatelessWidget {
  final String label;
  final int value;

  final int min;
  final int max;

  final String? minLabel;

  final ValueChanged<int> onChanged;

  const SettingsStepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.minLabel,
  });

  @override
  Widget build(BuildContext context) {
    final display = (minLabel != null && value == min)
        ? minLabel!
        : value.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.sans(
                color: context.colors.text,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepButton(
                icon: Icons.remove_circle_outline,
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 50),
                alignment: Alignment.center,
                child: Text(
                  display,
                  style: AppTypography.sans(
                    color: context.colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add_circle_outline,
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      color: context.colors.accent,
      disabledColor: context.colors.textMuted.withValues(alpha: 0.3),
    );
  }
}

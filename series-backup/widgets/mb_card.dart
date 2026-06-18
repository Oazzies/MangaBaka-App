import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';

/// Surface card from the MangaBaka design system: warm surface fill, hairline
/// border, soft radius, with an optional uppercase monospace label header and
/// an optional trailing accent widget (e.g. a progress percentage).
class MbCard extends StatelessWidget {
  final String? label;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const MbCard({
    super.key,
    this.label,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppConstants.secondaryBackground,
        border: Border.all(color: AppConstants.borderColor, width: 1),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    label!.toUpperCase(),
                    style: AppTypography.monoLabel(
                      color: AppConstants.textMutedColor,
                      fontSize: 10.5,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Surface card from the MangaBaka design system: flat dark fill, soft radius,
/// with an optional uppercase display label header and an optional trailing
/// accent widget (e.g. a progress percentage).
class MbCard extends StatelessWidget {
  final String? label;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// A tap on the header row. There is no visual cue; it is a shortcut.
  final VoidCallback? onHeaderTap;

  const MbCard({
    super.key,
    this.label,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onHeaderTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onHeaderTap,
              child: Padding(
                // Taller than the text so the shortcut is easy to hit.
                padding: EdgeInsets.only(
                  top: onHeaderTap == null ? 0 : 4,
                  bottom: onHeaderTap == null ? 14 : 18,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label!.toUpperCase(),
                        style: AppTypography.monoLabel(
                          color: context.colors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            ),
          ],
          child,
        ],
      ),
    );
  }
}

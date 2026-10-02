import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/mb_toast.dart';

/// An inline status card above the library list: a solid glyph disc in the
/// status colour, the message, and an optional action or close button. The
/// same visual language as the toasts, but sitting in the page rather than
/// floating over it.
class LibraryStatusBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  final Widget? action;
  final VoidCallback? onClose;

  const LibraryStatusBanner({
    super.key,
    required this.message,
    required this.icon,
    required this.color,
    this.action,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            ToastBadge(
              icon: icon,
              disc: color,
              onDisc: colors.on(color),
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTypography.sans(
                  color: colors.text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
            if (action != null) ...[const SizedBox(width: 8), action!],
            if (onClose != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close, color: colors.textMuted, size: 18),
                onPressed: onClose,
              ),
          ],
        ),
      ),
    );
  }
}

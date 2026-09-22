import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';

/// Centralized SnackBar and Toast presenter.
///
/// On desktop platforms, displays messages as compact floating toasts in the
/// bottom-right corner of the window. On mobile platforms, displays them as
/// floating snackbars.
class AppSnackBar {
  AppSnackBar._();

  /// Displays a message toast or snackbar.
  static void show(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    final c = context.colors;

    final isDesktop = DesktopLayout.isDesktopPlatform;

    if (isDesktop) {
      final screenWidth = MediaQuery.sizeOf(context).width;
      final leftMargin = (screenWidth - 420).clamp(20.0, double.infinity);

      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: c.surface,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: c.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: EdgeInsets.only(
            left: leftMargin,
            right: 28,
            bottom: 28,
          ),
          duration: duration,
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
                color: isError
                    ? c.error
                    : c.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.sans(
                    color: c.text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    action.onPressed();
                    messenger.hideCurrentSnackBar();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor:
                        action.textColor ?? c.accent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    action.label,
                    style: AppTypography.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: c.surface,
          duration: duration,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.denseRadius),
            side: BorderSide(color: c.border),
          ),
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
                color: isError
                    ? c.error
                    : c.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.sans(
                    color: c.text,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
          action: action,
        ),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/widgets/mb_toast.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';

export 'package:mangabaka_app/core/widgets/mb_toast.dart' show ToastKind;

/// Centralized SnackBar and Toast presenter.
///
/// Every message is an [MbToastCard] — a raised card with a tinted glyph badge
/// and, if given, an action pill. On desktop it floats in the bottom-right
/// corner of the window; on a phone it floats full-width above the bottom edge.
class AppSnackBar {
  AppSnackBar._();

  /// Displays a message toast or snackbar.
  ///
  /// [kind] picks the colour and glyph; [isError] is shorthand for
  /// [ToastKind.error]. [detail] adds a quieter second line under [message].
  static void show(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    bool isError = false,
    ToastKind? kind,
    IconData? icon,
    String? detail,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    final resolved = kind ?? (isError ? ToastKind.error : ToastKind.success);
    final isDesktop = DesktopLayout.isDesktopPlatform;

    final card = MbToastCard(
      kind: resolved,
      icon: icon,
      title: message,
      detail: detail,
      radius: isDesktop ? 14 : 16,
      maxWidth: isDesktop ? 420 : null,
      trailing: [
        if (action != null)
          ToastActionPill(
            label: action.label,
            kind: resolved,
            onPressed: () {
              action.onPressed();
              messenger.hideCurrentSnackBar();
            },
          ),
      ],
    );

    final screenWidth = MediaQuery.sizeOf(context).width;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        // The card draws its own surface, border and shadow.
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        duration: duration,
        shape: const RoundedRectangleBorder(),
        margin: isDesktop
            ? EdgeInsets.only(
                left: (screenWidth - 448).clamp(20.0, double.infinity),
                right: 28,
                bottom: 28,
              )
            : const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: isDesktop ? Align(alignment: Alignment.centerRight, child: card) : card,
      ),
    );
  }
}

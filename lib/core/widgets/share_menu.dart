import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_dropdown.dart';

/// Asks whether to share [text] or copy it, and does it.
///
/// In landscape (with an [anchor], the button's rect in global coordinates)
/// the choice is a dropdown under the button; otherwise a bottom sheet.
Future<void> showShareChoice(
  BuildContext context, {
  required String text,
  required String shareLabel,
  required String copyLabel,
  required String copiedMessage,
  Rect? anchor,
}) async {
  final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
  final origin = anchor;

  void share() => SharePlus.instance.share(
    ShareParams(text: text, sharePositionOrigin: origin),
  );
  void copy() {
    Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) AppSnackBar.show(context, copiedMessage);
  }

  if (anchor != null && landscape) {
    showDropdownMenuAt<String>(
      context,
      anchor: anchor,
      items: [
        DesktopDropdownItem(
          value: 'share',
          label: shareLabel,
          icon: Icons.share_rounded,
        ),
        DesktopDropdownItem(
          value: 'copy',
          label: copyLabel,
          icon: Icons.copy_rounded,
        ),
      ],
      onSelected: (choice) => choice == 'share' ? share() : copy(),
    );
    return;
  }

  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (sheet) {
      final c = sheet.colors;
      Widget option(IconData icon, String title, String value) => ListTile(
        onTap: () => Navigator.pop(sheet, value),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: c.accent, size: 24),
        ),
        title: Text(
          title,
          style: AppTypography.sans(
            color: c.text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: c.textMuted.withValues(alpha: 0.5),
        ),
      );
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: c.shadowAt(0.5),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: c.textMuted.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              option(Icons.share_rounded, shareLabel, 'share'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: c.text.withValues(alpha: 0.1),
                ),
              ),
              option(Icons.copy_rounded, copyLabel, 'copy'),
            ],
          ),
        ),
      );
    },
  );
  if (choice == 'share') share();
  if (choice == 'copy') copy();
}

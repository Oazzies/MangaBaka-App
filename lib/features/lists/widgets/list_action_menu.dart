import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_dropdown.dart';

class ListMenuItem<T> {
  final T value;
  final String label;
  final IconData icon;
  final bool destructive;

  const ListMenuItem({
    required this.value,
    required this.label,
    required this.icon,
    this.destructive = false,
  });
}

Rect? globalRectOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// A dropdown at [anchor] where a sheet would open far from the button; a sheet on phones.
Future<void> showListActionMenu<T>(
  BuildContext context, {
  required Rect? anchor,
  required List<ListMenuItem<T>> items,
  required ValueChanged<T> onSelected,
  String? title,
}) async {
  if (anchor != null && prefersDialogSheet(context)) {
    final danger = context.colors.error;
    showDropdownMenuAt<T>(
      context,
      anchor: anchor,
      width: 220,
      items: [
        for (final i in items)
          DesktopDropdownItem(
            value: i.value,
            label: i.label,
            icon: i.icon,
            iconColor: i.destructive ? danger : null,
          ),
      ],
      onSelected: onSelected,
    );
    return;
  }
  final choice = await showAdaptiveSheet<T>(
    context: context,
    backgroundColor: context.colors.surface,
    showDragHandle: true,
    builder: (sheet) {
      final c = sheet.colors;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sans(
                    color: c.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            for (final i in items)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Icon(i.icon, color: i.destructive ? c.error : c.text),
                title: Text(
                  i.label,
                  style: AppTypography.sans(
                    color: i.destructive ? c.error : c.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () => Navigator.of(sheet).pop(i.value),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
  if (choice != null) onSelected(choice);
}

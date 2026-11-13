import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';

/// Bottom sheet offering native share and copy-link actions for a series URL.
void showSeriesShareSheet({
  required BuildContext context,
  required String link,
  required VoidCallback onShare,
  required VoidCallback onCopy,
}) {
  final l10n = LocalizationService();
  showAdaptiveSheet(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (sheetContext) => Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: sheetContext.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: sheetContext.colors.shadowAt(0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdaptiveSheetHandle(
              width: 40,
              color: sheetContext.colors.textMuted.withValues(alpha: 0.2),
              bottomSpacing: 20,
            ),
            _ShareOptionTile(
              icon: Icons.share_rounded,
              title: l10n.translate('share_series'),
              onTap: () {
                Navigator.pop(sheetContext);
                onShare();
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: sheetContext.colors.text.withValues(alpha: 0.1),
              ),
            ),
            _ShareOptionTile(
              icon: Icons.copy_rounded,
              title: l10n.translate('copy_link'),
              onTap: () {
                Navigator.pop(sheetContext);
                onCopy();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.colors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: context.colors.accent, size: 24),
      ),
      title: Text(
        title,
        style: AppTypography.sans(
          color: context.colors.text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: context.colors.textMuted.withValues(alpha: 0.5),
      ),
    );
  }
}

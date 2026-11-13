import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
import 'package:mangabaka_app/features/profile/screens/settings/settings_categories.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/logout_dialog.dart';
import 'package:mangabaka_app/features/series/widgets/delete_from_library_dialog.dart';
import 'package:mangabaka_app/features/series/widgets/progress_update_dialog.dart';
import 'package:mangabaka_app/features/series/widgets/rating_selection_dialog.dart';
import 'package:mangabaka_app/features/series/widgets/unblur_warning.dart';
import 'package:mangabaka_app/features/updates/widgets/update_dialog.dart';

/// Every dialog or sheet Developer Tools can open.
enum DialogPreview {
  update,
  logout,
  deleteFromLibrary,
  unblurCover,
  rating,
  progress,
}

/// Lets the developer pick a [DialogPreview] and opens it with sample content.
/// Purely visual: confirming or changing anything has no effect.
Future<void> showDialogPreviewPicker(BuildContext context) async {
  final l10n = LocalizationService();
  final entries = <DialogPreview, (IconData, String)>{
    DialogPreview.update: (
      Icons.system_update_rounded,
      l10n.translate('dialog_update'),
    ),
    DialogPreview.logout: (
      Icons.logout_rounded,
      l10n.translate('dialog_logout'),
    ),
    DialogPreview.deleteFromLibrary: (
      Icons.delete_sweep_rounded,
      l10n.translate('dialog_delete'),
    ),
    DialogPreview.unblurCover: (
      Icons.blur_off_rounded,
      l10n.translate('dialog_unblur'),
    ),
    DialogPreview.rating: (Icons.star_rounded, l10n.translate('dialog_rating')),
    DialogPreview.progress: (
      Icons.format_list_numbered_rounded,
      l10n.translate('dialog_progress'),
    ),
  };

  final picked = await showDialog<DialogPreview>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      backgroundColor: dialogContext.colors.surface,
      title: Text(
        l10n.translate('preview_dialogs').toUpperCase(),
        style: AppTypography.display(
          color: dialogContext.colors.text,
          fontSize: 18,
        ),
      ),
      children: [
        for (final e in entries.entries)
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(e.key),
            child: Row(
              children: [
                Icon(
                  e.value.$1,
                  size: 20,
                  color: dialogContext.colors.textMuted,
                ),
                const SizedBox(width: 14),
                Text(
                  e.value.$2,
                  style: AppTypography.sans(
                    color: dialogContext.colors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
  if (picked == null || !context.mounted) return;
  await showDialogPreview(context, picked);
}

/// Opens [preview] the way the app would, with nothing wired to real data.
Future<void> showDialogPreview(
  BuildContext context,
  DialogPreview preview,
) async {
  final l10n = LocalizationService();
  switch (preview) {
    case DialogPreview.update:
      await UpdateDialog.show(context, SettingsCategories.debugRelease);
    case DialogPreview.logout:
      await LogoutDialog.showLogoutConfirmationDialog(context);
    case DialogPreview.deleteFromLibrary:
      await showDeleteFromLibraryDialog(context);
    case DialogPreview.unblurCover:
      await confirmUnblur(context);
    case DialogPreview.rating:
      await showAdaptiveSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: RatingSelectionDialog(
            initialRating: 80,
            onRatingChanged: (_) {},
          ),
        ),
      );
    case DialogPreview.progress:
      await showAdaptiveSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ProgressUpdateDialog(
            initialValue: 42,
            title: l10n.translate('update_chapters'),
            maxValue: '120',
            onUpdate: (_) {},
          ),
        ),
      );
  }
}

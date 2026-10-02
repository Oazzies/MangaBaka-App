import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/features/library/widgets/sync_progress_overlay.dart';
import 'package:mangabaka_app/features/profile/screens/settings/settings_categories.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/logout_dialog.dart';
import 'package:mangabaka_app/features/series/widgets/delete_from_library_dialog.dart';
import 'package:mangabaka_app/features/series/widgets/progress_update_dialog.dart';
import 'package:mangabaka_app/features/series/widgets/rating_selection_dialog.dart';
import 'package:mangabaka_app/features/series/widgets/unblur_warning.dart';
import 'package:mangabaka_app/features/updates/widgets/update_dialog.dart';

/// Wraps the logo on the Settings screen: tapping it ten times in quick
/// succession flips developer mode.
///
/// Turning it on shows a snackbar and reveals the Developer Tools category;
/// doing the same while it is on asks first, then hides the category again.
/// The count restarts if the taps slow down, so ordinary tapping never gets
/// there by accident.
class DeveloperModeTapTarget extends StatefulWidget {
  final Widget child;

  /// The time source; tests supply their own, since widget tests do not
  /// advance the real clock.
  final DateTime Function() clock;

  /// Taps needed, and the longest pause between two of them.
  static const int tapsRequired = 10;
  static const Duration maxGap = Duration(milliseconds: 700);

  const DeveloperModeTapTarget({
    super.key,
    required this.child,
    this.clock = DateTime.now,
  });

  @override
  State<DeveloperModeTapTarget> createState() => _DeveloperModeTapTargetState();
}

class _DeveloperModeTapTargetState extends State<DeveloperModeTapTarget> {
  int _taps = 0;
  DateTime? _last;

  Future<void> _onTap() async {
    final now = widget.clock();
    final last = _last;
    _taps = (last != null && now.difference(last) <= DeveloperModeTapTarget.maxGap)
        ? _taps + 1
        : 1;
    _last = now;
    if (_taps < DeveloperModeTapTarget.tapsRequired) return;
    _taps = 0;
    _last = null;

    final settings = SettingsManager();
    final l10n = LocalizationService();
    if (!settings.developerMode) {
      await settings.setDeveloperMode(true);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        l10n.translate('developer_mode_enabled'),
        detail: l10n.translate('developer_mode_enabled_detail'),
        kind: ToastKind.info,
        icon: Icons.code_rounded,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.colors.surface,
        title: Text(
          l10n.translate('developer_mode_deactivate_title'),
          style: AppTypography.display(
            color: dialogContext.colors.text,
            fontSize: 18,
          ),
        ),
        content: Text(
          l10n.translate('developer_mode_deactivate_body'),
          style: AppTypography.sans(color: dialogContext.colors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.translate('developer_mode_deactivate'),
              style: TextStyle(color: dialogContext.colors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await settings.setDeveloperMode(false);
    if (!mounted) return;
    AppSnackBar.show(
      context,
      l10n.translate('developer_mode_disabled'),
      kind: ToastKind.info,
      icon: Icons.code_off_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: widget.child,
    );
  }
}

/// Every snackbar or toast Developer Tools can show.
enum ToastPreview {
  general,
  generalError,
  generalAction,
  syncing,
  syncInterrupted,
}

/// Lets the developer pick a [ToastPreview] and shows it with sample content.
/// Purely visual: nothing is synced, and no action does anything.
Future<void> showToastPreviewPicker(BuildContext context) async {
  final l10n = LocalizationService();
  final labels = {
    ToastPreview.general: l10n.translate('toast_general'),
    ToastPreview.generalError: l10n.translate('toast_general_error'),
    ToastPreview.generalAction: l10n.translate('toast_general_action'),
    ToastPreview.syncing: l10n.translate('toast_syncing'),
    ToastPreview.syncInterrupted: l10n.translate('toast_sync_interrupted'),
  };
  final icons = {
    ToastPreview.general: Icons.check_circle_outline_rounded,
    ToastPreview.generalError: Icons.error_outline_rounded,
    ToastPreview.generalAction: Icons.undo_rounded,
    ToastPreview.syncing: Icons.sync_rounded,
    ToastPreview.syncInterrupted: Icons.sync_problem_rounded,
  };

  final picked = await showDialog<ToastPreview>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      backgroundColor: dialogContext.colors.surface,
      title: Text(
        l10n.translate('preview_toasts').toUpperCase(),
        style: AppTypography.display(
          color: dialogContext.colors.text,
          fontSize: 18,
        ),
      ),
      children: [
        for (final preview in ToastPreview.values)
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(preview),
            child: Row(
              children: [
                Icon(
                  icons[preview],
                  size: 20,
                  color: dialogContext.colors.textMuted,
                ),
                const SizedBox(width: 14),
                Text(
                  labels[preview]!,
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
  showToastPreview(context, picked);
}

/// Shows [preview] the way the app would.
void showToastPreview(BuildContext context, ToastPreview preview) {
  final l10n = LocalizationService();
  switch (preview) {
    case ToastPreview.general:
      AppSnackBar.show(
        context,
        l10n.translate('toast_sample_message'),
        detail: l10n.translate('toast_sample_detail'),
      );
    case ToastPreview.generalError:
      AppSnackBar.show(
        context,
        l10n.translate('toast_sample_message'),
        detail: l10n.translate('toast_sample_detail'),
        isError: true,
      );
    case ToastPreview.generalAction:
      AppSnackBar.show(
        context,
        l10n.translate('toast_sample_message'),
        action: SnackBarAction(
          label: l10n.translate('toast_sample_action'),
          onPressed: () {},
        ),
      );
    case ToastPreview.syncing:
      _showSyncPreview(
        context,
        const LibrarySyncStatus(isSyncing: true, currentEntries: 128),
      );
    case ToastPreview.syncInterrupted:
      _showSyncPreview(
        context,
        const LibrarySyncStatus(
          currentEntries: 128,
          error: 'Connection timed out',
        ),
      );
  }
}

/// Places a sample [SyncStatusCard] where the real sync overlay sits, for a few
/// seconds (or until tapped).
void _showSyncPreview(BuildContext context, LibrarySyncStatus status) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final isDesktop = DesktopLayout.isDesktopPlatform;

  late final OverlayEntry entry;
  Timer? timer;
  void dismiss() {
    timer?.cancel();
    if (entry.mounted) entry.remove();
  }

  entry = OverlayEntry(
    builder: (_) => SafeArea(
      child: Padding(
        padding: isDesktop
            ? const EdgeInsets.fromLTRB(0, 0, 28, 28)
            : const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Align(
          alignment: isDesktop ? Alignment.bottomRight : Alignment.bottomCenter,
          child: Material(
            type: MaterialType.transparency,
            child: SyncStatusCard(
              status: status,
              isDesktop: isDesktop,
              onStop: dismiss,
              onTap: dismiss,
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  timer = Timer(const Duration(seconds: 5), dismiss);
}


/// Every dialog or sheet Developer Tools can open.
enum DialogPreview { update, logout, deleteFromLibrary, unblurCover, rating, progress }

/// Lets the developer pick a [DialogPreview] and opens it with sample content.
/// Purely visual: confirming or changing anything has no effect.
Future<void> showDialogPreviewPicker(BuildContext context) async {
  final l10n = LocalizationService();
  final entries = <DialogPreview, (IconData, String)>{
    DialogPreview.update: (Icons.system_update_rounded, l10n.translate('dialog_update')),
    DialogPreview.logout: (Icons.logout_rounded, l10n.translate('dialog_logout')),
    DialogPreview.deleteFromLibrary: (Icons.delete_sweep_rounded, l10n.translate('dialog_delete')),
    DialogPreview.unblurCover: (Icons.blur_off_rounded, l10n.translate('dialog_unblur')),
    DialogPreview.rating: (Icons.star_rounded, l10n.translate('dialog_rating')),
    DialogPreview.progress: (Icons.format_list_numbered_rounded, l10n.translate('dialog_progress')),
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
                Icon(e.value.$1, size: 20, color: dialogContext.colors.textMuted),
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
Future<void> showDialogPreview(BuildContext context, DialogPreview preview) async {
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
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: RatingSelectionDialog(initialRating: 80, onRatingChanged: (_) {}),
        ),
      );
    case DialogPreview.progress:
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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

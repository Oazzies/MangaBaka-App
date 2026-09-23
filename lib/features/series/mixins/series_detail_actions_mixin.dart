import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/series/widgets/progress_update_dialog.dart';
import 'package:mangabaka_app/features/series/widgets/rating_selection_dialog.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

mixin SeriesDetailActionsMixin<T extends StatefulWidget> on State<T> {
  LibraryService get libraryService;
  Series get series;
  bool get isAdding;
  set isAdding(bool value);

  /// Whether deleting the entry should also pop the enclosing route. A detail
  /// page embedded in another screen (the Discovery Queue) must not.
  bool get popAfterDelete => true;

  void showUpdateRatingDialog(LibraryEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: RatingSelectionDialog(
          initialRating: entry.rating ?? 0,
          onRatingChanged: (rating) async {
            try {
              await libraryService.updateLibraryEntryRating(series.id, rating);
            } catch (e) {
              if (mounted) {
                AppSnackBar.show(
                  this.context,
                  LocalizationService().translate('failed_to_update'),
                  isError: true,
                );
              }
            }
          },
        ),
      ),
    );
  }

  void showUpdateProgressDialog(LibraryEntry entry, {bool isChapter = true}) {
    final l10n = LocalizationService();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ProgressUpdateDialog(
          initialValue:
              (isChapter ? entry.progressChapter : entry.progressVolume) ?? 0,
          title: isChapter
              ? l10n.translate('update_chapters')
              : l10n.translate('update_volumes'),
          maxValue: isChapter ? series.totalChapters : series.finalVolume,
          onUpdate: (value) {
            if (isChapter) {
              libraryService.updateLibraryEntryProgress(
                series.id,
                progressChapter: value,
              );
            } else {
              libraryService.updateLibraryEntryProgress(
                series.id,
                progressVolume: value,
              );
            }
          },
        ),
      ),
    );
  }

  void shareLink() {
    final l10n = LocalizationService();
    final String? link = series.links
        .whereType<String>()
        .where((l) => l.contains('mangabaka'))
        .firstOrNull;

    if (link != null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        elevation: 0,
        builder: (context) => Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: context.colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: context.colors.shadowAt(0.5),
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
                    color: context.colors.textMuted.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _buildShareOption(
                  icon: Icons.share_rounded,
                  title: l10n.translate('share_series'),
                  onTap: () {
                    Navigator.pop(context);
                    final box = this.context.findRenderObject() as RenderBox?;
                    SharePlus.instance.share(
                      ShareParams(
                        text: link,
                        sharePositionOrigin: box != null
                            ? box.localToGlobal(Offset.zero) & box.size
                            : null,
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: context.colors.text.withValues(alpha: 0.1),
                  ),
                ),
                _buildShareOption(
                  icon: Icons.copy_rounded,
                  title: l10n.translate('copy_link'),
                  onTap: () {
                    Navigator.pop(context);
                    copyToClipboard(link);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      AppSnackBar.show(context, l10n.translate('no_sharing_link'));
    }
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
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

  void showDeleteConfirmationDialog() {
    final l10n = LocalizationService();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.largeRadius),
          side: BorderSide(color: context.colors.surfaceRaised, width: 1.5),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_sweep_rounded,
                color: context.colors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.translate('delete_from_library').toUpperCase(),
                style: AppTypography.display(
                  color: context.colors.text,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.translate('delete_confirmation'),
          style: AppTypography.sans(
            color: context.colors.textMuted,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              l10n.translate('cancel'),
              style: AppTypography.sans(
                color: context.colors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await libraryService.deleteEntry(series.id);
                if (mounted && popAfterDelete) Navigator.pop(this.context);
              } catch (e) {
                if (mounted) {
                  AppSnackBar.show(
                    this.context,
                    LocalizationService().translate('failed_to_delete'),
                    isError: true,
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.on(context.colors.error),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
              ),
            ),
            child: Text(
              l10n.translate('confirm'),
              style: AppTypography.sans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    AppSnackBar.show(
      context,
      LocalizationService()
          .translate('copied_to_clipboard')
          .replaceAll('{text}', text),
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> addSeriesToLibrary() async {
    if (isAdding) return;
    setState(() => isAdding = true);
    try {
      await libraryService.createLibraryEntry(
        series.id,
        SettingsManager().addLibraryDefaultTab,
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          LocalizationService().translate('failed_to_add'),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => isAdding = false);
    }
  }
}

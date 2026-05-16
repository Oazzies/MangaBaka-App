import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/features/series/widgets/progress_update_dialog.dart';
import 'package:mangabaka_app/features/series/widgets/rating_selection_dialog.dart';

mixin SeriesDetailActionsMixin<T extends StatefulWidget> on State<T> {
  LibraryService get libraryService;
  Series get series;
  bool get isAdding;
  set isAdding(bool value);

  void showUpdateRatingDialog(LibraryEntry entry) {
    showDialog(
      context: context,
      builder: (context) => RatingSelectionDialog(
        initialRating: entry.rating ?? 0,
        onRatingChanged: (rating) {
          libraryService.updateLibraryEntryRating(series.id, rating);
        },
      ),
    );
  }

  void showUpdateProgressDialog(LibraryEntry entry, {bool isChapter = true}) {
    final l10n = LocalizationService();
    showDialog(
      context: context,
      builder: (context) => ProgressUpdateDialog(
        initialValue: (isChapter ? entry.progressChapter : entry.progressVolume) ?? 0,
        title: isChapter ? l10n.translate('update_chapters') : l10n.translate('update_volumes'),
        maxValue: isChapter ? series.totalChapters : series.finalVolume,
        onUpdate: (value) {
          if (isChapter) {
            libraryService.updateLibraryEntryProgress(series.id, progressChapter: value);
          } else {
            libraryService.updateLibraryEntryProgress(series.id, progressVolume: value);
          }
        },
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
            color: AppConstants.primaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
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
                    color: AppConstants.textMutedColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _buildShareOption(
                  icon: Icons.share_rounded,
                  title: l10n.translate('share_series'),
                  onTap: () {
                    Navigator.pop(context);
                    final box = this.context.findRenderObject() as RenderBox?;
                    SharePlus.instance.share(ShareParams(
                      text: link,
                      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
                    ));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(height: 1, thickness: 0.5, color: AppConstants.textColor.withValues(alpha: 0.1)),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.translate('no_sharing_link'))));
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
          color: AppConstants.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppConstants.accentColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppConstants.textMutedColor.withValues(alpha: 0.5),
      ),
    );
  }

  void showDeleteConfirmationDialog() {
    final l10n = LocalizationService();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.tertiaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.translate('delete_from_library'), style: TextStyle(color: AppConstants.textColor, fontWeight: FontWeight.bold)),
        content: Text(l10n.translate('delete_confirmation'), style: TextStyle(color: AppConstants.textMutedColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.translate('cancel'), style: TextStyle(color: AppConstants.textColor))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await libraryService.deleteEntry(series.id);
              if (mounted) Navigator.pop(this.context);
            },
            child: Text(l10n.translate('confirm'), style: TextStyle(color: AppConstants.errorColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(LocalizationService().translate('copied_to_clipboard').replaceAll('{text}', text)),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> addSeriesToLibrary() async {
    if (isAdding) return;
    setState(() => isAdding = true);
    try {
      await libraryService.createLibraryEntry(series.id, SettingsManager().addLibraryDefaultTab);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService().translate('failed_to_add'))),
        );
      }
    } finally {
      if (mounted) setState(() => isAdding = false);
    }
  }
}

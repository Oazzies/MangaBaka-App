import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/series/widgets/complete_series_dialog.dart';
import 'package:mangabaka_app/features/series/widgets/delete_from_library_dialog.dart';
import 'package:mangabaka_app/features/series/widgets/note_editor_dialog.dart';
import 'package:mangabaka_app/features/series/widgets/progress_update_dialog.dart';
import 'package:mangabaka_app/features/series/widgets/rating_selection_dialog.dart';
import 'package:mangabaka_app/features/series/widgets/series_share_sheet.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_dropdown.dart';

mixin SeriesDetailActionsMixin<T extends StatefulWidget> on State<T> {
  LibraryService get libraryService;
  Series get series;
  bool get isAdding;
  set isAdding(bool value);

  /// Whether deleting the entry should also pop the enclosing route. A detail
  /// page embedded in another screen (the Discovery Queue) must not.
  bool get popAfterDelete => true;

  void showUpdateRatingDialog(LibraryEntry entry) {
    showAdaptiveSheet(
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

  void showUpdateNoteDialog(LibraryEntry entry) {
    showAdaptiveSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => NoteEditorDialog(
        initialNote: entry.note,
        onSave: (note) async {
          try {
            await libraryService.updateLibraryEntryNote(series.id, note);
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
    );
  }

  void showUpdateProgressDialog(LibraryEntry entry, {bool isChapter = true}) {
    final l10n = LocalizationService();
    showAdaptiveSheet(
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
          isChapter: isChapter,
          seriesStatus: series.status,
          onUpdate: (value) async {
            // Not fire-and-forget: a failed request (already rolled back
            // locally) would otherwise surface only as an unhandled async
            // error, with the user told nothing.
            try {
              await libraryService.updateLibraryEntryProgress(
                series.id,
                progressChapter: isChapter ? value : null,
                progressVolume: isChapter ? null : value,
              );
              if (mounted) {
                await maybePromptCompleteSeries(
                  this.context,
                  series: series,
                  entry: entry,
                  libraryService: libraryService,
                  previousChapter: isChapter ? entry.progressChapter ?? 0 : null,
                  updatedChapter: isChapter ? value : null,
                  previousVolume: isChapter ? null : entry.progressVolume ?? 0,
                  updatedVolume: isChapter ? null : value,
                );
              }
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

  void _shareText(String link) {
    final box = context.findRenderObject() as RenderBox?;
    SharePlus.instance.share(
      ShareParams(
        text: link,
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      ),
    );
  }

  /// Share / copy-link choices as a dropdown hanging off the button at
  /// [anchor], used in landscape where a bottom sheet is a long way from it.
  void _showShareMenu(String link, Rect anchor) {
    final l10n = LocalizationService();
    showDropdownMenuAt<String>(
      context,
      anchor: anchor,
      items: [
        DesktopDropdownItem(
          value: 'share',
          label: l10n.translate('share_series'),
          icon: Icons.share_rounded,
        ),
        DesktopDropdownItem(
          value: 'copy',
          label: l10n.translate('copy_link'),
          icon: Icons.copy_rounded,
        ),
      ],
      onSelected: (choice) {
        if (!mounted) return;
        if (choice == 'share') {
          _shareText(link);
        } else {
          copyToClipboard(link);
        }
      },
    );
  }

  void shareLink({Rect? anchor}) {
    final l10n = LocalizationService();
    final String? link = series.links
        .whereType<String>()
        .where((l) => l.contains('mangabaka'))
        .firstOrNull;

    if (link != null &&
        anchor != null &&
        MediaQuery.orientationOf(context) == Orientation.landscape) {
      _showShareMenu(link, anchor);
    } else if (link != null) {
      showSeriesShareSheet(
        context: context,
        link: link,
        onShare: () => _shareText(link),
        onCopy: () => copyToClipboard(link),
      );
    } else {
      AppSnackBar.show(context, l10n.translate('no_sharing_link'));
    }
  }

  Future<void> showDeleteConfirmationDialog() async {
    final confirmed = await showDeleteFromLibraryDialog(context);
    if (confirmed != true) return;
    try {
      await libraryService.deleteEntry(series.id);
      if (mounted && popAfterDelete) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          LocalizationService().translate('failed_to_delete'),
          isError: true,
        );
      }
    }
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

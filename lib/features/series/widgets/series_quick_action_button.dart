import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class SeriesQuickActionButton extends StatefulWidget {
  final Series series;
  final LibraryEntry? entry;
  final ValueChanged<int?>? onOptimisticProgressChanged;

  const SeriesQuickActionButton({
    super.key,
    required this.series,
    this.entry,
    this.onOptimisticProgressChanged,
  });

  @override
  State<SeriesQuickActionButton> createState() =>
      _SeriesQuickActionButtonState();
}

class _SeriesQuickActionButtonState extends State<SeriesQuickActionButton> {
  int? _optimisticProgress;

  @override
  void didUpdateWidget(covariant SeriesQuickActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry?.progressChapter != widget.entry?.progressChapter) {
      _optimisticProgress = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show for series already in the library
    if (widget.entry == null) return const SizedBox.shrink();

    final totalChapters = int.tryParse(widget.series.totalChapters) ?? 0;
    final currentProgress =
        _optimisticProgress ?? widget.entry?.progressChapter ?? 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Gives way to the button in a narrow cell or at a large text size.
        Flexible(
          child: Text(
            '$currentProgress${totalChapters > 0 ? ' / $totalChapters' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sans(
              color: context.colors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        WidgetUtils.tooltip(
          message: LocalizationService().translate('update_progress'),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handlePress(widget.entry!),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 38,
                width: 48,
                decoration: BoxDecoration(
                  color: context.colors.accent,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '+1',
                    style: AppTypography.sans(
                      color: context.colors.background,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePress(LibraryEntry entry) async {
    final libraryService = getIt<LibraryService>();

    final currentProgress = _optimisticProgress ?? entry.progressChapter ?? 0;
    final newProgress = currentProgress + 1;

    setState(() {
      _optimisticProgress = newProgress;
    });
    widget.onOptimisticProgressChanged?.call(newProgress);

    try {
      await libraryService.updateLibraryEntryProgress(
        widget.series.id,
        progressChapter: newProgress,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _optimisticProgress = null;
        });
        widget.onOptimisticProgressChanged?.call(null);
        AppSnackBar.show(
          context,
          LocalizationService().translate('an_error_occurred'),
          isError: true,
        );
      }
    }
  }
}

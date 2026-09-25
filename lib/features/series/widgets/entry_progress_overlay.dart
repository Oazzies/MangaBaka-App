import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/fixed_colors.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/progress_update_dialog.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The badges laid over a grid cover: how far the reader has got, and how much
/// is left.
///
/// Renders nothing unless the series is in the library and at least one of the
/// two settings is on. The progress badge is tappable and opens the update
/// sheet; the remaining count is informational.
class EntryProgressOverlay extends StatelessWidget {
  final Series series;
  final LibraryEntry? entry;

  /// Whether the cell is too narrow for the two badges side by side (under
  /// [combineBelowWidth]), so they merge into one pill.
  final bool combineBadges;

  /// Progress to display instead of the entry's own — used while an optimistic
  /// update is in flight.
  final int? progressOverride;

  final SettingsManager settings;
  final LocalizationService l10n;

  /// Below this cell width the two badges would collide.
  static const double combineBelowWidth = 145;

  const EntryProgressOverlay({
    super.key,
    required this.series,
    required this.entry,
    required this.combineBadges,
    required this.progressOverride,
    required this.settings,
    required this.l10n,
  });

  /// Solid dark pill with a subtle drop shadow. Const, so it is not
  /// reallocated on every rebuild of every cell in a grid.
  static const BoxDecoration _badge = BoxDecoration(
    color: FixedColors.imageBadge,
    borderRadius: BorderRadius.all(Radius.circular(20)),
    boxShadow: [
      BoxShadow(color: FixedColors.imageBadgeShadow, blurRadius: 4, offset: Offset(0, 2)),
    ],
  );

  static const EdgeInsets _badgePadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 4,
  );

  static final BorderRadius _badgeRadius = BorderRadius.circular(20);

  bool get _isChapter =>
      settings.libraryProgressType == LibraryProgressType.chapters;

  int get _total {
    final raw = _isChapter ? series.totalChapters : series.finalVolume;
    return int.tryParse(raw) ?? 0;
  }

  int get _progress {
    if (progressOverride != null) return progressOverride!;
    final value = _isChapter ? entry?.progressChapter : entry?.progressVolume;
    return value ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox.shrink();

    final total = _total;
    final remaining = total > 0 ? total - _progress : 0;

    final showProgress = settings.showLibraryProgress;
    // Nothing useful to say about what is left when the total is unknown, or
    // when there is none left.
    final showRemaining =
        settings.showRemainingProgress && total > 0 && remaining > 0;

    if (!showProgress && !showRemaining) return const SizedBox.shrink();

    if (showProgress && showRemaining && combineBadges) {
      return _combined(context, remaining: remaining, total: total);
    }
    return _separate(
      context,
      showProgress: showProgress,
      showRemaining: showRemaining,
      remaining: remaining,
      total: total,
    );
  }

  /// One pill spanning the cell, remaining and progress divided by a hairline.
  Widget _combined(
    BuildContext context, {
    required int remaining,
    required int total,
  }) {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: _tappable(
        context,
        child: Container(
          padding: _badgePadding,
          decoration: _badge,
          // Scales down rather than overflowing on a very narrow cell.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _remainingText(context, remaining),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: 1,
                    height: 10,
                    color: FixedColors.onImage.withValues(alpha: 0.3),
                  ),
                ),
                _progressText(total),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Remaining on the left, progress on the right.
  Widget _separate(
    BuildContext context, {
    required bool showProgress,
    required bool showRemaining,
    required int remaining,
    required int total,
  }) {
    return Stack(
      children: [
        if (showRemaining)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: _badgePadding,
              decoration: _badge,
              child: _remainingText(context, remaining),
            ),
          ),
        if (showProgress)
          Positioned(
            top: 8,
            right: 8,
            child: _tappable(
              context,
              child: Container(
                padding: _badgePadding,
                decoration: _badge,
                child: _progressText(total),
              ),
            ),
          ),
      ],
    );
  }

  Widget _tappable(BuildContext context, {required Widget child}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openUpdateDialog(context),
        borderRadius: _badgeRadius,
        child: child,
      ),
    );
  }

  Widget _progressText(int total) {
    final prefix = _isChapter ? 'Ch. ' : 'Vol. ';
    return Text(
      '$prefix$_progress${total > 0 ? '/$total' : ''}',
      style: AppTypography.sans(
        color: FixedColors.onImage,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
    );
  }

  Widget _remainingText(BuildContext context, int remaining) {
    return Text(
      '$remaining',
      style: AppTypography.sans(
        color: context.colors.warning,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
    );
  }

  void _openUpdateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        // Lifts the sheet above the keyboard when the field is focused.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: ProgressUpdateDialog(
          initialValue: _progress,
          title: l10n.translate(
            _isChapter ? 'update_chapters' : 'update_volumes',
          ),
          maxValue: _isChapter ? series.totalChapters : series.finalVolume,
          onUpdate: (value) {
            final library = getIt<LibraryService>();
            if (_isChapter) {
              library.updateLibraryEntryProgress(
                series.id,
                progressChapter: value,
              );
            } else {
              library.updateLibraryEntryProgress(
                series.id,
                progressVolume: value,
              );
            }
          },
        ),
      ),
    );
  }
}

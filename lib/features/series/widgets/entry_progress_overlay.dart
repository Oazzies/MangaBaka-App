import 'package:mangabaka_app/core/widgets/adaptive_form.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/fixed_colors.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/complete_series_dialog.dart';
import 'package:mangabaka_app/features/series/widgets/progress_update_dialog.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class EntryProgressOverlay extends StatelessWidget {
  final Series series;
  final LibraryEntry? entry;

  final bool combineBadges;

  /// Shown while an optimistic update is in flight.
  final int? progressOverride;

  final SettingsManager settings;
  final LocalizationService l10n;
  final LibraryService library;

  static const double combineBelowWidth = 145;

  const EntryProgressOverlay({
    super.key,
    required this.series,
    required this.entry,
    required this.combineBadges,
    required this.progressOverride,
    required this.settings,
    required this.l10n,
    required this.library,
  });

  static const BoxDecoration _badge = BoxDecoration(
    color: FixedColors.imageBadge,
    borderRadius: BorderRadius.all(Radius.circular(20)),
    boxShadow: [
      BoxShadow(
        color: FixedColors.imageBadgeShadow,
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
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
    final prefix = l10n.translate(_isChapter ? 'abbr_chapter' : 'abbr_volume');
    return Text(
      '$prefix $_progress${total > 0 ? '/$total' : ''}',
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
    final title = l10n.translate(
      _isChapter ? 'update_chapters' : 'update_volumes',
    );
    showAdaptiveForm(
      context: context,
      title: title,
      builder: (_) => ProgressUpdateDialog(
        initialValue: _progress,
        title: title,
        maxValue: _isChapter ? series.totalChapters : series.finalVolume,
        isChapter: _isChapter,
        seriesStatus: series.status,
        onUpdate: (value) async {
          final currentEntry = entry;
          try {
            if (_isChapter) {
              await library.updateLibraryEntryProgress(
                series.id,
                progressChapter: value,
              );
            } else {
              await library.updateLibraryEntryProgress(
                series.id,
                progressVolume: value,
              );
            }
            if (currentEntry != null && context.mounted) {
              await maybePromptCompleteSeries(
                context,
                series: series,
                entry: currentEntry,
                libraryService: library,
                previousChapter: _isChapter ? _progress : null,
                updatedChapter: _isChapter ? value : null,
                previousVolume: _isChapter ? null : _progress,
                updatedVolume: _isChapter ? null : value,
              );
            }
          } catch (e) {
            if (context.mounted) {
              AppSnackBar.show(
                context,
                l10n.translate('failed_to_update'),
                isError: true,
              );
            }
          }
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/state_selection_section.dart';
import 'package:mangabaka_app/features/series/widgets/rating_icon_button.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';

class SeriesActionBar extends StatelessWidget {
  final Series series;
  final LibraryEntry? entry;
  final Function(String) onStateChanged;
  final Function(int) onRatingChanged;
  final VoidCallback onUpdateChapter;
  final VoidCallback onUpdateVolume;
  final LocalizationService l10n;

  const SeriesActionBar({
    super.key,
    required this.series,
    this.entry,
    required this.onStateChanged,
    required this.onRatingChanged,
    required this.onUpdateChapter,
    required this.onUpdateVolume,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox.shrink();

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final hasChapters = series.totalChapters.isNotEmpty && series.totalChapters != 'null';
    final hasVolumes = series.finalVolume.isNotEmpty && series.finalVolume != 'null';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StateSelectionSection(
                currentState: entry!.state,
                onStateChanged: onStateChanged,
              ),
            ),
            if (isLandscape) ...[
              const SizedBox(width: 12),
              RatingIconButton(
                currentRating: entry!.rating,
                onRatingChanged: onRatingChanged,
              ),
            ],
          ],
        ),
        if (isLandscape && (hasChapters || hasVolumes)) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (hasChapters)
                Expanded(
                  child: _ProgressButton(
                    icon: Icons.menu_book_outlined,
                    label: l10n.translate('chapters'),
                    value: entry!.progressChapter ?? 0,
                    total: series.totalChapters,
                    onTap: onUpdateChapter,
                  ),
                ),
              if (hasChapters && hasVolumes) const SizedBox(width: 12),
              if (hasVolumes)
                Expanded(
                  child: _ProgressButton(
                    icon: Icons.shelves,
                    label: l10n.translate('volumes'),
                    value: entry!.progressVolume ?? 0,
                    total: series.finalVolume,
                    onTap: onUpdateVolume,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

}

class _ProgressButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final String? total;
  final VoidCallback onTap;

  const _ProgressButton({
    required this.icon,
    required this.label,
    required this.value,
    this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayTotal = (total == null || total == 'null' || total!.isEmpty) ? '?' : total;

    return Material(
      color: AppConstants.secondaryBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppConstants.accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$value / $displayTotal',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.add,
                size: 20,
                color: AppConstants.textMutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}



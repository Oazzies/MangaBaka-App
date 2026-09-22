import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/desktop/widgets/series_hover_preview.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class ReferencedListItem extends StatelessWidget {
  final Series series;
  final bool compact;

  const ReferencedListItem({
    super.key,
    required this.series,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final settings = SettingsManager();
    final displayTitle = series.getDisplayTitle(settings.defaultTitleLanguage);

    return SeriesHoverPreview(
      series: series,
      child: GestureDetector(
        onTap: () {
          SeriesHoverPreviewController.instance.hide();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SeriesDetailScreen(series: series),
            ),
          );
        },
        child: SizedBox(
          width: compact ? 90 : 120,
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 2 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.denseRadius),
                  child: WidgetUtils.networkImage(
                    url: series.coverUrl,
                    blurred: WidgetUtils.isRatingBlurred(series.contentRating),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    memCacheWidth: 240,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                displayTitle,
                style: AppTypography.sans(
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textMuted,
                  letterSpacing: 0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

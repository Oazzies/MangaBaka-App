import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_cover.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

class SeriesPickRow extends StatelessWidget {
  final Series series;
  final String meta;
  final Color? metaColor;
  final Widget trailing;
  final VoidCallback? onTap;

  const SeriesPickRow({
    super.key,
    required this.series,
    required this.meta,
    required this.trailing,
    required this.onTap,
    this.metaColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: MbCover(
        url: series.coverUrl,
        width: 36,
        radius: 6,
        memCacheWidth: 96,
        blurred: WidgetUtils.isRatingBlurred(series.contentRating),
      ),
      title: Text(
        series.getDisplayTitle(SettingsManager().defaultTitleLanguage),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.sans(
          color: c.text,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: meta.isEmpty
          ? null
          : Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sans(
                color: metaColor ?? c.textMuted,
                fontSize: 12.5,
              ),
            ),
      trailing: SizedBox(width: 24, height: 24, child: Center(child: trailing)),
    );
  }
}

class PickMark extends StatelessWidget {
  final bool on;
  final bool busy;
  final IconData offIcon;

  const PickMark({
    super.key,
    required this.on,
    required this.offIcon,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (busy) return const MbSpinner(size: 20, strokeWidth: 2);
    return Icon(
      on ? Icons.check_circle_rounded : offIcon,
      color: on ? c.accent : c.textMuted,
    );
  }
}

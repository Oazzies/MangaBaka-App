import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/staff/models/staff.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class StaffListItem extends StatelessWidget {
  final Staff staff;
  final VoidCallback? onTap;

  /// Space around the card. The default suits a vertical list; a grid supplies
  /// its own spacing and passes [EdgeInsets.zero].
  final EdgeInsetsGeometry? margin;

  const StaffListItem({
    super.key,
    required this.staff,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: context.colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        // A person with no photo gets no stand-in glyph: a grey tile with a
        // silhouette says nothing and costs the name its room.
        leading: staff.image == null
            ? null
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: WidgetUtils.networkImage(
                    url: staff.image!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
        title: Text(
          staff.name,
          style: AppTypography.sans(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (staff.nativeName != null)
              Text(
                staff.nativeName!,
                style: AppTypography.sans(
                  color: context.colors.textMuted,
                  fontSize: 14,
                ),
              ),
            if (staff.role != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  staff.role!,
                  style: AppTypography.sans(
                    color: context.colors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        trailing: staff.seriesCount != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    staff.seriesCount.toString(),
                    style: AppTypography.sans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    LocalizationService().translate('series'),
                    style: AppTypography.sans(
                      color: context.colors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}

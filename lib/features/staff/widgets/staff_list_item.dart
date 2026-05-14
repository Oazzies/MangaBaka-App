import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/staff/models/staff.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';

class StaffListItem extends StatelessWidget {
  final Staff staff;
  final VoidCallback? onTap;

  const StaffListItem({
    super.key,
    required this.staff,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppConstants.secondaryBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 50,
            height: 50,
            child: staff.image != null
                ? WidgetUtils.networkImage(
                    url: staff.image!,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: AppConstants.tertiaryBackground,
                    child: Icon(
                      Icons.person,
                      color: AppConstants.textMutedColor,
                    ),
                  ),
          ),
        ),
        title: Text(
          staff.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (staff.nativeName != null)
              Text(
                staff.nativeName!,
                style: TextStyle(
                  color: AppConstants.textMutedColor,
                  fontSize: 14,
                ),
              ),
            if (staff.role != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  staff.role!,
                  style: TextStyle(
                    color: AppConstants.accentColor,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Series',
                    style: TextStyle(
                      color: AppConstants.textMutedColor,
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

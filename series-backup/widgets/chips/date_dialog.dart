import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/utils/date_utils.dart' as mb_date;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';

class DateDialog extends StatelessWidget {
  final String start;
  final String end;
  const DateDialog({required this.start, required this.end, super.key});

  @override
  Widget build(BuildContext context) {
    final startFormatted = mb_date.AppDateUtils.formatFullDate(start);
    final endFormatted = mb_date.AppDateUtils.formatFullDate(end);
    final l10n = LocalizationService();

    return AlertDialog(
      backgroundColor: AppConstants.secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        side: BorderSide(
          color: AppConstants.borderColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: AppConstants.accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.translate('publication_dates'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.primaryBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppConstants.borderColor.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                if (startFormatted.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 70,
                        child: Text(
                          '${l10n.translate('start')}:',
                          style: TextStyle(
                            color: AppConstants.textMutedColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          startFormatted,
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (startFormatted.isNotEmpty && endFormatted.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: AppConstants.borderColor.withValues(alpha: 0.1),
                    ),
                  ),
                if (endFormatted.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 70,
                        child: Text(
                          '${l10n.translate('end')}:',
                          style: TextStyle(
                            color: AppConstants.textMutedColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          endFormatted,
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
              ),
              elevation: 0,
            ),
            child: Text(
              l10n.translate('close'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:bakahyou/utils/date_utils.dart' as mb_date;
import 'package:bakahyou/utils/constants/app_constants.dart';

class DateDialog extends StatelessWidget {
  final String start;
  final String end;
  const DateDialog({required this.start, required this.end, super.key});

  @override
  Widget build(BuildContext context) {
    final startFormatted = mb_date.AppDateUtils.formatFullDate(start);
    final endFormatted = mb_date.AppDateUtils.formatFullDate(end);

    return AlertDialog(
      backgroundColor: AppConstants.tertiaryBackground,
      title: Text(
        'Publication Dates',
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (startFormatted.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    'Start:',
                    style: TextStyle(
                      color: AppConstants.textMutedColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 17,
                    ),
                  ),
                ),
                Text(
                  startFormatted,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontWeight: FontWeight.w400,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          if (endFormatted.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      'End:',
                      style: TextStyle(
                        color: AppConstants.textMutedColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Text(
                    endFormatted,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontWeight: FontWeight.w400,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

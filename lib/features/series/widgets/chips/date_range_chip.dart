import 'package:flutter/material.dart';
import 'package:bakahyou/utils/date_utils.dart' as mb_date;
import 'package:bakahyou/features/series/widgets/chip.dart';
import 'date_dialog.dart';

class DateRangeChip extends StatelessWidget {
  final String start;
  final String end;
  const DateRangeChip({required this.start, required this.end, super.key});

  void _showDateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => DateDialog(start: start, end: end),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startYear = mb_date.DateUtils.extractYear(start);
    final endYear = mb_date.DateUtils.extractYear(end);

    if (startYear.isEmpty && endYear.isEmpty) return SizedBox.shrink();

    String text;
    if (startYear.isNotEmpty && endYear.isNotEmpty) {
      text = startYear == endYear ? startYear : '$startYear - $endYear';
    } else if (startYear.isNotEmpty) {
      text = startYear;
    } else {
      text = endYear;
    }
    return GestureDetector(
      onTap: () => _showDateDialog(context),
      child: ChipBase(label: Text(text)),
    );
  }
}
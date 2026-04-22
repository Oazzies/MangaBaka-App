import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class IdChip extends StatelessWidget {
  final String id;
  const IdChip({required this.id, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: id));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppConstants.textMutedColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'ID: $id',
          style: TextStyle(
            fontSize: 11,
            color: AppConstants.textMutedColor,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

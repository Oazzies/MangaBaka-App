import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class SeriesSectionHeader extends StatelessWidget {
  final String title;
  final double bottomPadding;

  const SeriesSectionHeader({
    super.key,
    required this.title,
    this.bottomPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppConstants.textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

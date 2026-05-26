import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';

class SeriesSectionHeader extends StatelessWidget {
  final String title;
  final double bottomPadding;

  const SeriesSectionHeader({
    super.key,
    required this.title,
    this.bottomPadding = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppConstants.textMutedColor,
          letterSpacing: 1.0,
          height: 1.2,
        ),
      ),
    );
  }
}

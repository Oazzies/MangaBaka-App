import 'package:bakahyou/features/series/widgets/rating_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class RatingIconButton extends StatelessWidget {
  final int? currentRating;
  final Function(int) onRatingChanged;

  const RatingIconButton({
    super.key,
    required this.currentRating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rating = currentRating ?? 0;
    final hasRating = rating > 0;

    return Container(
      height: 38,
      width: 50,
      decoration: BoxDecoration(
        color: AppConstants.primaryBackground,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppConstants.borderColor, width: 1.5),
      ),
      child: IconButton(
        icon: Icon(
          hasRating ? Icons.star : Icons.star_border,
          color: hasRating ? AppConstants.warningColor : AppConstants.textColor,
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => RatingSelectionDialog(
              initialRating: rating,
              onRatingChanged: onRatingChanged,
            ),
          );
        },
      ),
    );
  }
}

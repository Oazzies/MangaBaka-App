import 'package:mangabaka_app/features/series/widgets/rating_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';

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
      height: 44,
      width: 54,
      decoration: BoxDecoration(
        color: AppConstants.secondaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: IconButton(
        icon: Icon(
          hasRating ? Icons.star : Icons.star_border,
          color: hasRating ? AppConstants.warningColor : AppConstants.textColor,
          size: 24,
        ),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (ctx) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: RatingSelectionDialog(
                initialRating: rating,
                onRatingChanged: onRatingChanged,
              ),
            ),
          );
        },
      ),
    );
  }
}

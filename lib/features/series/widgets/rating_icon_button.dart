import 'package:bakahyou/features/series/widgets/rating_selection_dialog.dart';
import 'package:flutter/material.dart';

class RatingIconButton extends StatelessWidget {
  final int? currentRating;
  final Function(int) onRatingChanged;

  const RatingIconButton({
    Key? key,
    required this.currentRating,
    required this.onRatingChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rating = currentRating ?? 0;
    final hasRating = rating > 0;

    return Container(
      height: 38,
      width: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF0a0a0a),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0xFF3f3f46), width: 1.5),
      ),
      child: IconButton(
        icon: Icon(
          hasRating ? Icons.star : Icons.star_border,
          color: hasRating ? Colors.amber : Colors.white,
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
import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/utils/settings/settings_enums.dart';


class RatingSelectionDialog extends StatefulWidget {
  final int initialRating;
  final Function(int) onRatingChanged;

  const RatingSelectionDialog({
    super.key,
    required this.initialRating,
    required this.onRatingChanged,
  });

  @override
  State<RatingSelectionDialog> createState() => _RatingSelectionDialogState();
}

class _RatingSelectionDialogState extends State<RatingSelectionDialog> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppConstants.tertiaryBackground,
      title: Text(
        'Set Your Rating',
        style: TextStyle(color: AppConstants.textColor, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentRating.toInt() == 0
                ? 'Unrated'
                : _currentRating.toInt().toString(),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            value: _currentRating,
            min: 0,
            max: 100,
            divisions: _getDivisions(),
            label: _currentRating.round().toString(),
            onChanged: (double value) {
              setState(() {
                _currentRating = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final newRating = _currentRating.toInt();
            if (newRating != widget.initialRating) {
              widget.onRatingChanged(newRating);
            }
            Navigator.of(context).pop();
          },
          child: const Text('Update'),
        ),
      ],
    );
  }

  int _getDivisions() {
    final step = SettingsManager().ratingSliderStep;
    switch (step) {
      case RatingSliderStep.step5: return 20;
      case RatingSliderStep.step10: return 10;
      case RatingSliderStep.step20: return 5;
      case RatingSliderStep.step25: return 4;
      case RatingSliderStep.step1: return 100;
    }
  }
}

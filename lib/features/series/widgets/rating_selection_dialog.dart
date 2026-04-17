import 'package:flutter/material.dart';

class RatingSelectionDialog extends StatefulWidget {
  final int initialRating;
  final Function(int) onRatingChanged;

  const RatingSelectionDialog({
    Key? key,
    required this.initialRating,
    required this.onRatingChanged,
  }) : super(key: key);

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
      backgroundColor: const Color(0xFF23232a),
      title: const Text(
        'Set Your Rating',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentRating.toInt() == 0 ? 'Unrated' : _currentRating.toInt().toString(),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _currentRating,
            min: 0,
            max: 100,
            divisions: 100,
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
}
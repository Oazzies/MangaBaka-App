import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/settings/settings_enums.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';


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
    final l10n = LocalizationService();
    return AlertDialog(
      backgroundColor: AppConstants.secondaryBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Text(
        l10n.translate('rating_dialog_title'),
        style: TextStyle(
          color: AppConstants.textColor, 
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppConstants.primaryBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppConstants.borderColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _currentRating.toInt() == 0 ? Icons.star_outline : Icons.star,
                  color: _currentRating.toInt() == 0 ? AppConstants.textMutedColor : AppConstants.warningColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  _currentRating.toInt() == 0
                      ? l10n.translate('rating_unrated')
                      : _currentRating.toInt().toString(),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                if (_currentRating.toInt() > 0)
                  Text(
                    ' / 100',
                    style: TextStyle(
                      color: AppConstants.textMutedColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppConstants.accentColor,
              inactiveTrackColor: AppConstants.borderColor.withValues(alpha: 0.3),
              thumbColor: AppConstants.textColor,
              overlayColor: AppConstants.accentColor.withValues(alpha: 0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
            ),
            child: Slider(
              value: _currentRating,
              min: 0,
              max: 100,
              divisions: _getDivisions(),
              onChanged: (double value) {
                setState(() {
                  _currentRating = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0', style: TextStyle(color: AppConstants.textMutedColor, fontSize: 12)),
                Text('50', style: TextStyle(color: AppConstants.textMutedColor, fontSize: 12)),
                Text('100', style: TextStyle(color: AppConstants.textMutedColor, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            l10n.translate('cancel'),
            style: TextStyle(color: AppConstants.textMutedColor, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () {
            final newRating = _currentRating.toInt();
            if (newRating != widget.initialRating) {
              widget.onRatingChanged(newRating);
            }
            Navigator.of(context).pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppConstants.accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            l10n.translate('update'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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

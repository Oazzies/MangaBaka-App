import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

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
  late final int _stepValue;
  late final int _divisions;

  @override
  void initState() {
    super.initState();
    final step = SettingsManager().ratingSliderStep;
    _stepValue = step.stepValue;
    _divisions = step.divisions;
    _currentRating = ((widget.initialRating / _stepValue).round() * _stepValue)
        .toDouble()
        .clamp(0.0, 100.0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final displayRating = _currentRating.round();
    final isUnrated = displayRating == 0;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.largeRadius),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.surfaceRaised,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colors.star.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: context.colors.star,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.translate('rating_dialog_title').toUpperCase(),
                  style: AppTypography.display(
                    color: context.colors.text,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: context.colors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.colors.border.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUnrated
                        ? Icons.star_outline
                        : Icons.star,
                    color: isUnrated
                        ? context.colors.textMuted
                        : context.colors.star,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isUnrated
                        ? l10n.translate('rating_unrated')
                        : displayRating.toString(),
                    style: AppTypography.display(
                      color: context.colors.text,
                      fontSize: 26,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (!isUnrated)
                    Text(
                      ' / 100',
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: context.colors.accent,
              inactiveTrackColor: context.colors.border.withValues(alpha: 0.3),
              thumbColor: context.colors.text,
              overlayColor: context.colors.accent.withValues(alpha: 0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
            ),
            child: Slider(
              value: _currentRating,
              min: 0,
              max: 100,
              divisions: _divisions,
              onChanged: (double value) {
                final snapped = ((value / _stepValue).round() * _stepValue)
                    .toDouble()
                    .clamp(0.0, 100.0);
                setState(() {
                  _currentRating = snapped;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0',
                  style: AppTypography.sans(
                    color: context.colors.textMuted,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '50',
                  style: AppTypography.sans(
                    color: context.colors.textMuted,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '100',
                  style: AppTypography.sans(
                    color: context.colors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  l10n.translate('cancel'),
                  style: AppTypography.sans(
                    color: context.colors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () {
                  final newRating = _currentRating.round();
                  if (newRating != widget.initialRating) {
                    widget.onRatingChanged(newRating);
                  }
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.accent,
                  foregroundColor: context.colors.onAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.pillRadius,
                    ),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.translate('update'),
                  style: AppTypography.sans(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

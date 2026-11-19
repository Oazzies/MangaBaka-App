import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/adaptive_form.dart';
import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
import 'package:mangabaka_app/features/series/widgets/progress_overflow_dialog.dart';

part 'progress_update_dialog_parts.dart';

class ProgressUpdateDialog extends StatefulWidget {
  /// Not the series total: it lags for a releasing series, and readers ahead of it must still log progress.
  static const int maxProgress = 99999;

  final int initialValue;
  final String title;
  final String maxValue;
  final bool isChapter;
  final String? seriesStatus;
  final Function(int) onUpdate;

  const ProgressUpdateDialog({
    super.key,
    required this.initialValue,
    required this.title,
    required this.maxValue,
    this.isChapter = true,
    this.seriesStatus,
    required this.onUpdate,
  });

  @override
  State<ProgressUpdateDialog> createState() => _ProgressUpdateDialogState();
}

class _ProgressUpdateDialogState extends State<ProgressUpdateDialog> {
  late int _currentValue;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _controller = TextEditingController(text: _currentValue.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _parsedTotal {
    final t = int.tryParse(widget.maxValue);
    return (t != null && t > 0) ? t : null;
  }

  int get _effectiveMax {
    final t = _parsedTotal;
    if (SettingsManager().progressOverflow == ProgressOverflowMode.never &&
        t != null) {
      // Progress already past the total from before this setting may shrink but not grow.
      return widget.initialValue > t ? widget.initialValue : t;
    }
    return ProgressUpdateDialog.maxProgress;
  }

  void _updateValue(int newValue) {
    if (newValue < 0 || newValue > _effectiveMax) return;
    setState(() {
      _currentValue = newValue;
      _controller.text = _currentValue.toString();
    });
  }

  Future<void> _handleSave() async {
    if (_currentValue > widget.initialValue) {
      final allowed = await confirmProgressOverflow(
        context,
        newValue: _currentValue,
        total: _parsedTotal,
        isChapter: widget.isChapter,
        seriesStatus: widget.seriesStatus,
      );
      if (!allowed || !mounted) return;
    }
    widget.onUpdate(_currentValue);
    Navigator.pop(context);
  }

  Widget? _totalLine(LocalizationService l10n) {
    if (widget.maxValue == 'null' || widget.maxValue.isEmpty) return null;
    return Text(
      '${l10n.translate('total')}: ${widget.maxValue}',
      style: AppTypography.sans(
        color: context.colors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final isPage = AdaptiveFormPage.isPage(context);
    final totalLine = _totalLine(l10n);

    return Container(
      decoration: isPage
          ? null
          : BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppConstants.largeRadius),
              ),
            ),
      padding: EdgeInsets.fromLTRB(
        24,
        isPage ? 20 : 12,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isPage) ...[
            const AdaptiveSheetHandle(bottomSpacing: 24),
            _ProgressDialogHeader(title: widget.title, totalLine: totalLine),
            const SizedBox(height: 24),
          ] else if (totalLine != null) ...[
            totalLine,
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: context.colors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.colors.surfaceRaised,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _IconButton(
                  icon: Icons.remove_rounded,
                  onPressed: () => _updateValue(_currentValue - 1),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    // keyboardType is only a hint (none on desktop); the formatters keep it a non-negative int.
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(
                        ProgressUpdateDialog.maxProgress.toString().length,
                      ),
                    ],
                    textAlign: TextAlign.center,
                    style: AppTypography.display(
                      color: context.colors.text,
                      fontSize: 22,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null) {
                        if (parsed > _effectiveMax) {
                          final clamped = _effectiveMax;
                          setState(() {
                            _currentValue = clamped;
                            _controller.value = TextEditingValue(
                              text: '$clamped',
                              selection: TextSelection.collapsed(
                                offset: '$clamped'.length,
                              ),
                            );
                          });
                        } else {
                          setState(() => _currentValue = parsed);
                        }
                      }
                    },
                  ),
                ),
                _IconButton(
                  icon: Icons.add_rounded,
                  onPressed: () => _updateValue(_currentValue + 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
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
                onPressed: _handleSave,
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
                  l10n.translate('save'),
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

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';

class ProgressUpdateDialog extends StatefulWidget {
  final int initialValue;
  final String title;
  final String maxValue;
  final Function(int) onUpdate;

  const ProgressUpdateDialog({
    super.key,
    required this.initialValue,
    required this.title,
    required this.maxValue,
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

  void _updateValue(int newValue) {
    if (newValue < 0) return;
    setState(() {
      _currentValue = newValue;
      _controller.text = _currentValue.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.secondaryBackground,
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
                color: AppConstants.borderColor.withValues(alpha: 0.15),
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
                  color: AppConstants.accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: AppConstants.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    if (widget.maxValue != 'null' && widget.maxValue.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.translate('total')}: ${widget.maxValue}',
                        style: TextStyle(
                          color: AppConstants.textMutedColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppConstants.primaryBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppConstants.borderColor.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _IconButton(
                  icon: Icons.remove,
                  onPressed: () => _updateValue(_currentValue - 1),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null) {
                        setState(() => _currentValue = parsed);
                      }
                    },
                  ),
                ),
                _IconButton(
                  icon: Icons.add,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  l10n.translate('cancel'),
                  style: TextStyle(
                    color: AppConstants.textMutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () {
                  widget.onUpdate(_currentValue);
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppConstants.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.pillRadius),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.translate('save'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _IconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppConstants.borderColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(icon, color: AppConstants.textColor, size: 20),
        ),
      ),
    );
  }
}

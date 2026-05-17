import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';

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
    
    return AlertDialog(
      backgroundColor: AppConstants.tertiaryBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: AppConstants.textColor,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          if (widget.maxValue != 'null' && widget.maxValue.isNotEmpty)
            Text(
              '${l10n.translate('total')}: ${widget.maxValue}',
              style: TextStyle(
                color: AppConstants.textMutedColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppConstants.primaryBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppConstants.secondaryBackground, width: 2),
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.translate('cancel'),
            style: TextStyle(
              color: AppConstants.textMutedColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onUpdate(_currentValue);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.accentColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 0,
          ),
          child: Text(
            l10n.translate('save'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
      color: AppConstants.secondaryBackground,
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

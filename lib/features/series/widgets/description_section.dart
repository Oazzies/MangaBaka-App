import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';

class DescriptionSection extends StatefulWidget {
  final String description;
  const DescriptionSection({super.key, required this.description});

  @override
  State<DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<DescriptionSection> {
  bool expanded = false;

  bool get _isLong {
    final trimmed = widget.description.trim();
    if (trimmed.isEmpty) return false;
    final wordCount = trimmed.split(RegExp(r'\s+')).length;
    return wordCount > 40 || trimmed.length > 400;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Text(
            widget.description,
            maxLines: expanded ? null : 6,
            overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(
              height: 1.7,
              fontSize: 14,
              color: AppConstants.textColor.withValues(alpha: 0.9),
            ),
          ),
        ),
        if (_isLong || widget.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                if (_isLong)
                  Expanded(
                    child: Center(
                      child: InkWell(
                        onTap: () => setState(() => expanded = !expanded),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                expanded
                                    ? LocalizationService().translate('show_less')
                                    : LocalizationService().translate('show_more'),
                                style: TextStyle(
                                  color: AppConstants.accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                size: 20,
                                color: AppConstants.accentColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                WidgetUtils.tooltip(
                  message: LocalizationService().translate('copy_description'),
                  child: IconButton(
                    icon: const Icon(Icons.copy_all, size: 20),
                    padding: const EdgeInsets.all(8),
                    color: AppConstants.textMutedColor,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.description));
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

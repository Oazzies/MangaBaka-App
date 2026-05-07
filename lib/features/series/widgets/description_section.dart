import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';

class DescriptionSection extends StatefulWidget {
  final String description;
  const DescriptionSection({super.key, required this.description});

  @override
  State<DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<DescriptionSection> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong =
        widget.description
                .trim()
                .split('\n')
                .expand((l) => l.split(' '))
                .length >
            40 ||
        widget.description.length > 400;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Stack(
            children: [
              Text(
                widget.description,
                maxLines: expanded ? null : 6,
                overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: AppConstants.textColor.withValues(alpha: 0.9),
                      fontSize: 15,
                    ),
              ),
              if (isLong && !expanded)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppConstants.primaryBackground.withValues(alpha: 0),
                          AppConstants.primaryBackground.withValues(alpha: 0.8),
                          AppConstants.primaryBackground,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (isLong || widget.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                if (isLong)
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
                                expanded ? LocalizationService().translate('show_less') : LocalizationService().translate('show_more'),
                                style: TextStyle(
                                  color: AppConstants.accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
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
                IconButton(
                  icon: const Icon(Icons.copy_all, size: 20),
                  padding: const EdgeInsets.all(8),
                  tooltip: LocalizationService().translate('copy_description'),
                  color: AppConstants.textMutedColor,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.description));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(LocalizationService().translate('description_copied')), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

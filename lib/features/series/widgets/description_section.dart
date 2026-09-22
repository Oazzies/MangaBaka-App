import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/markdown_utils.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';

class DescriptionSection extends StatefulWidget {
  final String description;
  const DescriptionSection({super.key, required this.description});

  @override
  State<DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<DescriptionSection> {
  bool expanded = false;
  final List<GestureRecognizer> _recognizers = [];

  void _clearRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _clearRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _clearRecognizers();

    final isLong =
        widget.description
                .trim()
                .split('\n')
                .expand((l) => l.split(' '))
                .length >
            40 ||
        widget.description.length > 400;

    final spans = MarkdownUtils.buildTextSpans(
      text: widget.description,
      context: context,
      registerRecognizer: (r) => _recognizers.add(r),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Stack(
            children: [
              SelectionArea(
                child: Text.rich(
                  TextSpan(children: spans),
                  maxLines: expanded ? null : 6,
                  overflow: expanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
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
                          context.colors.background.withValues(alpha: 0),
                          context.colors.background.withValues(alpha: 0.8),
                          context.colors.background,
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
                          padding: const EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 16.0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                expanded
                                    ? LocalizationService().translate(
                                        'show_less',
                                      )
                                    : LocalizationService().translate(
                                        'show_more',
                                      ),
                                style: AppTypography.sans(
                                  color: context.colors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                expanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 20,
                                color: context.colors.accent,
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
                    color: context.colors.textMuted,
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: MarkdownUtils.normalizeDescription(
                            widget.description,
                          ),
                        ),
                      );
                      AppSnackBar.show(
                        context,
                        LocalizationService().translate('description_copied'),
                      );
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

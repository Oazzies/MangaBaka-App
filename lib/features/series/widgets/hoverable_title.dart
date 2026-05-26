import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';

/// A title widget that underlines on hover to indicate it is clickable.
class HoverableTitle extends StatefulWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final FontStyle? fontStyle;
  final int maxLines;
  final List<Shadow>? shadows;
  final VoidCallback onTap;

  const HoverableTitle({
    super.key,
    required this.text,
    required this.fontSize,
    this.fontWeight = FontWeight.normal,
    required this.color,
    this.fontStyle,
    this.maxLines = 1,
    this.shadows,
    required this.onTap,
  });

  @override
  State<HoverableTitle> createState() => _HoverableTitleState();
}

class _HoverableTitleState extends State<HoverableTitle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: WidgetUtils.tooltip(
        message: LocalizationService().translate('copy_title'),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: widget.fontWeight,
                color: widget.color,
                fontStyle: widget.fontStyle,
                height: 1.1,
                shadows: widget.shadows,
                decoration: _hovered
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: widget.color.withValues(alpha: 0.6),
              ),
              maxLines: widget.maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

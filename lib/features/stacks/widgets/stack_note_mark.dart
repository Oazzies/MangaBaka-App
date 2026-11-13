import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/markdown_utils.dart';
import 'package:mangabaka_app/features/stacks/utils/stack_format.dart';

/// The mark on a grid cover that says it carries a curator's note.
class StackNoteMark extends StatelessWidget {
  final String note;
  final bool hover;
  final VoidCallback onTap;

  const StackNoteMark({
    super.key,
    required this.note,
    required this.hover,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mark = Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
      child: Icon(Icons.format_quote_rounded, size: 15, color: c.onAccent),
    );
    if (!hover) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(padding: const EdgeInsets.all(4), child: mark),
      );
    }
    return Tooltip(
      richMessage: TextSpan(
        text: MarkdownUtils.toPlainText(stackMarkdown(note)),
      ),
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      waitDuration: const Duration(milliseconds: 120),
      showDuration: const Duration(seconds: 12),
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: false,
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.shadowAt(0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: AppTypography.sans(color: c.text, fontSize: 13, height: 1.4),
      child: Padding(padding: const EdgeInsets.all(4), child: mark),
    );
  }
}

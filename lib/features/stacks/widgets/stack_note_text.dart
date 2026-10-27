import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/markdown_utils.dart';
import 'package:mangabaka_app/features/stacks/utils/stack_format.dart';

/// A curator's note on an entry: markdown, clamped to a few lines with a
/// "More" toggle, set as a pull-quote beside an accent rule.
class StackNoteText extends StatefulWidget {
  final String note;
  final int collapsedLines;

  const StackNoteText({super.key, required this.note, this.collapsedLines = 3});

  @override
  State<StackNoteText> createState() => _StackNoteTextState();
}

class _StackNoteTextState extends State<StackNoteText> {
  final List<GestureRecognizer> _recognizers = [];
  bool _expanded = false;

  void _clear() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _clear();
    final c = context.colors;
    final style = AppTypography.sans(
      color: c.text,
      fontSize: 13.5,
      height: 1.45,
    );
    final spans = MarkdownUtils.buildTextSpans(
      text: stackMarkdown(widget.note),
      context: context,
      baseStyle: style,
      registerRecognizer: _recognizers.add,
    );
    final long =
        widget.note.length > 180 || '\n'.allMatches(widget.note).length > 2;
    // Set like a pull-quote: an accent rule down the side, no box.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: spans),
                  maxLines: _expanded ? null : widget.collapsedLines,
                  overflow: _expanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
                if (long)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        LocalizationService().translate(
                          _expanded ? 'stacks_less' : 'stacks_more',
                        ),
                        style: AppTypography.sans(
                          color: c.accent,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// A [TextEditingController] that paints an inline completion after the text
/// the user has typed.
///
/// The suffix is *not* part of [text] — it is drawn as an extra span, so the
/// selection, the cursor and everything reading the controller still see only
/// what was typed. Accepting the completion is an explicit act (Tab or Right
/// arrow at the end of the line), which is what keeps a suggestion from
/// silently becoming the query.
class GhostTextEditingController extends TextEditingController {
  /// The completion drawn after [text]. Empty means no ghost.
  String ghostSuffix = '';

  /// Colour of the ghost span. Null uses the theme's muted text at half
  /// strength, so the completion reads as a suggestion, not typed text.
  Color? ghostColor;

  void clearGhost() {
    ghostSuffix = '';
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (ghostSuffix.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    return TextSpan(
      style: style,
      children: [
        TextSpan(text: text),
        TextSpan(
          text: ghostSuffix,
          style: style?.copyWith(
            color: ghostColor ??
                context.colors.textMuted.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

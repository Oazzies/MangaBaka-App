import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The suffix is only painted: [text] and selection hold just what was typed.
class GhostTextEditingController extends TextEditingController {
  String ghostSuffix = '';

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
            color:
                ghostColor ?? context.colors.textMuted.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

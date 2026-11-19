import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Crossfades between content states, with a progress line over results that are being replaced.
class BrowseContentFrame extends StatelessWidget {
  final Widget content;
  final bool showProgress;
  final double horizontalInset;

  const BrowseContentFrame({
    super.key,
    required this.content,
    required this.showProgress,
    required this.horizontalInset,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                children: [...previousChildren, ?currentChild],
              );
            },
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: content,
          ),
        ),
        if (showProgress)
          Positioned(
            top: 0,
            left: horizontalInset,
            right: horizontalInset,
            child: LinearProgressIndicator(
              minHeight: 2,
              color: context.colors.accent,
              backgroundColor: Colors.transparent,
            ),
          ),
      ],
    );
  }
}

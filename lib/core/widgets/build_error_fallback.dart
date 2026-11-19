import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Replaces Flutter's release-mode grey box, which reads as the app dying.
class BuildErrorFallback extends StatelessWidget {
  /// [details] is never shown: exception text is not for users.
  const BuildErrorFallback({super.key, this.details});

  final FlutterErrorDetails? details;

  static void install() {
    if (_debugBuild) return;
    ErrorWidget.builder = (details) => BuildErrorFallback(details: details);
  }

  static bool get _debugBuild {
    var debug = false;
    assert(() {
      debug = true;
      return true;
    }());
    return debug;
  }

  static const double _iconSize = 28;
  static const double _iconPadding = 8;

  @override
  Widget build(BuildContext context) {
    // Can replace a widget above Directionality, e.g. in MaterialApp.builder.
    final hasDirection = Directionality.maybeOf(context) != null;
    final colors = context.colors;

    // No LayoutBuilder: it throws under IntrinsicHeight; this must never fail.
    final tile = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(_iconPadding),
            child: Icon(
              Icons.error_outline_rounded,
              color: colors.textMuted,
              size: _iconSize,
            ),
          ),
        ),
      ),
    );

    final labelled = Semantics(
      label: 'This section failed to load',
      container: true,
      child: tile,
    );

    return hasDirection
        ? labelled
        : Directionality(textDirection: TextDirection.ltr, child: labelled);
  }
}

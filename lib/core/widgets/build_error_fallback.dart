import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// What a widget that throws during build is replaced with in profile and
/// release builds.
///
/// Flutter's release default is a flat grey box that fills whatever space the
/// broken widget had — on a full-screen route that reads as the app having
/// died. This keeps the failure contained and recognisable instead: a muted
/// tile with a warning glyph, sized to its slot, while the rest of the screen
/// keeps working. The error itself is already logged by
/// `FlutterError.onError`.
///
/// Debug builds keep Flutter's red error screen, which carries the message.
class BuildErrorFallback extends StatelessWidget {
  /// Creates the fallback. [details] is accepted for parity with
  /// [ErrorWidget.builder] but never shown — exception text is not for users.
  const BuildErrorFallback({super.key, this.details});

  /// The failure this widget stands in for.
  final FlutterErrorDetails? details;

  /// Installs this widget as the app-wide [ErrorWidget.builder] outside debug
  /// mode. Safe to call more than once.
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
    // This can stand in for a widget above the app's Directionality (e.g. a
    // failure in MaterialApp.builder), so it must not assume one exists.
    final hasDirection = Directionality.maybeOf(context) != null;
    final colors = context.colors;

    // No LayoutBuilder: it throws under intrinsic-sizing parents
    // (IntrinsicHeight, table cells), and an error widget must never fail.
    // FittedBox shrinks the glyph to fit tiny slots such as a chip instead.
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

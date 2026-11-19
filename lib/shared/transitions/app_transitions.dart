import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/fixed_colors.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';

abstract final class AppTransitions {
  static bool _calm(BuildContext context) =>
      DesktopLayout.isActive(context) ||
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static Widget _fadeThroughOutgoing(
    Animation<double> secondary,
    Widget child,
  ) {
    // A scrim, not an Opacity: fading a full-screen subtree forces a saveLayer every frame.
    final curved = CurvedAnimation(
      parent: secondary,
      curve: AppMotion.emphasized,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, inner) {
        final t = curved.value;
        if (t == 0) return inner!;
        return Transform.scale(
          scale: 1 - (t * 0.02),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              inner!,
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: FixedColors.dim.withValues(alpha: t * 0.35),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: child,
    );
  }

  static Route<T> fade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.enter,
        );
        if (_calm(context)) {
          return FadeTransition(opacity: curved, child: child);
        }
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1.0).animate(curved),
            child: _fadeThroughOutgoing(secondaryAnimation, child),
          ),
        );
      },
      transitionDuration: AppMotion.base,
      reverseTransitionDuration: AppMotion.fast,
    );
  }

  static Route<T> slideUp<T>(Widget page) {
    return PageRouteBuilder<T>(
      opaque: true,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.enter,
          reverseCurve: AppMotion.exit,
        );
        // On a wide screen moving up or sideways means nothing, so the page just fades in.
        if (_calm(context)) {
          return FadeTransition(opacity: curved, child: child);
        }
        return SlideTransition(
          position: Tween<Offset>(
            // A short rise, not a full slide: the page is already fading in.
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: _fadeThroughOutgoing(secondaryAnimation, child),
          ),
        );
      },
      transitionDuration: AppMotion.slow,
      reverseTransitionDuration: AppMotion.base,
    );
  }

  static Route<T> slideRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.enter,
          reverseCurve: AppMotion.exit,
        );
        if (_calm(context)) {
          return FadeTransition(opacity: curved, child: child);
        }
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.18, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: _fadeThroughOutgoing(secondaryAnimation, child),
          ),
        );
      },
      transitionDuration: AppMotion.base,
      reverseTransitionDuration: AppMotion.base,
    );
  }
}

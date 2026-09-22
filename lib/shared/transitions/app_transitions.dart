import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/fixed_colors.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';

/// Route transitions for the Ink & Amber system.
///
/// Every transition pairs movement with a fade, and pushes the outgoing page
/// slightly away instead of leaving it static — so a push reads as one surface
/// replacing another rather than a new screen sliding over a frozen one.
abstract final class AppTransitions {
  static Widget _fadeThroughOutgoing(Animation<double> secondary, Widget child) {
    // The outgoing page dims and recedes a touch; barely perceptible on its
    // own, but it is what stops a push from feeling flat.
    //
    // The dim is a scrim overlay rather than an `Opacity` on the whole page:
    // fading a full-screen subtree forces a `saveLayer` every frame of the
    // transition, which is exactly the kind of cost that makes a push stutter.
    // A `ColoredBox` painting into the existing layer is effectively free.
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
        final curved =
            CurvedAnimation(parent: animation, curve: AppMotion.enter);
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
        return SlideTransition(
          position: Tween<Offset>(
            // A short rise rather than a full-height slide: the page is
            // already fading in, so it does not need the distance.
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

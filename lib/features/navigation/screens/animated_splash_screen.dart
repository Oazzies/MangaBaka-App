import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

/// A minimalistic splash overlay that handles the transition from native splash to Flutter.
/// Should be used inside a Stack on top of the main content.
class AnimatedSplashOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const AnimatedSplashOverlay({
    super.key,
    required this.onComplete,
  });

  @override
  State<AnimatedSplashOverlay> createState() => _AnimatedSplashOverlayState();
}

class _AnimatedSplashOverlayState extends State<AnimatedSplashOverlay> {
  @override
  void initState() {
    super.initState();
    // Remove native splash as soon as we start our Flutter animation
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: AppConstants.primaryBackground,
        child: Center(
          child: Image.asset(
            'assets/mangabaka512.png',
            width: 160,
            height: 160,
          )
              .animate()
              .fadeIn(duration: 400.ms, curve: Curves.easeOut)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                duration: 600.ms,
                curve: Curves.easeOutCubic,
              ),
        ),
      )
          .animate(
            onComplete: (controller) {
              widget.onComplete();
            },
          )
          .then(delay: 800.ms)
          .fadeOut(duration: 600.ms, curve: Curves.easeInOut),
    );
  }
}

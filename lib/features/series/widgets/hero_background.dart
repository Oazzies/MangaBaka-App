import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HeroBackground extends StatelessWidget {
  final String coverUrl;
  final bool isLoaded;
  final bool isWide;

  const HeroBackground({
    super.key,
    required this.coverUrl,
    required this.isLoaded,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          WidgetUtils.networkImage(
                url: coverUrl,
                fit: BoxFit.cover,
                memCacheWidth: isWide ? 1200 : 800,
              )
              .animate(target: isLoaded ? 1 : 0)
              .fadeIn(duration: 1200.ms, curve: Curves.easeOut)
              .scale(
                begin: const Offset(1.05, 1.05),
                end: const Offset(1, 1),
                curve: Curves.easeOut,
              ),
          ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(color: Colors.black.withValues(alpha: 0.3)),
                ),
              )
              .animate(target: isLoaded ? 1 : 0)
              .fadeIn(duration: 1200.ms, curve: Curves.easeOut),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppConstants.primaryBackground],
                stops: const [0.3, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

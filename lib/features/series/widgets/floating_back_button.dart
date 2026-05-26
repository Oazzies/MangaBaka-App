import 'dart:ui';
import 'package:flutter/material.dart';

class FloatingBackButton extends StatelessWidget {
  final VoidCallback onBack;

  const FloatingBackButton({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            iconSize: 20,
            color: Colors.white,
            onPressed: onBack,
          ),
        ),
      ),
    );
  }
}

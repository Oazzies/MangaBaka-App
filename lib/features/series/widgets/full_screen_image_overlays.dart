import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/fixed_colors.dart';

/// Left/right navigation arrows shown over [FullScreenImageScreen].
class FullScreenNavArrow extends StatelessWidget {
  final bool isLeft;
  final VoidCallback onPressed;

  const FullScreenNavArrow({
    super.key,
    required this.isLeft,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: isLeft ? 16 : null,
      right: isLeft ? null : 16,
      top: 0,
      bottom: 0,
      child: Center(
        child: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: FixedColors.imageScrim.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLeft ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
              color: FixedColors.onImage,
              size: 24,
            ),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// Bottom caption/note banner shown over [FullScreenImageScreen].
class FullScreenImageNoteBanner extends StatelessWidget {
  final String note;

  const FullScreenImageNoteBanner({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 60,
      left: 32,
      right: 32,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: FixedColors.imageScrim.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: FixedColors.imageScrim.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            note,
            style: AppTypography.sans(
              color: FixedColors.onImage,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

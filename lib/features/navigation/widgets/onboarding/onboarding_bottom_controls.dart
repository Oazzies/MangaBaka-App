import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';

class OnboardingBottomControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isDesktop;
  final VoidCallback onPrevious;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const OnboardingBottomControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.isDesktop,
    required this.onPrevious,
    required this.onSkip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLastPage = currentPage == totalPages - 1;
    final localization = LocalizationService();
    final screenHeight = MediaQuery.of(context).size.height;

    final isShort = screenHeight < 600;
    final bottomPadding = isShort ? 16.0 : 32.0;
    final spacingHeight = isShort ? 16.0 : 32.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDesktop)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalPages, (index) {
                final isSelected = currentPage == index;
                return AnimatedContainer(
                  duration: AppMotion.base,
                  curve: AppMotion.emphasized,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isSelected
                        ? context.colors.accent
                        : context.colors.surfaceRaised,
                  ),
                );
              }),
            ),
          if (!isDesktop) SizedBox(height: spacingHeight),
          Row(
            children: [
              if (currentPage > 0)
                Expanded(
                  child: TextButton(
                    onPressed: onPrevious,
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.textMuted,
                      padding: EdgeInsets.symmetric(
                        vertical: isShort ? 12 : 16,
                      ),
                    ),
                    child: Text(localization.translate('onboarding_back')),
                  ),
                )
              else
                Expanded(
                  child: TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.textMuted,
                      padding: EdgeInsets.symmetric(
                        vertical: isShort ? 12 : 16,
                      ),
                    ),
                    child: Text(localization.translate('onboarding_skip')),
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: MbPrimaryButton(
                  label: isLastPage
                      ? localization.translate('onboarding_finish')
                      : localization.translate('onboarding_next'),
                  onPressed: onNext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

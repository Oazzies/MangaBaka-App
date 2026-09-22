import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';

class SelectionBottomSheet {
  static void showSelectionBottomSheet<T>({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<T> options,
    required T currentValue,
    required String Function(T) getLabel,
    required void Function(T) onSelected,
    bool isScrollable = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollable,
      builder: (BuildContext dialogContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: dialogContext.colors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppConstants.largeRadius),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dialogContext.colors.surfaceRaised,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title.toUpperCase(),
                style: AppTypography.display(
                  color: dialogContext.colors.text,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTypography.sans(
                  color: dialogContext.colors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isScrollable)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: options.length,
                          itemBuilder: (context, index) => buildOptionRow(
                            options[index],
                            currentValue,
                            getLabel,
                            onSelected,
                            dialogContext,
                          ),
                        )
                      else
                        ...options.map(
                          (option) => buildOptionRow(
                            option,
                            currentValue,
                            getLabel,
                            onSelected,
                            dialogContext,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget buildOptionRow<T>(
    T option,
    T currentValue,
    String Function(T) getLabel,
    void Function(T) onSelected,
    BuildContext context,
  ) {
    final isSelected = option == currentValue;
    return MbTappable(
      pressedScale: 0.985,
      onTap: () {
        onSelected(option);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.emphasized,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.accent.withValues(alpha: 0.14)
              : context.colors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppConstants.denseRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                getLabel(option),
                style: AppTypography.sans(
                  color: isSelected
                      ? context.colors.accent
                      : context.colors.text,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: AppMotion.fast,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check_circle_rounded,
                      key: const ValueKey('checked'),
                      color: context.colors.accent,
                      size: 22,
                    )
                  : const SizedBox(
                      key: ValueKey('unchecked'),
                      width: 22,
                      height: 22,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

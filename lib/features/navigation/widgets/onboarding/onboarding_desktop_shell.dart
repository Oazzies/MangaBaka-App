import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_title_bar.dart';
import 'package:window_manager/window_manager.dart';

typedef OnboardingStep = ({String titleKey, IconData icon, Widget page});

class OnboardingDesktopShell extends StatelessWidget {
  final List<OnboardingStep> steps;
  final int currentPage;
  final Widget pageView;
  final bool isRedoing;
  final ValueChanged<int> onSelectPage;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const OnboardingDesktopShell({
    super.key,
    required this.steps,
    required this.currentPage,
    required this.pageView,
    required this.isRedoing,
    required this.onSelectPage,
    required this.onPrevious,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        children: [
          Container(
            height: DesktopTitleBar.height,
            decoration: BoxDecoration(
              color: context.colors.background,
              border: Border(
                bottom: BorderSide(color: context.colors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: DesktopTitleBar.height,
                    child: DragToMoveArea(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.translate('onboarding').toUpperCase(),
                            style: AppTypography.monoLabel(
                              color: context.colors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 12),
                  child: DesktopWindowButtons(
                    showMaximize: false,
                    onClose: isRedoing
                        ? () => Navigator.of(context).pop()
                        : null,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                DesktopSidePanel(width: 280, child: _brandPanel(context, l10n)),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                36,
                                24,
                                36,
                                16,
                              ),
                              child: pageView,
                            ),
                          ),
                        ),
                      ),
                      _bottomControls(context, l10n),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandPanel(BuildContext context, LocalizationService l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Image.asset('assets/mangabaka512.png', width: 32, height: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppConstants.appName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(
                      color: context.colors.text,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              itemCount: steps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, i) {
                final step = steps[i];
                return _stepItem(
                  context,
                  index: i,
                  title: l10n.translate(step.titleKey),
                  icon: step.icon,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 15,
                  color: context.colors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.translate('onboarding_settings_hint'),
                    style: AppTypography.sans(
                      color: context.colors.textMuted,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepItem(
    BuildContext context, {
    required int index,
    required String title,
    required IconData icon,
  }) {
    final isCurrent = index == currentPage;
    final isDone = index < currentPage;

    final fg = isCurrent ? context.colors.onAccent : context.colors.text;
    final iconColor = isCurrent
        ? context.colors.onAccent
        : (isDone ? context.colors.accent : context.colors.textMuted);

    return DesktopHoverSurface(
      onTap: () => onSelectPage(index),
      selected: isCurrent,
      selectedColor: context.colors.accent,
      hoverColor: context.colors.surface,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : icon,
            size: 20,
            color: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display(color: fg, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomControls(BuildContext context, LocalizationService l10n) {
    final isLastPage = currentPage == steps.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: context.colors.background,
        border: Border(top: BorderSide(color: context.colors.border, width: 1)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: currentPage > 0
                    ? DesktopPillButton(
                        label: l10n.translate('onboarding_back'),
                        icon: Icons.arrow_back_rounded,
                        onPressed: onPrevious,
                      )
                    : DesktopPillButton(
                        label: l10n.translate('onboarding_skip'),
                        onPressed: onSkip,
                      ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: MbPrimaryButton(
                  expand: false,
                  label: isLastPage
                      ? l10n.translate('onboarding_finish')
                      : l10n.translate('onboarding_next'),
                  trailingIcon: isLastPage
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  onPressed: onNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

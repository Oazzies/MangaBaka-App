import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_nav.dart';
import 'package:mangabaka_app/features/navigation/models/nav_destinations.dart';
import 'package:mangabaka_app/features/profile/screens/settings_screen.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class MainNavRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final LocalizationService l10n;

  final NavRailSide side;

  static const double _width = 88;

  const MainNavRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.l10n,
    required this.side,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = side == NavRailSide.left;

    return Container(
      width: _width,
      color: context.colors.background,
      child: SafeArea(
        // Only the outward edge meets the screen edge.
        left: !isLeft,
        right: isLeft,
        child: MbNavRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: navDestinations(l10n),
          leading: const _RailLogo(),
          trailing: _SettingsButton(l10n: l10n),
        ),
      ),
    );
  }
}

enum NavRailSide { left, right }

class NavRailDivider extends StatelessWidget {
  const NavRailDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, color: context.colors.border);
  }
}

class _RailLogo extends StatelessWidget {
  const _RailLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppConstants.denseRadius),
          ),
          child: Image.asset('assets/mangabaka512.png', width: 36, height: 36),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final LocalizationService l10n;

  const _SettingsButton({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return WidgetUtils.tooltip(
      message: l10n.translate('settings'),
      child: IconButton(
        icon: const Icon(Icons.settings_outlined),
        onPressed: () => SettingsScreen.show(context),
        color: context.colors.textMuted,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/features/browse/controllers/mix_controller.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The three switches that shape a mix.
///
/// Two of them need an account — they are rendered dimmed with a "Requires
/// login" subtitle rather than hidden, so the feature is discoverable to a
/// logged-out user instead of silently absent.
class MixOptionsSection extends StatelessWidget {
  final MixController controller;
  final LocalizationService l10n;

  const MixOptionsSection({
    super.key,
    required this.controller,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = getIt<ProfileAuthService>().isLoggedIn;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        ),
        child: Column(
          children: [
            MixToggleRow(
              icon: Icons.tune_rounded,
              title: 'Strict Mode',
              subtitle: 'Hard-filter tags instead of vector boost',
              value: controller.strictMode,
              onChanged: controller.setStrictMode,
              isFirst: true,
            ),
            const _OptionDivider(),
            MixToggleRow(
              icon: Icons.visibility_off_outlined,
              title: l10n.translate('hide_library'),
              subtitle: l10n.translate('hide_library_subtext'),
              value: controller.excludeLibrary,
              onChanged: isLoggedIn ? controller.setExcludeLibrary : null,
              requiresLogin: !isLoggedIn,
            ),
            const _OptionDivider(),
            MixToggleRow(
              icon: Icons.merge_type_rounded,
              title: 'Blend My Taste',
              subtitle: 'Mix recommendations with your library taste',
              value: controller.blendUser,
              onChanged: isLoggedIn ? controller.setBlendUser : null,
              requiresLogin: !isLoggedIn,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionDivider extends StatelessWidget {
  const _OptionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.colors.border,
      indent: 16,
      endIndent: 16,
    );
  }
}

/// A single labelled switch inside the options card.
class MixToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;

  /// Null disables the switch — pass null together with [requiresLogin] so the
  /// row explains why it is inert.
  final ValueChanged<bool>? onChanged;

  final bool isFirst;
  final bool isLast;

  /// Dims the row and replaces [subtitle] with "Requires login".
  final bool requiresLogin;

  const MixToggleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isFirst = false,
    this.isLast = false,
    this.requiresLogin = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = requiresLogin
        ? context.colors.textMuted.withValues(alpha: 0.5)
        : context.colors.text;
    final iconColor = requiresLogin
        ? context.colors.textMuted.withValues(alpha: 0.4)
        : context.colors.accent;

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 4 : 0, bottom: isLast ? 4 : 0),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 20),
        title: Text(
          title,
          style: AppTypography.sans(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          requiresLogin ? 'Requires login' : subtitle,
          style: AppTypography.sans(
            color: context.colors.textMuted.withValues(
              alpha: requiresLogin ? 0.5 : 1.0,
            ),
            fontSize: 12,
          ),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: context.colors.accent,
          activeTrackColor: context.colors.accent.withValues(alpha: 0.4),
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }
}

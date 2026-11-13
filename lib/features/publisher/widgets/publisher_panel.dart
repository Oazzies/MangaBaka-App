import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/series/widgets/mb_card.dart';

String capitalizePublisherKey(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');

class PublisherPanel extends StatelessWidget {
  final String? label;
  final Widget? trailing;
  final Widget child;

  const PublisherPanel({
    super.key,
    this.label,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!DesktopLayout.isActive(context)) {
      return MbCard(label: label, trailing: trailing, child: child);
    }
    return DesktopCard(
      showBorder: false,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null)
            DesktopSectionTitle(
              title: label!,
              trailing: trailing,
              fontSize: 16,
              padding: const EdgeInsets.only(bottom: 14),
            ),
          child,
        ],
      ),
    );
  }
}

class PublisherSubLabel extends StatelessWidget {
  final String text;

  const PublisherSubLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: AppTypography.monoLabel(
      color: context.colors.textMuted,
      fontSize: 10,
    ),
  );
}

class PublisherBadge extends StatelessWidget {
  final String text;

  const PublisherBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTypography.monoLabel(
          color: context.colors.accent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class PublisherNoteLine extends StatelessWidget {
  final String text;

  const PublisherNoteLine({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: context.colors.textMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.sans(
              color: context.colors.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class PublisherSectionLoading extends StatelessWidget {
  const PublisherSectionLoading({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Center(child: MbSpinner(size: 20, strokeWidth: 2)),
  );
}

class PublisherSectionError extends StatelessWidget {
  final String label;
  final VoidCallback onRetry;
  final LocalizationService l10n;

  const PublisherSectionError({
    super.key,
    required this.label,
    required this.onRetry,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return PublisherPanel(
      label: label,
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: onRetry,
          child: Text(l10n.translate('retry')),
        ),
      ),
    );
  }
}

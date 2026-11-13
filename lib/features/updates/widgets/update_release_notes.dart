import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateReleaseNotes extends StatelessWidget {
  final String body;
  final LocalizationService l10n;

  const UpdateReleaseNotes({super.key, required this.body, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final trimmed = body.trim();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: SingleChildScrollView(
        child: trimmed.isEmpty
            ? Text(
                l10n.translate('no_release_notes'),
                style: AppTypography.sans(
                  color: context.colors.text,
                  fontSize: 14,
                  height: 1.5,
                ),
              )
            : MarkdownBody(
                data: trimmed,
                selectable: true,
                onTapLink: (text, href, title) {
                  if (href != null) {
                    final uri = Uri.tryParse(href);
                    if (uri != null) {
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  }
                },
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                    .copyWith(
                      p: AppTypography.sans(
                        color: context.colors.text,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      listBullet: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 14,
                      ),
                      h1: AppTypography.display(
                        color: context.colors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      h2: AppTypography.display(
                        color: context.colors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      h3: AppTypography.display(
                        color: context.colors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      a: AppTypography.sans(
                        color: context.colors.accent,
                        fontSize: 14,
                      ).copyWith(decoration: TextDecoration.underline),
                      code: TextStyle(
                        fontFamily: 'monospace',
                        color: context.colors.accent,
                        fontSize: 13,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: context.colors.surfaceRaised,
                        borderRadius: BorderRadius.circular(
                          AppConstants.denseRadius,
                        ),
                      ),
                    ),
              ),
      ),
    );
  }
}

class UpdateErrorBanner extends StatelessWidget {
  final LocalizationService l10n;

  const UpdateErrorBanner({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppConstants.denseRadius),
        border: Border.all(color: context.colors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: context.colors.error,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.translate('update_failed'),
              style: AppTypography.sans(
                color: context.colors.error.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

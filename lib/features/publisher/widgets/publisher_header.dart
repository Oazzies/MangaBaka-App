import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/utils/format_count.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_logo.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_panel.dart';

List<String> _publisherFacts(Publisher publisher, LocalizationService l10n) => [
  if (publisher.countryOfOrigin != null &&
      publisher.countryOfOrigin!.isNotEmpty)
    publisher.countryOfOrigin!,
  if (publisher.languages.isNotEmpty)
    publisher.languages.map((l) => l.toUpperCase()).join(' · '),
  if (publisher.founded != null)
    l10n
        .translate('publisher_established')
        .replaceAll('{year}', '${publisher.founded}'),
  if (publisher.seriesCount != null)
    l10n
        .translate('publisher_series_count')
        .replaceAll('{count}', formatCount(publisher.seriesCount!)),
];

class PublisherMobileHeader extends StatelessWidget {
  final Publisher publisher;
  final LocalizationService l10n;

  const PublisherMobileHeader({
    super.key,
    required this.publisher,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final facts = _publisherFacts(publisher, l10n);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PublisherLogoView(publisher: publisher, size: 72),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  publisher.name,
                  style: AppTypography.display(
                    color: context.colors.text,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (publisher.subType.isNotEmpty)
                      PublisherBadge(text: publisher.subType.toUpperCase()),
                    if (publisher.closed != null)
                      Text(
                        l10n
                            .translate('publisher_closed')
                            .replaceAll('{year}', '${publisher.closed}'),
                        style: AppTypography.sans(
                          color: context.colors.error.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    for (final fact in facts)
                      Text(
                        fact,
                        style: AppTypography.sans(
                          color: context.colors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PublisherDesktopIdentity extends StatelessWidget {
  final Publisher publisher;
  final LocalizationService l10n;
  final bool loading;

  const PublisherDesktopIdentity({
    super.key,
    required this.publisher,
    required this.l10n,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final facts = _publisherFacts(publisher, l10n);
    final description = publisher.description;

    return DesktopCard(
      showBorder: false,
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PublisherLogoView(publisher: publisher, size: 112),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      publisher.name,
                      style: AppTypography.display(
                        color: colors.text,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (publisher.subType.isNotEmpty)
                          PublisherBadge(text: publisher.subType.toUpperCase()),
                        if (publisher.closed != null)
                          Text(
                            l10n
                                .translate('publisher_closed')
                                .replaceAll('{year}', '${publisher.closed}'),
                            style: AppTypography.sans(
                              color: colors.error.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        for (final fact in facts)
                          Text(
                            fact,
                            style: AppTypography.monoLabel(
                              color: colors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (loading) const MbSpinner(size: 20, strokeWidth: 2),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 22),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: DesktopTokens.readableWidth,
              ),
              child: Text(
                description,
                style: AppTypography.sans(
                  color: colors.text,
                  fontSize: 14.5,
                  height: 1.55,
                ),
              ),
            ),
          ],
          if (publisher.note != null && publisher.note!.isNotEmpty) ...[
            const SizedBox(height: 14),
            PublisherNoteLine(text: publisher.note!),
          ],
        ],
      ),
    );
  }
}

import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/publisher/utils/format_count.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_logo.dart';

class PublisherListItem extends StatelessWidget {
  final Publisher publisher;
  final VoidCallback onTap;

  /// Space around the card. The default suits a vertical list; a grid supplies
  /// its own spacing and passes [EdgeInsets.zero].
  final EdgeInsetsGeometry? margin;

  const PublisherListItem({
    super.key,
    required this.publisher,
    required this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final desktop = DesktopLayout.isActive(context);
    final row = Row(
            children: [
              PublisherLogoView(publisher: publisher, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      publisher.name,
                      style: AppTypography.sans(
                        color: context.colors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Wraps rather than overflows: in a narrow grid cell the
                    // badge and its facts do not fit on one line.
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (publisher.subType.isNotEmpty)
                          _buildBadge(context, publisher.subType.toUpperCase())
                        else if (publisher.topMediaType != null &&
                            publisher.topMediaType!.isNotEmpty)
                          _buildBadge(
                            context,
                            publisher.topMediaType!.toUpperCase(),
                          ),
                        if (publisher.seriesCount != null)
                          _buildInfoText(
                            context,
                            l10n
                                .translate('publisher_series_count')
                                .replaceAll(
                                  '{count}',
                                  formatCount(publisher.seriesCount!),
                                ),
                          ),
                        if (publisher.countryOfOrigin != null &&
                            publisher.countryOfOrigin!.isNotEmpty)
                          _buildInfoText(context, publisher.countryOfOrigin!),
                        if (publisher.founded != null)
                          _buildInfoText(
                            context,
                            l10n
                                .translate('publisher_established')
                                .replaceAll('{year}', publisher.founded.toString()),
                          ),
                        if (publisher.closed != null)
                          _buildInfoText(
                            context,
                            l10n
                                .translate('publisher_closed')
                                .replaceAll('{year}', publisher.closed.toString()),
                            isError: true,
                          ),
                        if (publisher.imprints.isNotEmpty)
                          _buildInfoText(
                            context,
                            l10n
                                .translate('publisher_imprints')
                                .replaceAll(
                                  '{count}',
                                  publisher.imprints.length.toString(),
                                ),
                          ),
                        if (publisher.links.isNotEmpty)
                          Icon(
                            Icons.link_rounded,
                            size: 14,
                            color: context.colors.accent.withValues(alpha: 0.6),
                          ),
                      ],
                    ),
                    if (publisher.description != null &&
                        publisher.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        publisher.description!,
                        style: AppTypography.sans(
                          color: context.colors.textMuted,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // A pointer needs no chevron: the hover fill says it is clickable.
              if (!desktop) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.colors.textMuted.withValues(alpha: 0.5),
                ),
              ],
            ],
          );

    if (desktop) {
      return DesktopHoverSurface(
        onTap: onTap,
        idleColor: context.colors.surface,
        borderRadius: BorderRadius.circular(DesktopTokens.panelRadius),
        padding: const EdgeInsets.all(16),
        child: row,
      );
    }

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        hoverColor: context.colors.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: row,
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTypography.sans(
          color: context.colors.accent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoText(
    BuildContext context,
    String text, {
    bool isError = false,
  }) {
    return Text(
      text,
      style: AppTypography.sans(
        color: isError
            ? context.colors.error.withValues(alpha: 0.8)
            : context.colors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

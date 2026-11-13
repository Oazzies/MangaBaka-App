import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// A link chip with favicon, domain title, and optional language badge.
class HoverableLinkChip extends StatelessWidget {
  final Uri uri;
  final String faviconUrl;
  final String displayName;
  final String? language;

  const HoverableLinkChip({
    super.key,
    required this.uri,
    required this.faviconUrl,
    required this.displayName,
    this.language,
  });

  static Widget? fromDynamic(dynamic link) {
    String url = '';
    String displayName = '';
    String? language;

    if (link is String) {
      final parsed = Uri.tryParse(link);
      if (parsed != null && parsed.hasAbsolutePath && parsed.host.isNotEmpty) {
        url = link;
        final domain = parsed.host.replaceFirst('www.', '');
        displayName = domain.split('.').first;
        if (displayName.isNotEmpty) {
          displayName = displayName[0].toUpperCase() + displayName.substring(1);
        }
        final langMatch = RegExp(r'\/([a-z]{2})\/').firstMatch(parsed.path);
        if (langMatch != null) {
          language = langMatch.group(1)!.toUpperCase();
        }
      }
    } else if (link.runtimeType.toString() == 'SeriesLink') {
      try {
        url = link.url;
        displayName = link.nameDisplay;
        language = link.language?.toString().toUpperCase();
      } catch (e, st) {
        LoggingService.logger.fine('Failed to read SeriesLink fields', e, st);
        return null;
      }
    }

    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final domain = uri.host.replaceFirst('www.', '');
    final faviconUrl =
        'https://www.google.com/s2/favicons?domain=$domain&sz=64';

    return HoverableLinkChip(
      uri: uri,
      faviconUrl: faviconUrl,
      displayName: displayName,
      language: language,
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppConstants.cardRadius);
    return WidgetUtils.tooltip(
      message: LocalizationService()
          .translate('open_link')
          .replaceAll('{name}', displayName),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border.all(color: context.colors.border, width: 1),
          borderRadius: borderRadius,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => launchUrl(uri),
            borderRadius: borderRadius,
            hoverColor: context.colors.accent.withValues(alpha: 0.1),
            splashColor: context.colors.accent.withValues(alpha: 0.1),
            highlightColor: context.colors.accent.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: WidgetUtils.networkImage(
                      url: faviconUrl,
                      width: 18,
                      height: 18,
                      errorWidget: Icon(
                        Icons.link,
                        size: 18,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    displayName,
                    style: AppTypography.sans(
                      color: context.colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (language?.isNotEmpty ?? false) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceRaised,
                        border: Border.all(
                          color: context.colors.border,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        language!,
                        style: AppTypography.monoLabel(
                          color: context.colors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

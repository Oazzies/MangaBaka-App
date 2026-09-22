import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/widgets/chip.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class WidgetUtils {
  static Widget responsiveConstraint(Widget child, {double maxWidth = 800}) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  static Widget tooltip({required String message, required Widget child}) {
    return AppTooltip(message: message, child: child);
  }

  /// Whether covers of [contentRating] are blurred, per the user's content
  /// preferences. The one answer every cover should ask, so a rating the user
  /// blurs is blurred everywhere it shows.
  static bool isRatingBlurred(String contentRating) => SettingsManager()
      .blurredContentRatings
      .contains(contentRating.toLowerCase());

  static Widget networkImage({
    required String url,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    int? memCacheWidth,
    int? memCacheHeight,
    bool blurred = false,
  }) {
    if (url.isEmpty) {
      final iconSize = (width != null && width.isFinite) ? width : 24.0;
      return errorWidget ??
          _BrokenImageIcon(size: iconSize);
    }

    final Widget image = url.startsWith('assets/')
        ? Image.asset(
            url,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              final iconSize = (width != null && width.isFinite) ? width : 24.0;
              return errorWidget ??
                  _BrokenImageIcon(size: iconSize);
            },
          )
        : CachedNetworkImage(
            imageUrl: url,
            httpHeaders: const {'User-Agent': AppConstants.userAgent},
            width: width,
            height: height,
            fit: fit,
            memCacheWidth: memCacheWidth,
            memCacheHeight: memCacheHeight,
            placeholder: (context, url) =>
                placeholder ??
                const _ImagePlaceholder(),
            errorWidget: (context, url, error) {
              // Surface the failing host + error so image outages (dead CDN,
              // TLS handshake, cleartext block, rate limit) are diagnosable from
              // the in-app log rather than a silent broken-image icon.
              LoggingService.logger.warning('Image load failed: $url — $error');
              final iconSize = (width != null && width.isFinite) ? width : 24.0;
              return errorWidget ??
                  _BrokenImageIcon(size: iconSize);
            },
            fadeOutDuration: const Duration(milliseconds: 300),
            fadeInDuration: const Duration(milliseconds: 300),
          );

    if (!blurred) return image;

    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: image,
    );
  }

  static Widget chipWrap(
    String label,
    List<String> items, {
    Color? color,
    Function(String)? onChipTap,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _SectionLabel(label),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (e) => ChipBase(
                  backgroundColor: color,
                  label: SelectableText(e),
                  onTap: onChipTap != null ? () => onChipTap(e) : null,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  static Widget linkList(List<dynamic> links) {
    if (links.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _SectionLabel('Links'),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: links.map<Widget>((l) {
            String url = '';
            String displayName = '';
            String? language;

            if (l is String) {
              if (Uri.tryParse(l)?.hasAbsolutePath == true) {
                url = l;
                final uri = Uri.parse(l);
                final domain = uri.host.replaceFirst('www.', '');
                displayName = domain.split('.').first;
                displayName =
                    displayName[0].toUpperCase() + displayName.substring(1);

                final langMatch = RegExp(
                  r'\/([a-z]{2})\/',
                ).firstMatch(uri.path);
                if (langMatch != null) {
                  language = langMatch.group(1)!.toUpperCase();
                }
              }
            } else if (l.runtimeType.toString() == 'SeriesLink') {
              try {
                url = l.url;
                displayName = l.nameDisplay;
                language = l.language?.toString().toUpperCase();
              } catch (e) {
                return const SizedBox.shrink();
              }
            }

            if (url.isEmpty) return const SizedBox.shrink();
            final uri = Uri.parse(url);
            final domain = uri.host.replaceFirst('www.', '');
            final faviconUrl =
                'https://www.google.com/s2/favicons?domain=$domain&sz=64';

            return _HoverableLinkChip(
              uri: uri,
              faviconUrl: faviconUrl,
              displayName: displayName,
              language: language,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// A reactive tooltip that listens to [SettingsManager] to show or hide itself.
class AppTooltip extends StatelessWidget {
  final String message;
  final Widget child;

  const AppTooltip({super.key, required this.message, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsManager(),
      builder: (context, _) {
        if (!SettingsManager().showTooltips) return child;
        return Tooltip(message: message, child: child);
      },
    );
  }
}

/// A link chip that shows a subtle highlight on hover.
class _HoverableLinkChip extends StatelessWidget {
  final Uri uri;
  final String faviconUrl;
  final String displayName;
  final String? language;

  const _HoverableLinkChip({
    required this.uri,
    required this.faviconUrl,
    required this.displayName,
    this.language,
  });

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

class _BrokenImageIcon extends StatelessWidget {
  final double size;
  const _BrokenImageIcon({required this.size});

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.broken_image, size: size, color: context.colors.textMuted);
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(color: context.colors.surface);
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: AppTypography.monoLabel(
      color: context.colors.textMuted,
      fontSize: 11.5,
    ),
  );
}

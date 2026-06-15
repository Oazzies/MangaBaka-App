import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/widgets/chip.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'package:mangabaka_app/core/theme/app_typography.dart';

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
      return errorWidget ?? Icon(Icons.broken_image, size: iconSize, color: AppConstants.textMutedColor);
    }
    
    final Widget image = url.startsWith('assets/')
        ? Image.asset(
            url,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              final iconSize = (width != null && width.isFinite) ? width : 24.0;
              return errorWidget ?? Icon(Icons.broken_image, size: iconSize, color: AppConstants.textMutedColor);
            },
          )
        : CachedNetworkImage(
            imageUrl: url,
            width: width,
            height: height,
            fit: fit,
            memCacheWidth: memCacheWidth,
            memCacheHeight: memCacheHeight,
            placeholder: (context, url) => placeholder ?? Container(color: AppConstants.secondaryBackground),
            errorWidget: (context, url, error) {
              final iconSize = (width != null && width.isFinite) ? width : 24.0;
              return errorWidget ?? Icon(Icons.broken_image, size: iconSize, color: AppConstants.textMutedColor);
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

  static Widget chipWrap(String label, List<String> items, {Color? color, Function(String)? onChipTap}) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            label.toUpperCase(),
            style: AppTypography.monoLabel(
              color: AppConstants.textMutedColor,
              fontSize: 11.5,
            ),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map((e) => ChipBase(
                    backgroundColor: color,
                    label: SelectableText(e),
                    onTap: onChipTap != null ? () => onChipTap(e) : null,
                  ))
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
          child: Text(
            'Links'.toUpperCase(),
            style: AppTypography.monoLabel(
              color: AppConstants.textMutedColor,
              fontSize: 11.5,
            ),
          ),
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
                displayName = displayName[0].toUpperCase() + displayName.substring(1);
                
                final langMatch = RegExp(r'\/([a-z]{2})\/').firstMatch(uri.path);
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
            final faviconUrl = 'https://www.google.com/s2/favicons?domain=$domain&sz=64';

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

  const AppTooltip({
    super.key,
    required this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsManager(),
      builder: (context, _) {
        if (!SettingsManager().showTooltips) return child;
        return Tooltip(
          message: message,
          child: child,
        );
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
          color: AppConstants.secondaryBackground,
          border: Border.all(color: AppConstants.borderColor, width: 1),
          borderRadius: borderRadius,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => launchUrl(uri),
            borderRadius: borderRadius,
            hoverColor: AppConstants.accentColor.withValues(alpha: 0.1),
            splashColor: AppConstants.accentColor.withValues(alpha: 0.1),
            highlightColor: AppConstants.accentColor.withValues(alpha: 0.05),
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
                      errorWidget: Icon(Icons.link, size: 18, color: AppConstants.textMutedColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    displayName,
                    style: AppTypography.sans(
                      color: AppConstants.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (language?.isNotEmpty ?? false) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppConstants.tertiaryBackground,
                        border: Border.all(color: AppConstants.borderColor, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        language!,
                        style: AppTypography.mono(
                          color: AppConstants.textMutedColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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

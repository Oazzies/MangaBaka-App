import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/widgets/chip.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';

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

  static Widget chipWrap(String label, List<String> items, {Color? color}) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppConstants.textColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map((e) => ChipBase(
                    backgroundColor: color,
                    label: SelectableText(e),
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
        Text(
          'Links',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppConstants.textColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
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
    return Tooltip(
      message: LocalizationService()
          .translate('open_link')
          .replaceAll('{name}', displayName),
      child: Material(
        color: AppConstants.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => launchUrl(uri),
          borderRadius: BorderRadius.circular(16),
          hoverColor: AppConstants.accentColor.withValues(alpha: 0.1),
          splashColor: AppConstants.accentColor.withValues(alpha: 0.1),
          highlightColor: AppConstants.accentColor.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  faviconUrl,
                  width: 18,
                  height: 18,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.link, size: 18, color: AppConstants.textMutedColor),
                ),
                const SizedBox(width: 10),
                Text(
                  displayName,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (language?.isNotEmpty ?? false) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppConstants.tertiaryBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      language!,
                      style: TextStyle(
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
    );
  }
}

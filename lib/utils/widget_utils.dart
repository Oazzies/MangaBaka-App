import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WidgetUtils {
  static Widget chipWrap(String label, List<String> items, {Color? color}) {
    if (items.isEmpty) return SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: items
              .map((e) => Chip(label: Text(e), backgroundColor: color))
              .toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  static Widget linkList(List<dynamic> links) {
    if (links.isEmpty) return SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Links:', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: links.map<Widget>((l) {
            if (l is String && Uri.tryParse(l)?.hasAbsolutePath == true) {
              final uri = Uri.parse(l);
              final domain = uri.host.replaceFirst('www.', '');

              var prettyName = domain.split('.').first;
              prettyName =
                  prettyName[0].toUpperCase() + prettyName.substring(1);

              final langMatch = RegExp(r'\/([a-z]{2})\/').firstMatch(uri.path);
              if (langMatch != null) {
                prettyName += ' ${langMatch.group(1)!.toUpperCase()}';
              }

              final faviconUrl = 'https://icons.duckduckgo.com/ip3/$domain.ico';

              return ActionChip(
                avatar: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Image.network(
                    faviconUrl,
                    width: 20,
                    height: 20,
                    errorBuilder: (_, __, ___) => const Icon(Icons.link),
                  ),
                ),
                label: Text(prettyName),
                tooltip: l,
                onPressed: () => launchUrl(uri),
              );
            }
            return const SizedBox.shrink();
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

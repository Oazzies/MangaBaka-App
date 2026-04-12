import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WidgetUtils {
  static Widget infoRow(String label, String value) {
    if (value.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  static Widget chipWrap(String label, List<String> items, {Color? color}) {
    if (items.isEmpty) return SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: items.map((e) => Chip(label: Text(e), backgroundColor: color)).toList(),
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
        ...links.map((l) {
          if (l is String && Uri.tryParse(l)?.hasAbsolutePath == true) {
            return InkWell(
              onTap: () => launchUrl(Uri.parse(l)),
              child: Text(l, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
            );
          }
          return Text(l.toString());
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  static Widget mapSection(String label, Map? map) {
    if (map == null || map.isEmpty) return SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ...map.entries.map((e) => infoRow(e.key, e.value.toString())),
        const SizedBox(height: 8),
      ],
    );
  }
}
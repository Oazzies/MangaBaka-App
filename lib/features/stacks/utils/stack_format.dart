import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/publisher/utils/format_count.dart';

/// "3h ago", "2d ago", "just now": how long ago [when] was, coarsely.
String stackTimeAgo(DateTime? when, LocalizationService l10n, {DateTime? now}) {
  if (when == null) return '';
  final diff = (now ?? DateTime.now()).difference(when.toLocal());
  String unit(String key, int n) => l10n.translate(key).replaceAll('{n}', '$n');
  if (diff.inMinutes < 1) return l10n.translate('stacks_time_now');
  if (diff.inHours < 1) return unit('stacks_time_minutes', diff.inMinutes);
  if (diff.inDays < 1) return unit('stacks_time_hours', diff.inHours);
  if (diff.inDays < 30) return unit('stacks_time_days', diff.inDays);
  if (diff.inDays < 365) return unit('stacks_time_months', diff.inDays ~/ 30);
  return unit('stacks_time_years', diff.inDays ~/ 365);
}

/// "6 entries", "1 entry" and friends: [count] with the singular or plural
/// form of the `stacks_count_<noun>` key.
String stackCount(String noun, int count, LocalizationService l10n) {
  final key = count == 1 ? 'stacks_count_${noun}_one' : 'stacks_count_$noun';
  return l10n.translate(key).replaceAll('{n}', formatCount(count));
}

/// Turns the block-level markdown stack descriptions and notes use into the
/// inline markdown [MarkdownUtils] renders: headings become bold lines,
/// rules a divider, list items bullets, quotes plain lines.
String stackMarkdown(String raw) {
  final lines = raw.replaceAll('\r\n', '\n').split('\n');
  final out = <String>[];
  for (final line in lines) {
    final t = line.trimLeft();
    final heading = RegExp(r'^#{1,6}\s+(.*)$').firstMatch(t);
    if (heading != null) {
      final text = heading.group(1)!.trim();
      out.add(text.isEmpty ? '' : '**$text**');
    } else if (RegExp(r'^([-*_])(\s*\1){2,}\s*$').hasMatch(t)) {
      out.add('———');
    } else if (RegExp(r'^[-*+]\s+').hasMatch(t)) {
      out.add('•  ${t.replaceFirst(RegExp(r'^[-*+]\s+'), '')}');
    } else if (t.startsWith('>')) {
      out.add(t.replaceFirst(RegExp(r'^>\s?'), ''));
    } else {
      out.add(line);
    }
  }
  return out.join('\n');
}

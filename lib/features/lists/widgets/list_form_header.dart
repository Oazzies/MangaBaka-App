import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/adaptive_form.dart';

/// In a page the app bar carries the title and the way back, so only [subtitle] remains.
class ListFormHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const ListFormHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sub = Text(
      subtitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.sans(color: c.textMuted, fontSize: 13),
    );
    if (AdaptiveFormPage.isPage(context)) return sub;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: AppTypography.display(color: c.text, fontSize: 18),
                ),
                const SizedBox(height: 4),
                sub,
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          key: const ValueKey('list_form_close'),
          tooltip: LocalizationService().translate('close'),
          icon: Icon(Icons.close_rounded, color: c.textMuted),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

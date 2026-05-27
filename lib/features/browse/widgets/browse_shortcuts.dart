import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/widgets/shortcut_section.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';

class BrowseShortcuts extends StatelessWidget {
  final Function(String, String, {String? type}) onNavigate;
  final VoidCallback onMix;

  const BrowseShortcuts({
    super.key,
    required this.onNavigate,
    required this.onMix,
  });

  /// Builds a [ShortcutSection] for a content type (e.g. 'manga', 'novel').
  /// [headerKey] is the l10n key for the section header; [typeValue] is the
  /// API type string sent in the request.
  ShortcutSection _buildTypeSection(
    LocalizationService l10n, {
    required String headerKey,
    required String typeValue,
  }) {
    return ShortcutSection(
      header: l10n.translate(headerKey),
      onMostPopular: () => onNavigate(
        l10n.translate('most_popular'),
        'popularity_asc',
        type: typeValue,
      ),
      onTopRated: () => onNavigate(
        l10n.translate('top_rated'),
        'score_desc',
        type: typeValue,
      ),
      onRandom: () => onNavigate(
        l10n.translate('random'),
        'random',
        type: typeValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return ListenableBuilder(
      listenable: l10n,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: Column(
            children: [
              // ── General ──────────────────────────────────────────────
              ShortcutSection(
                header: l10n.translate('general'),
                customButtons: [
                  ShortcutButtonEntry(
                    icon: Icons.shuffle_rounded,
                    label: l10n.translate('mix'),
                    onPressed: onMix,
                  ),
                ],
              ),
              // ── Content types ────────────────────────────────────────
              _buildTypeSection(l10n, headerKey: 'type_manga', typeValue: 'manga'),
              _buildTypeSection(l10n, headerKey: 'type_manhwa', typeValue: 'manhwa'),
              _buildTypeSection(l10n, headerKey: 'type_manhua', typeValue: 'manhua'),
              _buildTypeSection(l10n, headerKey: 'novels', typeValue: 'novel'),
              _buildTypeSection(l10n, headerKey: 'oel_other', typeValue: 'oel'),
            ],
          ),
        );
      },
    );
  }
}


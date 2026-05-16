import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/widgets/shortcut_section.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';

class BrowseShortcuts extends StatelessWidget {
  final Function(String, String, {String? type}) onNavigate;

  const BrowseShortcuts({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return ListenableBuilder(
      listenable: l10n,
      builder: (context, _) {
        return SingleChildScrollView(
          child: Column(
            children: [
              ShortcutSection(
                header: l10n.translate('type_manga'),
                onMostPopular: () =>
                    onNavigate(l10n.translate('most_popular'), 'popularity_asc', type: 'manga'),
                onTopRated: () =>
                    onNavigate(l10n.translate('top_rated'), 'score_desc', type: 'manga'),
                onRandom: () => onNavigate(l10n.translate('random'), 'random', type: 'manga'),
              ),
              ShortcutSection(
                header: l10n.translate('type_manhwa'),
                onMostPopular: () =>
                    onNavigate(l10n.translate('most_popular'), 'popularity_asc', type: 'manhwa'),
                onTopRated: () =>
                    onNavigate(l10n.translate('top_rated'), 'score_desc', type: 'manhwa'),
                onRandom: () => onNavigate(l10n.translate('random'), 'random', type: 'manhwa'),
              ),
              ShortcutSection(
                header: l10n.translate('type_manhua'),
                onMostPopular: () =>
                    onNavigate(l10n.translate('most_popular'), 'popularity_asc', type: 'manhua'),
                onTopRated: () =>
                    onNavigate(l10n.translate('top_rated'), 'score_desc', type: 'manhua'),
                onRandom: () => onNavigate(l10n.translate('random'), 'random', type: 'manhua'),
              ),
              ShortcutSection(
                header: l10n.translate('novels'),
                onMostPopular: () =>
                    onNavigate(l10n.translate('most_popular'), 'popularity_asc', type: 'novel'),
                onTopRated: () =>
                    onNavigate(l10n.translate('top_rated'), 'score_desc', type: 'novel'),
                onRandom: () => onNavigate(l10n.translate('random'), 'random', type: 'novel'),
              ),
              ShortcutSection(
                header: l10n.translate('oel_other'),
                onMostPopular: () =>
                    onNavigate(l10n.translate('most_popular'), 'popularity_asc', type: 'oel'),
                onTopRated: () =>
                    onNavigate(l10n.translate('top_rated'), 'score_desc', type: 'oel'),
                onRandom: () => onNavigate(l10n.translate('random'), 'random', type: 'oel'),
              ),
            ],
          ),
        );
      },
    );
  }
}

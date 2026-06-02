import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/widgets/mini_badge.dart';

import 'package:mangabaka_app/core/localization/localization_service.dart';

class HasAnimeChip extends StatelessWidget {
  const HasAnimeChip({super.key});

  @override
  Widget build(BuildContext context) {
    return MiniBadge(
      text: 'Anime',
      icon: Icons.ondemand_video_outlined,
      tooltip: LocalizationService().translate('anime_adaptation'),
    );
  }
}

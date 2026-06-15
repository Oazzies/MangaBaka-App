import 'package:flutter/material.dart';

enum AppListStyle {
  comfortable,
  compact,
  minimalList,
  coverOnlyGrid,
  compactGrid,
}

extension AppListStyleExtension on AppListStyle {
  bool get isGrid => this == AppListStyle.coverOnlyGrid || 
                     this == AppListStyle.compactGrid;

  double get childAspectRatio {
    if (this == AppListStyle.compactGrid) {
      return 0.56;
    }
    return 0.65;
  }

  AppListStyle get next {
    final nextIndex = (index + 1) % AppListStyle.values.length;
    return AppListStyle.values[nextIndex];
  }

  IconData get icon {
    switch (this) {
      case AppListStyle.comfortable:
        return Icons.view_day_outlined;
      case AppListStyle.compact:
        return Icons.view_headline_rounded;
      case AppListStyle.minimalList:
        return Icons.reorder_rounded;
      case AppListStyle.coverOnlyGrid:
        return Icons.grid_view_rounded;
      case AppListStyle.compactGrid:
        return Icons.apps_rounded;
    }
  }
}

enum AppStartPage { home, library, browse, news, profile }

enum RatingSliderStep { step1, step5, step10, step20, step25 }

enum TitleLanguage { defaultLang, native, romanized }

enum LibraryProgressType { chapters, volumes }

enum LandscapeAppBarPosition { top, bottom, left, right }

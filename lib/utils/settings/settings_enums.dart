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
}

enum AppStartPage { home, library, browse, news, profile }

enum RatingSliderStep { step1, step5, step10, step20, step25 }

enum TitleLanguage { defaultLang, native, romanized }

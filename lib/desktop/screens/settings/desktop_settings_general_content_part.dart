part of 'desktop_settings_screen.dart';

const List<String> _desktopContentRatings = [
  'safe',
  'suggestive',
  'erotica',
  'pornographic',
];

extension _DesktopSettingsGeneralContent on DesktopSettingsScreenState {
  Widget _buildGeneral(LocalizationService l10n) {
    final settings = SettingsManager();
    final languages = l10n.getLanguages();

    return DesktopCard(
      showBorder: false,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          DesktopSettingRow(
            icon: Icons.language,
            title: l10n.translate('language'),
            subtitle: l10n.translate('language_subtitle'),
            control: DesktopMenuButton<String>(
              valueLabel: GeneralSettingsDialogs.getLanguageName(
                l10n.currentLanguage,
              ),
              items: languages
                  .map((l) => (l['code'] as String, l['native_name'] as String))
                  .toList(),
              selected: l10n.currentLanguage,
              onSelected: (code) => l10n.setLanguage(code),
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.start,
            title: l10n.translate('start_page'),
            subtitle: l10n.translate('start_page_subtitle'),
            control: DesktopMenuButton<AppStartPage>(
              valueLabel: GeneralSettingsDialogs.getAppStartPageName(
                settings.defaultStartPage,
              ),
              items: AppStartPage.values
                  .map(
                    (p) => (p, GeneralSettingsDialogs.getAppStartPageName(p)),
                  )
                  .toList(),
              selected: settings.defaultStartPage,
              onSelected: (p) => settings.setDefaultStartPage(p),
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.translate,
            title: l10n.translate('title_language'),
            subtitle: l10n.translate('title_language_subtitle'),
            control: DesktopMenuButton<TitleLanguage>(
              valueLabel: GeneralSettingsDialogs.getTitleLanguageName(
                settings.defaultTitleLanguage,
              ),
              items: TitleLanguage.values
                  .map(
                    (t) => (t, GeneralSettingsDialogs.getTitleLanguageName(t)),
                  )
                  .toList(),
              selected: settings.defaultTitleLanguage,
              onSelected: (t) => settings.setDefaultTitleLanguage(t),
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.help_outline,
            title: l10n.translate('show_tooltips'),
            subtitle: l10n.translate('show_tooltips_subtext'),
            control: Switch(
              value: settings.showTooltips,
              onChanged: settings.setShowTooltips,
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.search,
            title: l10n.translate('auto_suggest_browse'),
            subtitle: l10n.translate('auto_suggest_browse_subtitle'),
            control: Switch(
              value: settings.autoSuggestBrowse,
              onChanged: settings.setAutoSuggestBrowse,
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.keyboard_alt_outlined,
            title: l10n.translate('auto_focus_browse_search'),
            subtitle: l10n.translate('auto_focus_browse_search_subtitle'),
            control: Switch(
              value: settings.autoFocusBrowseSearch,
              onChanged: settings.setAutoFocusBrowseSearch,
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.local_library_outlined,
            title: l10n.translate('auto_suggest_library'),
            subtitle: l10n.translate('auto_suggest_library_subtitle'),
            control: Switch(
              value: settings.autoSuggestLibrary,
              onChanged: settings.setAutoSuggestLibrary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(LocalizationService l10n) {
    final settings = SettingsManager();
    final defaultTabs = const [
      'reading',
      'paused',
      'completed',
      'plan_to_read',
      'dropped',
      'rereading',
      'considering',
    ];
    final ratingSteps = RatingSliderStep.values;

    return DesktopCard(
      showBorder: false,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesktopSettingRow(
            icon: Icons.star_outline,
            title: l10n.translate('rating_step'),
            subtitle: l10n.translate('rating_step_subtitle'),
            control: DesktopMenuButton<RatingSliderStep>(
              valueLabel: GeneralSettingsDialogs.getRatingSliderStepName(
                settings.ratingSliderStep,
              ),
              items: ratingSteps
                  .map(
                    (s) =>
                        (s, GeneralSettingsDialogs.getRatingSliderStepName(s)),
                  )
                  .toList(),
              selected: settings.ratingSliderStep,
              onSelected: (s) => settings.setRatingSliderStep(s),
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.tab,
            title: l10n.translate('library_default'),
            subtitle: l10n.translate('library_default_subtitle'),
            control: DesktopMenuButton<String>(
              valueLabel: GeneralSettingsDialogs.getLibraryTabName(
                settings.addLibraryDefaultTab,
              ),
              items: defaultTabs
                  .map((t) => (t, GeneralSettingsDialogs.getLibraryTabName(t)))
                  .toList(),
              selected: settings.addLibraryDefaultTab,
              onSelected: (t) => settings.setAddLibraryDefaultTab(t),
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.visibility_off_outlined,
            title: l10n.translate('hide_library'),
            subtitle: l10n.translate('hide_library_subtext'),
            control: Switch(
              value: settings.hideLibrarySeriesInBrowse,
              onChanged: settings.setHideLibrarySeriesInBrowse,
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.check_circle_outline,
            title: l10n.translate('auto_complete_chapters'),
            subtitle: l10n.translate('auto_complete_chapters_subtitle'),
            control: DesktopMenuButton<AutoCompleteProgressMode>(
              valueLabel:
                  GeneralSettingsDialogs.getAutoCompleteProgressModeName(
                    settings.autoCompleteChapterProgress,
                  ),
              items: AutoCompleteProgressMode.values
                  .map(
                    (m) => (
                      m,
                      GeneralSettingsDialogs.getAutoCompleteProgressModeName(m),
                    ),
                  )
                  .toList(),
              selected: settings.autoCompleteChapterProgress,
              onSelected: settings.setAutoCompleteChapterProgress,
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.task_alt_outlined,
            title: l10n.translate('auto_complete_series_status'),
            subtitle: l10n.translate('auto_complete_series_status_subtitle'),
            control: DesktopMenuButton<AutoCompleteProgressMode>(
              valueLabel:
                  GeneralSettingsDialogs.getAutoCompleteProgressModeName(
                    settings.autoCompleteSeriesStatus,
                  ),
              items: AutoCompleteProgressMode.values
                  .map(
                    (m) => (
                      m,
                      GeneralSettingsDialogs.getAutoCompleteProgressModeName(m),
                    ),
                  )
                  .toList(),
              selected: settings.autoCompleteSeriesStatus,
              onSelected: settings.setAutoCompleteSeriesStatus,
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.exposure_plus_1_rounded,
            title: l10n.translate('progress_overflow'),
            subtitle: l10n.translate('progress_overflow_subtitle'),
            control: DesktopMenuButton<ProgressOverflowMode>(
              valueLabel: GeneralSettingsDialogs.getProgressOverflowModeName(
                settings.progressOverflow,
              ),
              items: ProgressOverflowMode.values
                  .map(
                    (m) => (
                      m,
                      GeneralSettingsDialogs.getProgressOverflowModeName(m),
                    ),
                  )
                  .toList(),
              selected: settings.progressOverflow,
              onSelected: settings.setProgressOverflow,
            ),
          ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Icon(
                  Icons.filter_alt_outlined,
                  color: context.colors.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('content_preferences').toUpperCase(),
                      style: AppTypography.display(
                        color: context.colors.text,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.translate('content_preferences_subtitle'),
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final rating in _desktopContentRatings)
                      _ContentRatingRow(rating: rating, l10n: l10n),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

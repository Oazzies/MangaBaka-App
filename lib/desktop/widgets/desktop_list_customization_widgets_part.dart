part of 'desktop_list_customization.dart';

class _ProgressTrackingCards extends StatelessWidget {
  final SettingsManager settings;
  final LocalizationService l10n;

  const _ProgressTrackingCards({required this.settings, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopCard(
          showBorder: false,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.translate('progress_tracking').toUpperCase(),
                style: AppTypography.display(
                  color: context.colors.text,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              DesktopSettingRow(
                icon: Icons.analytics_outlined,
                title: l10n.translate('show_library_progress'),
                subtitle: l10n.translate('show_library_progress_subtitle'),
                control: Switch(
                  value: settings.showLibraryProgress,
                  onChanged: settings.setShowLibraryProgress,
                ),
              ),
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: settings.showLibraryProgress
                      ? Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: DesktopSettingRow(
                            icon: Icons.menu_book_outlined,
                            title: l10n.translate('library_progress_type'),
                            subtitle: l10n.translate(
                              'library_progress_type_subtitle',
                            ),
                            control: DesktopMenuButton<LibraryProgressType>(
                              valueLabel:
                                  GeneralSettingsDialogs.getLibraryProgressTypeName(
                                    settings.libraryProgressType,
                                  ),
                              items: [
                                for (final t in LibraryProgressType.values)
                                  (
                                    t,
                                    GeneralSettingsDialogs.getLibraryProgressTypeName(
                                      t,
                                    ),
                                  ),
                              ],
                              selected: settings.libraryProgressType,
                              onSelected: settings.setLibraryProgressType,
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ),
              const Divider(height: 24),
              DesktopSettingRow(
                icon: Icons.hourglass_empty,
                title: l10n.translate('show_remaining_progress'),
                subtitle: l10n.translate('show_remaining_progress_subtitle'),
                control: Switch(
                  value: settings.showRemainingProgress,
                  onChanged: settings.setShowRemainingProgress,
                ),
              ),
              const Divider(height: 24),
              DesktopSettingRow(
                icon: Icons.add_circle_outline,
                title: l10n.translate('show_quick_progress'),
                subtitle: l10n.translate('show_quick_progress_subtitle'),
                control: Switch(
                  value: settings.showQuickProgress,
                  onChanged: settings.setShowQuickProgress,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DesktopCard(
          showBorder: false,
          padding: const EdgeInsets.all(20),
          child: DesktopSettingRow(
            icon: Icons.tag,
            title: l10n.translate('show_library_tab_counts'),
            subtitle: l10n.translate('show_library_tab_counts_subtitle'),
            control: Switch(
              value: settings.showLibraryTabCounts,
              onChanged: settings.setShowLibraryTabCounts,
            ),
          ),
        ),
      ],
    );
  }
}

/// One list style as a tile: its icon over its name.
class _StyleTile extends StatelessWidget {
  final AppListStyle style;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StyleTile({
    required this.style,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DesktopHoverSurface(
      onTap: onTap,
      selected: selected,
      selectedColor: context.colors.accent.withValues(alpha: 0.14),
      idleColor: context.colors.surfaceRaised,
      hoverColor: context.colors.border,
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
      child: Column(
        children: [
          Icon(
            style.icon,
            size: 26,
            color: selected ? context.colors.accent : context.colors.textMuted,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sans(
              color: selected ? context.colors.text : context.colors.textMuted,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled -/+ counter for a bounded integer setting.
class _StepperRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final int min;
  final int max;
  final String? minLabel;
  final ValueChanged<int> onChanged;

  const _StepperRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.minLabel,
  });

  @override
  Widget build(BuildContext context) {
    final display = (minLabel != null && value == min)
        ? minLabel!
        : value.toString();

    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Icon(icon, color: context.colors.textMuted, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: AppTypography.display(
              color: context.colors.text,
              fontSize: 14,
            ),
          ),
        ),
        DesktopIconButton(
          icon: Icons.remove_rounded,
          filled: true,
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 64),
          alignment: Alignment.center,
          child: Text(
            display,
            style: AppTypography.sans(
              color: context.colors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        DesktopIconButton(
          icon: Icons.add_rounded,
          filled: true,
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

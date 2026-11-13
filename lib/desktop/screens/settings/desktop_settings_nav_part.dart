part of 'desktop_settings_screen.dart';

extension _DesktopSettingsNav on DesktopSettingsScreenState {
  Widget _navItem(LocalizationService l10n, _Category c) {
    final (icon, _, titleKey, subtitleKey) = _describe(c);
    final selected = c == _navSelected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: DesktopHoverSurface(
        onTap: c == _Category.importExport
            ? () => ImportExportScreen.open(context)
            : () => _select(c),
        selected: selected,
        selectedColor: context.colors.surfaceRaised,
        hoverColor: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Icon(
                icon,
                size: 20,
                color: selected
                    ? context.colors.accent
                    : context.colors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate(titleKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      color: context.colors.text,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    l10n.translate(subtitleKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      color: context.colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _link({
    required Widget leading,
    required String label,
    required VoidCallback onTap,
    bool external = false,
    bool selected = false,
  }) {
    return DesktopHoverSurface(
      onTap: onTap,
      selected: selected,
      selectedColor: context.colors.surfaceRaised,
      hoverColor: context.colors.surface,
      borderRadius: BorderRadius.circular(10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        children: [
          SizedBox(width: 18, height: 18, child: Center(child: leading)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sans(
                color: context.colors.text,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (external)
            Icon(
              Icons.open_in_new_rounded,
              size: 15,
              color: context.colors.textMuted,
            ),
        ],
      ),
    );
  }

  Widget _pane(LocalizationService l10n) {
    return KeyedSubtree(
      key: ValueKey(_selected),
      child: _page(_selected, l10n),
    );
  }

  Widget _page(_Category category, LocalizationService l10n) {
    final (_, _, titleKey, subtitleKey) = _describe(category);

    if (category == _Category.logs) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(48, 36, 48, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _pageHeader(
              l10n,
              titleKey,
              subtitleKey,
              leading: DesktopIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: l10n.translate('back'),
                filled: true,
                onPressed: () => _select(_Category.advanced),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(child: _DesktopLogsView(l10n: l10n)),
          ],
        ),
      );
    }

    final maxWidth =
        category == _Category.lists || category == _Category.appearance
        ? DesktopTokens.maxPageWidth * 0.75
        : DesktopTokens.readableWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(48, 10, 48, 0),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: _pageHeader(l10n, titleKey, subtitleKey),
            ),
          ),
        ),
        Expanded(
          child: _ScrollPage(
            padding: const EdgeInsets.fromLTRB(48, 24, 48, 48),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: _buildCategoryContent(category, l10n),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pageHeader(
    LocalizationService l10n,
    String titleKey,
    String subtitleKey, {
    Widget? leading,
  }) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate(titleKey).toUpperCase(),
          style: AppTypography.display(
            color: context.colors.text,
            fontSize: 26,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.translate(subtitleKey),
          style: AppTypography.sans(
            color: context.colors.textMuted,
            fontSize: 14,
          ),
        ),
      ],
    );

    if (leading == null) return text;
    return Row(
      children: [
        leading,
        const SizedBox(width: 14),
        Expanded(child: text),
      ],
    );
  }

  Widget _buildCategoryContent(_Category category, LocalizationService l10n) {
    return switch (category) {
      _Category.appearance => const DesktopAppearancePage(),
      _Category.general => _buildGeneral(l10n),
      _Category.lists => DesktopListCustomization(l10n: l10n),
      _Category.content => _buildContent(l10n),
      _Category.importExport => const SizedBox.shrink(),
      _Category.account => _buildAccount(l10n),
      _Category.advanced => _buildAdvanced(l10n),
      _Category.translationCredits => _buildTranslationCredits(l10n),
      _Category.logs => const SizedBox.shrink(),
    };
  }
}

import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBackground,
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: AppConstants.primaryBackground,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([ThemeManager(), SettingsManager()]),
        builder: (context, _) {
          return ListView(
            padding: EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding, vertical: 8),
            children: [
              _buildSectionHeader('Appearance'),
              _buildSettingsGroup([
                _buildSettingItem(
                  icon: Icons.palette_outlined,
                  title: 'App Theme',
                  subtitle: _getThemeName(ThemeManager().currentTheme),
                  onTap: () => _showThemeSelectionDialog(context),
                  isFirst: true,
                  isLast: false,
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.view_list_outlined,
                  title: 'List Style',
                  subtitle: _getListStyleName(SettingsManager().currentListStyle),
                  onTap: () => _showListStyleSelectionDialog(context),
                  isFirst: false,
                  isLast: true,
                ),
              ]),
              const SizedBox(height: 16),
              _buildSectionHeader('Browse'),
              _buildSettingsGroup([
                _buildSwitchItem(
                  icon: Icons.library_books_outlined,
                  title: 'Hide Library Series',
                  subtitle: 'Exclude series already in your library from Browse search results',
                  value: SettingsManager().hideLibrarySeriesInBrowse,
                  onChanged: (value) => SettingsManager().setHideLibrarySeriesInBrowse(value),
                  isFirst: true,
                  isLast: true,
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0, top: 8.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppConstants.textMutedColor,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.secondaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppConstants.borderColor.withOpacity(0.2),
      indent: 48,
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? Radius.circular(AppConstants.cardRadius) : Radius.zero,
        bottom: isLast ? Radius.circular(AppConstants.cardRadius) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: AppConstants.textMutedColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppConstants.textMutedColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppConstants.textMutedColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.vertical(
        top: isFirst ? Radius.circular(AppConstants.cardRadius) : Radius.zero,
        bottom: isLast ? Radius.circular(AppConstants.cardRadius) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: AppConstants.textMutedColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppConstants.textMutedColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppConstants.accentColor,
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'Light Mode';
      case AppTheme.monochrome:
        return 'Monochrome';
      case AppTheme.dark:
        return 'Dark Mode';
      case AppTheme.system:
        return 'System Default';
    }
  }

  void _showThemeSelectionDialog(BuildContext context) {
    final currentTheme = ThemeManager().currentTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.tertiaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.cardRadius),
        ),
      ),
      builder: (BuildContext dialogContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Theme',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...AppTheme.values.map((theme) {
                return ListTile(
                  title: Text(
                    _getThemeName(theme),
                    style: TextStyle(color: AppConstants.textColor),
                  ),
                  trailing: theme == currentTheme
                      ? Icon(Icons.check, color: AppConstants.accentColor)
                      : null,
                  onTap: () {
                    ThemeManager().setTheme(theme);
                    Navigator.pop(dialogContext);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _getListStyleName(AppListStyle style) {
    switch (style) {
      case AppListStyle.comfortable:
        return 'Comfortable';
      case AppListStyle.compact:
        return 'Compact';
      case AppListStyle.minimalList:
        return 'Minimal List';
      case AppListStyle.grid:
        return 'Grid';
    }
  }

  void _showListStyleSelectionDialog(BuildContext context) {
    final currentStyle = SettingsManager().currentListStyle;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.tertiaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.cardRadius),
        ),
      ),
      builder: (BuildContext dialogContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select List Style',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...AppListStyle.values.map((style) {
                return ListTile(
                  title: Text(
                    _getListStyleName(style),
                    style: TextStyle(color: AppConstants.textColor),
                  ),
                  trailing: style == currentStyle
                      ? Icon(Icons.check, color: AppConstants.accentColor)
                      : null,
                  onTap: () {
                    SettingsManager().setListStyle(style);
                    Navigator.pop(dialogContext);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

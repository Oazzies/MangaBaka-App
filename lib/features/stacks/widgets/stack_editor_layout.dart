import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_editor_controller.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_editor_details_pane.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_editor_entries_pane.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_series_picker.dart';

class StackEditorDesktopScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isNew;
  final bool loading;
  final LocalizationService l10n;
  final Widget body;
  final Widget? saveButton;
  final VoidCallback onDelete;
  final VoidCallback onSave;

  const StackEditorDesktopScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isNew,
    required this.loading,
    required this.l10n,
    required this.body,
    required this.saveButton,
    required this.onDelete,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.background,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopPageHeader(
          leading: DesktopIconButton(
            icon: Icons.close_rounded,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: title,
          subtitle: subtitle,
          actions: [
            if (!isNew)
              DesktopPillButton(
                label: l10n.translate('stacks_delete'),
                icon: Icons.delete_outline_rounded,
                danger: true,
                onPressed: onDelete,
              ),
            saveButton ??
                DesktopPillButton(
                  label: l10n.translate('save'),
                  icon: Icons.check_rounded,
                  primary: true,
                  onPressed: loading ? null : onSave,
                ),
          ],
        ),
        Expanded(child: body),
      ],
    ),
  );
}

class StackEditorMobileScaffold extends StatelessWidget {
  final String title;
  final bool loading;
  final LocalizationService l10n;
  final Widget body;
  final Widget? saveButton;
  final VoidCallback onSave;

  const StackEditorMobileScaffold({
    super.key,
    required this.title,
    required this.loading,
    required this.l10n,
    required this.body,
    required this.saveButton,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.background,
    appBar: mbScreenAppBar(
      title: title,
      actions: [
        saveButton ??
            TextButton(
              onPressed: loading ? null : onSave,
              child: Text(
                l10n.translate('save'),
                style: AppTypography.sans(
                  color: context.colors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
      ],
    ),
    body: body,
  );
}

class StackEditorTabbedLayout extends StatelessWidget {
  final TabController tabs;
  final StackEditorController controller;
  final LocalizationService l10n;
  final bool showErrors;
  final VoidCallback onDelete;
  final VoidCallback onAdd;
  final ValueChanged<int> onEditNote;
  final ValueChanged<int> onReplaceMerged;

  const StackEditorTabbedLayout({
    super.key,
    required this.tabs,
    required this.controller,
    required this.l10n,
    required this.showErrors,
    required this.onDelete,
    required this.onAdd,
    required this.onEditNote,
    required this.onReplaceMerged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        TabBar(
          controller: tabs,
          labelColor: c.text,
          unselectedLabelColor: c.textMuted,
          indicatorColor: c.accent,
          dividerColor: c.border,
          tabs: [
            Tab(text: l10n.translate('stacks_tab_details')),
            Tab(
              text: l10n
                  .translate('stacks_tab_series')
                  .replaceAll('{n}', '${controller.entries.length}'),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.horizontalPadding),
                child: StackEditorDetailsPane(
                  controller: controller,
                  l10n: l10n,
                  showErrors: showErrors,
                  onDelete: onDelete,
                ),
              ),
              StackEditorEntriesPane(
                controller: controller,
                l10n: l10n,
                pad: AppConstants.horizontalPadding,
                onAdd: onAdd,
                onEditNote: onEditNote,
                onReplaceMerged: onReplaceMerged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StackEditorSplitLayout extends StatelessWidget {
  final StackEditorController controller;
  final LocalizationService l10n;
  final bool showErrors;
  final bool withSearch;
  final VoidCallback onDelete;
  final VoidCallback onAdd;
  final ValueChanged<int> onEditNote;
  final ValueChanged<int> onReplaceMerged;
  final ValueChanged<Series> onToggleSeries;

  const StackEditorSplitLayout({
    super.key,
    required this.controller,
    required this.l10n,
    required this.showErrors,
    required this.withSearch,
    required this.onDelete,
    required this.onAdd,
    required this.onEditNote,
    required this.onReplaceMerged,
    required this.onToggleSeries,
  });

  @override
  Widget build(BuildContext context) {
    final desktop = DesktopLayout.isActive(context);
    final pad = desktop
        ? DesktopTokens.pagePadding
        : AppConstants.horizontalPadding;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: DesktopTokens.maxPageWidth),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 380,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(pad, 12, 12, 32),
                child: StackEditorDetailsPane(
                  controller: controller,
                  l10n: l10n,
                  showErrors: showErrors,
                  onDelete: onDelete,
                ),
              ),
            ),
            Expanded(
              child: StackEditorEntriesPane(
                controller: controller,
                l10n: l10n,
                pad: 12,
                showAdd: !withSearch,
                onAdd: onAdd,
                onEditNote: onEditNote,
                onReplaceMerged: onReplaceMerged,
              ),
            ),
            if (withSearch)
              SizedBox(
                width: 360,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 12, pad, 16),
                  child: DesktopCard(
                    padding: const EdgeInsets.all(14),
                    child: StackSeriesSearch(
                      isAdded: controller.containsSeries,
                      onToggle: onToggleSeries,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

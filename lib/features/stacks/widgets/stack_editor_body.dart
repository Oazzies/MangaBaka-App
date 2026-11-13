import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_editor_controller.dart';
import 'package:mangabaka_app/features/stacks/services/stack_exceptions.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_editor_layout.dart';

class StackEditorLoadError extends StatelessWidget {
  final Object error;
  final LocalizationService l10n;
  final VoidCallback onRetry;

  const StackEditorLoadError({
    super.key,
    required this.error,
    required this.l10n,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stackErrorMessage(error, l10n),
          textAlign: TextAlign.center,
          style: AppTypography.sans(color: context.colors.textMuted),
        ),
        TextButton(onPressed: onRetry, child: Text(l10n.translate('retry'))),
      ],
    ),
  );
}

class StackEditorBody extends StatelessWidget {
  static const double _splitWidth = 840;
  static const double _searchPanelWidth = 1320;

  final bool desktop;
  final StackEditorController controller;
  final TabController tabs;
  final LocalizationService l10n;
  final bool showErrors;
  final VoidCallback onDelete;
  final VoidCallback onAdd;
  final ValueChanged<int> onEditNote;
  final ValueChanged<int> onReplaceMerged;
  final ValueChanged<Series> onToggleSeries;

  const StackEditorBody({
    super.key,
    required this.desktop,
    required this.controller,
    required this.tabs,
    required this.l10n,
    required this.showErrors,
    required this.onDelete,
    required this.onAdd,
    required this.onEditNote,
    required this.onReplaceMerged,
    required this.onToggleSeries,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.loading) return const Center(child: MbSpinner());
    if (controller.loadError != null) {
      return StackEditorLoadError(
        error: controller.loadError!,
        l10n: l10n,
        onRetry: controller.load,
      );
    }
    return DerivedLayoutBuilder<int>(
      derive: (c) => c.maxWidth >= _searchPanelWidth && desktop
          ? 3
          : c.maxWidth >= _splitWidth
          ? 2
          : 1,
      builder: (context, columns) => switch (columns) {
        1 => StackEditorTabbedLayout(
          tabs: tabs,
          controller: controller,
          l10n: l10n,
          showErrors: showErrors,
          onDelete: onDelete,
          onAdd: onAdd,
          onEditNote: onEditNote,
          onReplaceMerged: onReplaceMerged,
        ),
        _ => StackEditorSplitLayout(
          controller: controller,
          l10n: l10n,
          showErrors: showErrors,
          withSearch: columns == 3,
          onDelete: onDelete,
          onAdd: onAdd,
          onEditNote: onEditNote,
          onReplaceMerged: onReplaceMerged,
          onToggleSeries: onToggleSeries,
        ),
      },
    );
  }
}

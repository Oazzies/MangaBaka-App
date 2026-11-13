import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/stacks/models/stack_detail.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_action_bar.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_detail_header.dart';

List<Widget> buildStackDetailTopActions(
  BuildContext context,
  StackSummary s, {
  required bool isOwner,
  required bool desktop,
  required LocalizationService l10n,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  required ValueChanged<StackVisibility> onSetVisibility,
}) {
  final c = context.colors;
  return [
    if (isOwner) ...[
      if (desktop)
        DesktopIconButton(
          icon: Icons.edit_rounded,
          tooltip: l10n.translate('stacks_edit'),
          onPressed: onEdit,
        )
      else
        IconButton(
          tooltip: l10n.translate('stacks_edit'),
          icon: Icon(Icons.edit_rounded, color: c.text),
          onPressed: onEdit,
        ),
      PopupMenuButton<String>(
        tooltip: l10n.translate('stacks_more_actions'),
        color: c.surface,
        icon: Icon(Icons.more_horiz_rounded, color: c.text),
        onSelected: (v) {
          switch (v) {
            case 'delete':
              onDelete();
            default:
              onSetVisibility(StackVisibility.parse(v));
          }
        },
        itemBuilder: (context) => [
          for (final v in StackVisibility.values)
            if (v != s.visibility)
              PopupMenuItem(
                value: v.apiValue,
                child: Text(l10n.translate('stacks_make_${v.name}')),
              ),
          PopupMenuItem(
            value: 'delete',
            child: Text(
              l10n.translate('stacks_delete'),
              style: TextStyle(color: c.error),
            ),
          ),
        ],
      ),
    ],
    ...stackBarActions(context, s, desktop: desktop),
  ];
}

class StackDetailOnePane extends StatelessWidget {
  final StackSummary summary;
  final StackDetail? detail;
  final bool isOwner;
  final Future<void> Function() onRefresh;
  final List<Widget> entries;

  const StackDetailOnePane({
    super.key,
    required this.summary,
    required this.detail,
    required this.isOwner,
    required this.onRefresh,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: context.colors.accent,
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.horizontalPadding,
              8,
              AppConstants.horizontalPadding,
              8,
            ),
            sliver: SliverToBoxAdapter(
              child: StackDetailHeader(
                summary: summary,
                detail: detail,
                isOwner: isOwner,
                stacked: true,
              ),
            ),
          ),
          ...entries,
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class StackDetailTwoPane extends StatelessWidget {
  static const double sideWidth = 360;

  final StackSummary summary;
  final StackDetail? detail;
  final bool isOwner;
  final Future<void> Function() onRefresh;
  final List<Widget> entries;

  const StackDetailTwoPane({
    super.key,
    required this.summary,
    required this.detail,
    required this.isOwner,
    required this.onRefresh,
    required this.entries,
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
              width: sideWidth,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(pad, 12, 12, 32),
                child: StackDetailHeader(
                  summary: summary,
                  detail: detail,
                  isOwner: isOwner,
                  stacked: false,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: context.colors.accent,
                onRefresh: onRefresh,
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    ...entries,
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

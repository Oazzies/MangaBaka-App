import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/network/paged_list.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/screens/stacks_list_screen.dart';
import 'package:mangabaka_app/features/stacks/services/stack_exceptions.dart';
import 'package:mangabaka_app/features/stacks/widgets/stacks_grid.dart';

/// Builds the "Newest stacks" header and grid slivers for [StacksHubScreen].
List<Widget> buildStacksHubNewestSlivers(
  BuildContext context, {
  required bool desktop,
  required double pad,
  required Future<PagedList<StackSummary>> newest,
  required LocalizationService l10n,
  required VoidCallback onRetry,
}) => [
  SliverPadding(
    padding: EdgeInsets.fromLTRB(desktop ? pad : 0, 0, desktop ? pad : 0, 0),
    sliver: SliverToBoxAdapter(
      child: desktop
          ? DesktopSectionTitle(
              title: l10n.translate('stacks_new'),
              trailing: DesktopPillButton(
                label: l10n.translate('view_all'),
                onPressed: () => StacksListScreen.open(
                  context,
                  const StacksListSource.newest(),
                ),
              ),
            )
          : MbSectionHeader(
              title: l10n.translate('stacks_new'),
              onAction: () => StacksListScreen.open(
                context,
                const StacksListSource.newest(),
              ),
            ),
    ),
  ),
  FutureBuilder<PagedList<StackSummary>>(
    future: newest,
    builder: (context, snap) {
      if (snap.hasError) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  stackErrorMessage(snap.error!, l10n),
                  textAlign: TextAlign.center,
                  style: AppTypography.sans(
                    color: context.colors.textMuted,
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  child: Text(l10n.translate('retry')),
                ),
              ],
            ),
          ),
        );
      }
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: pad),
        sliver: SliverStackGrid(
          stacks: snap.data?.items ?? const [],
          loading: snap.connectionState != ConnectionState.done,
        ),
      );
    },
  ),
];

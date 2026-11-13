import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_progress_bar.dart';
import 'package:mangabaka_app/features/series/widgets/description_section.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_status_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_detail.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/screens/stacks_list_screen.dart';
import 'package:mangabaka_app/features/stacks/utils/stack_format.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_action_bar.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_auth_gate.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_card.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_cover_fan.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_detail_components.dart';

/// Title, author, counts, actions, description and library progress.
///
/// [stacked] lays the fan beside the title (phone portrait); otherwise the
/// fan sits on top of the side column.
class StackDetailHeader extends StatelessWidget {
  final StackSummary summary;
  final StackDetail? detail;
  final bool isOwner;
  final bool stacked;

  const StackDetailHeader({
    super.key,
    required this.summary,
    required this.detail,
    required this.isOwner,
    required this.stacked,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    final title = Text(
      summary.title,
      style: AppTypography.sans(
        color: c.text,
        fontSize: stacked ? 22 : 24,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
    );

    final owner = summary.owner;
    final updated = stackTimeAgo(summary.updatedAt, l10n);
    final meta = Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (owner.display.isNotEmpty)
          GestureDetector(
            onTap: owner.username == null
                ? null
                : () => StacksListScreen.open(
                    context,
                    StacksListSource.user(owner.username!, owner.display),
                  ),
            child: Text(
              l10n.translate('stacks_by').replaceAll('{name}', owner.display),
              style: AppTypography.sans(
                color: owner.username == null ? c.textMuted : c.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        _dot(c),
        Text(
          stackCount('entries', summary.entryCount, l10n),
          style: _metaStyle(c),
        ),
        if (updated.isNotEmpty) ...[
          _dot(c),
          Text(
            l10n.translate('stacks_updated').replaceAll('{when}', updated),
            style: _metaStyle(c),
          ),
        ],
      ],
    );

    final badges = <Widget>[
      if (summary.isFeatured)
        StackBadge(
          icon: Icons.star_rounded,
          label: l10n.translate('stacks_badge_featured'),
          color: c.star,
        ),
      if (summary.kind == StackKind.official)
        StackBadge(
          icon: Icons.verified_rounded,
          label: l10n.translate('stacks_badge_official'),
          color: c.accent,
        ),
      if (summary.isSpoiler)
        StackBadge(
          icon: Icons.visibility_off_rounded,
          label: l10n.translate('stacks_badge_spoiler'),
          color: c.warning,
        ),
      if (isOwner)
        StackBadge(
          icon: switch (summary.visibility) {
            StackVisibility.draft => Icons.edit_note_rounded,
            StackVisibility.unlisted => Icons.link_rounded,
            StackVisibility.public => Icons.public_rounded,
          },
          label: l10n.translate(summary.visibility.labelKey),
          color: c.info,
        ),
      if (isOwner && (detail?.isHidden ?? false))
        StackBadge(
          icon: Icons.block_rounded,
          label: l10n.translate('stacks_badge_hidden'),
          color: c.error,
        ),
      if (isOwner && (detail?.isDelisted ?? false))
        StackBadge(
          icon: Icons.visibility_off_outlined,
          label: l10n.translate('stacks_badge_delisted'),
          color: c.warning,
        ),
    ];

    final fan = StackCoverFan(
      covers: summary.covers,
      contentRating: summary.contentRating,
    );

    final description = detail?.description;
    final draftHint =
        isOwner &&
        summary.visibility == StackVisibility.draft &&
        detail != null &&
        detail!.liveEntries.length < StackLimits.publishMin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stacked)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 108, child: fan),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 8), meta],
                ),
              ),
            ],
          )
        else ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: fan,
          ),
          const SizedBox(height: 18),
          title,
          const SizedBox(height: 8),
          meta,
        ],
        if (badges.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: badges),
        ],
        const SizedBox(height: 16),
        StackActionBar(
          stack: summary,
          commentsEnabled: detail?.isCommentsEnabled ?? true,
        ),
        if (draftHint) ...[
          const SizedBox(height: 14),
          StackDetailHint(
            icon: Icons.info_outline_rounded,
            text: l10n
                .translate('stacks_publish_needs')
                .replaceAll('{n}', '${StackLimits.publishMin}'),
          ),
        ],
        if (detail != null) ...[
          const SizedBox(height: 14),
          StackLibraryProgress(
            stackId: summary.id,
            total: detail!.liveEntries.length,
          ),
        ],
        if (description != null) ...[
          const SizedBox(height: 18),
          DescriptionSection(
            description: stackMarkdown(description),
            expandIfFits: !stacked,
          ),
        ],
      ],
    );
  }

  static TextStyle _metaStyle(MbPalette c) =>
      AppTypography.sans(color: c.textMuted, fontSize: 13);

  static Widget _dot(MbPalette c) =>
      Text('·', style: AppTypography.sans(color: c.textMuted, fontSize: 13));
}

/// "4 of 10 in your library", from the live status; a sign-in nudge when
/// signed out.
class StackLibraryProgress extends StatelessWidget {
  final int stackId;
  final int total;

  const StackLibraryProgress({
    super.key,
    required this.stackId,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    final access = stackAccess();
    if (access != StackAccess.ready) {
      return Text(
        l10n.translate(
          access == StackAccess.signedOut
              ? 'stacks_library_sign_in'
              : 'stacks_library_reconnect',
        ),
        style: AppTypography.sans(color: c.textMuted, fontSize: 13),
      );
    }
    final controller = getIt<StackStatusController>();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final status = controller.of(stackId);
        if (status == null || total == 0) return const SizedBox.shrink();
        final have = status.libraryCount.clamp(0, total);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n
                  .translate('stacks_library_progress')
                  .replaceAll('{n}', '$have')
                  .replaceAll('{total}', '$total'),
              style: AppTypography.sans(
                color: c.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            MbProgressBar(value: have / total),
          ],
        );
      },
    );
  }
}

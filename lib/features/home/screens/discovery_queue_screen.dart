import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_cover.dart';
import 'package:mangabaka_app/core/widgets/design/mb_rating_stars.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/home/controllers/discovery_queue_controller.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Interactive Discovery Queue screen.
///
/// Lets the user step through personalised series recommendations one-by-one,
/// adding them to their library or skipping to the next.
class DiscoveryQueueScreen extends StatefulWidget {
  final DiscoveryQueueController? controller;

  const DiscoveryQueueScreen({super.key, this.controller});

  @override
  State<DiscoveryQueueScreen> createState() => _DiscoveryQueueScreenState();
}

class _DiscoveryQueueScreenState extends State<DiscoveryQueueScreen> {
  late final DiscoveryQueueController _controller;
  bool _ownsController = false;

  static const List<String> _libraryStates = [
    'plan_to_read',
    'reading',
    'considering',
    'completed',
    'paused',
    'dropped',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = DiscoveryQueueController();
      _ownsController = true;
      _controller.loadQueue();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _openSeriesDetail(Series series) {
    Navigator.of(
      context,
    ).push(AppTransitions.slideRight(SeriesDetailScreen(series: series)));
  }

  Future<void> _addWithState(String state) async {
    final l10n = LocalizationService();
    try {
      final success = await _controller.addToLibrary(state);
      if (success && mounted) {
        AppSnackBar.show(context, l10n.translate('added_to_library'));
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(
          context,
          l10n.translate('failed_to_add'),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = DesktopLayout.isActive(context);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): () {
          if (!_controller.isLoading && !_controller.isCompleted) {
            _controller.skip();
          }
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight): () {
          if (!_controller.isLoading && !_controller.isCompleted) {
            _controller.skip();
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: context.colors.background,
          appBar: isDesktop
              ? null
              : mbScreenAppBar(
                  title: LocalizationService().translate('discovery_queue'),
                ),
          body: SafeArea(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => _buildBody(context, isDesktop),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDesktop) {
    final l10n = LocalizationService();

    if (_controller.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.accent),
      );
    }

    if (!_controller.isReady) {
      return _buildNotReadyState(l10n, isDesktop);
    }

    if (_controller.errorMessage != null && _controller.queue.isEmpty) {
      return _buildErrorState(l10n, isDesktop);
    }

    if (_controller.queue.isEmpty) {
      return _buildEmptyState(l10n, isDesktop);
    }

    if (_controller.isCompleted) {
      return _buildCompletedState(l10n, isDesktop);
    }

    final series = _controller.currentSeries;
    if (series == null) {
      return _buildEmptyState(l10n, isDesktop);
    }

    return isDesktop
        ? _buildDesktopView(context, series, l10n)
        : _buildMobileView(context, series, l10n);
  }

  // ─── States ───────────────────────────────────────────────────────────────

  Widget _buildNotReadyState(LocalizationService l10n, bool isDesktop) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 64,
                color: context.colors.accent,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.translate('discovery_queue').toUpperCase(),
                style: AppTypography.display(
                  color: context.colors.text,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.translate('discovery_queue_not_ready'),
                style: AppTypography.sans(
                  color: context.colors.textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(l10n.translate('back')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(LocalizationService l10n, bool isDesktop) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.explore_off_outlined,
                size: 64,
                color: context.colors.textMuted,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.translate('discovery_queue_empty'),
                style: AppTypography.sans(
                  color: context.colors.textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _controller.restart,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.translate('retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(LocalizationService l10n, bool isDesktop) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: context.colors.error,
              ),
              const SizedBox(height: 20),
              Text(
                _controller.errorMessage ?? l10n.translate('error_loading'),
                style: AppTypography.sans(
                  color: context.colors.textMuted,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _controller.restart,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.translate('retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedState(LocalizationService l10n, bool isDesktop) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.accent.withValues(alpha: 0.15),
                ),
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 48,
                  color: context.colors.accent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.translate('discovery_queue_complete_title').toUpperCase(),
                style: AppTypography.display(
                  color: context.colors.text,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n
                    .translate('discovery_queue_complete_message')
                    .replaceAll('{reviewed}', '${_controller.reviewedCount}')
                    .replaceAll('{added}', '${_controller.addedCount}'),
                style: AppTypography.sans(
                  color: context.colors.textMuted,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(l10n.translate('done')),
                  ),
                  FilledButton.icon(
                    onPressed: _controller.restart,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      l10n.translate('discovery_queue_start_another'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Desktop View ─────────────────────────────────────────────────────────

  Widget _buildDesktopView(
    BuildContext context,
    Series series,
    LocalizationService l10n,
  ) {
    final titleLang = SettingsManager().defaultTitleLanguage;
    final displayTitle = series.getDisplayTitle(titleLang);
    final secondaryTitle =
        series.romanizedTitle.isNotEmpty &&
            series.romanizedTitle != displayTitle
        ? series.romanizedTitle
        : (series.nativeTitle.isNotEmpty && series.nativeTitle != displayTitle
              ? series.nativeTitle
              : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopPageHeader(
          title: l10n.translate('discovery_queue'),
          subtitle: l10n
              .translate('discovery_queue_progress')
              .replaceAll('{current}', '${_controller.currentIndex + 1}')
              .replaceAll('{total}', '${_controller.totalCount}')
              .replaceAll('{remaining}', '${_controller.remainingCount}'),
          leading: DesktopIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: l10n.translate('back'),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            DesktopPillButton(
              label: l10n.translate('discovery_queue_skip'),
              icon: Icons.skip_next_rounded,
              onPressed: _controller.skip,
            ),
          ],
        ),
        LinearProgressIndicator(
          value: _controller.progress,
          color: context.colors.accent,
          backgroundColor: context.colors.surfaceRaised,
          minHeight: 3,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesktopTokens.pagePadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: DesktopCard(
                  padding: const EdgeInsets.all(28),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover
                      GestureDetector(
                        onTap: () => _openSeriesDetail(series),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: MbCover(
                            url: series.coverUrl,
                            width: 200,
                            radius: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 28),
                      // Details & Actions
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _openSeriesDetail(series),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Text(
                                  displayTitle,
                                  style: AppTypography.display(
                                    color: context.colors.text,
                                    fontSize: 24,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            if (secondaryTitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                secondaryTitle,
                                style: AppTypography.sans(
                                  color: context.colors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            _buildMetadataChips(series),
                            const SizedBox(height: 12),
                            _buildGenreTags(series),
                            const SizedBox(height: 16),
                            if (series.description.isNotEmpty) ...[
                              Text(
                                series.description,
                                maxLines: 6,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.sans(
                                  color: context.colors.text.withValues(
                                    alpha: 0.85,
                                  ),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                            _buildActionButtons(l10n),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Mobile View ──────────────────────────────────────────────────────────

  Widget _buildMobileView(
    BuildContext context,
    Series series,
    LocalizationService l10n,
  ) {
    final titleLang = SettingsManager().defaultTitleLanguage;
    final displayTitle = series.getDisplayTitle(titleLang);

    return Column(
      children: [
        LinearProgressIndicator(
          value: _controller.progress,
          color: context.colors.accent,
          backgroundColor: context.colors.surfaceRaised,
          minHeight: 3,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            l10n
                .translate('discovery_queue_progress')
                .replaceAll('{current}', '${_controller.currentIndex + 1}')
                .replaceAll('{total}', '${_controller.totalCount}')
                .replaceAll('{remaining}', '${_controller.remainingCount}'),
            style: AppTypography.monoLabel(
              color: context.colors.textMuted,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: WidgetUtils.responsiveConstraint(
            maxWidth: 600,
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () => _openSeriesDetail(series),
                    child: MbCover(
                      url: series.coverUrl,
                      width: 160,
                      radius: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => _openSeriesDetail(series),
                    child: Text(
                      displayTitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.display(
                        color: context.colors.text,
                        fontSize: 20,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: _buildMetadataChips(series)),
                const SizedBox(height: 10),
                Center(child: _buildGenreTags(series)),
                if (series.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    series.description,
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      color: context.colors.text.withValues(alpha: 0.85),
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _buildActionButtons(l10n),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Shared Components ────────────────────────────────────────────────────

  Widget _buildMetadataChips(Series series) {
    final double? ratingScore = double.tryParse(series.rating);

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (series.type.isNotEmpty)
          _chip(series.type.toUpperCase(), context.colors.accent),
        if (series.status.isNotEmpty)
          _chip(series.status.toUpperCase(), context.colors.textMuted),
        if (ratingScore != null && ratingScore > 0)
          MbRatingStars(rating: ratingScore, fontSize: 13),
      ],
    );
  }

  Widget _buildGenreTags(Series series) {
    final tags = [...series.genres, ...series.tags].take(6).toList();
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: context.colors.border),
            ),
            child: Text(
              tag,
              style: AppTypography.sans(
                color: context.colors.textMuted,
                fontSize: 11.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(LocalizationService l10n) {
    final defaultTab = SettingsManager().addLibraryDefaultTab;
    final inProgress = _controller.isActionInProgress;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: inProgress ? null : _controller.skip,
            icon: const Icon(Icons.skip_next_rounded, size: 18),
            label: Text(l10n.translate('discovery_queue_skip').toUpperCase()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: FilledButton.icon(
            onPressed: inProgress ? null : () => _addWithState(defaultTab),
            icon: inProgress
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colors.onAccent,
                    ),
                  )
                : const Icon(Icons.bookmark_add_outlined, size: 18),
            label: Text(
              '+ ${l10n.translate(defaultTab)}'.toUpperCase(),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.arrow_drop_down_rounded),
          tooltip: l10n.translate('import_add_as'),
          color: context.colors.surface,
          onSelected: (state) => _addWithState(state),
          itemBuilder: (context) => [
            for (final s in _libraryStates)
              PopupMenuItem(
                value: s,
                child: Text(
                  l10n.translate(s),
                  style: AppTypography.sans(color: context.colors.text),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppConstants.pillRadius),
    ),
    child: Text(
      label,
      style: AppTypography.monoLabel(color: color, fontSize: 10.5),
    ),
  );
}

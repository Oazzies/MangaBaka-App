import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/widgets/beside_or_below.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/home/controllers/discovery_queue_controller.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/widgets/mb_card.dart';

/// Interactive Discovery Queue screen.
///
/// Steps through personalised series recommendations one-by-one, showing the
/// full series detail page for each and a pinned control bar with quick add,
/// skip and "not interested".
class DiscoveryQueueScreen extends StatefulWidget {
  final DiscoveryQueueController? controller;

  /// Overrides the embedded series preview. Defaults to the live series detail
  /// page; tests inject a light placeholder so the queue can be exercised
  /// without standing up the whole detail screen.
  final Widget Function(BuildContext context, Series series)? previewBuilder;

  const DiscoveryQueueScreen({super.key, this.controller, this.previewBuilder});

  @override
  State<DiscoveryQueueScreen> createState() => _DiscoveryQueueScreenState();
}

class _DiscoveryQueueScreenState extends State<DiscoveryQueueScreen> {
  late final DiscoveryQueueController _controller;
  bool _ownsController = false;

  /// Library state the add button currently targets. Changed only via the
  /// dropdown attached to the button — never applied until the button is
  /// pressed.
  late String _selectedState;

  static const List<String> _libraryStates = [
    'plan_to_read',
    'reading',
    'considering',
    'completed',
    'paused',
    'dropped',
  ];

  /// Above this width the controls are placed in the detail page's wide-layout
  /// right rail (scrolling with the page) instead of the floating top card.
  static const double _sidebarBreakpoint = 1200;

  @override
  void initState() {
    super.initState();
    _selectedState = SettingsManager().addLibraryDefaultTab;
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
      return const Center(
        child: MbSpinner(),
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

    return _buildQueueView(context, series, isDesktop, l10n);
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

  // ─── Queue View ───────────────────────────────────────────────────────────

  Widget _buildQueueView(
    BuildContext context,
    Series series,
    bool isDesktop,
    LocalizationService l10n,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showRail = constraints.maxWidth >= _sidebarBreakpoint;

        final preview =
            widget.previewBuilder?.call(context, series) ??
            SeriesDetailScreen(
              key: ValueKey(series.id),
              series: series,
              embedded: true,
              heroTagPrefix: 'discovery_queue_${series.id}',
              rightRail: showRail ? _buildControlCard(l10n) : null,
            );

        // With the rail, the controls live inside the detail page's scrolling
        // wide layout; otherwise they float over the preview — at the bottom on
        // phones, at the top on narrow desktop windows.
        final atBottom = !isDesktop;
        final content = showRail
            ? preview
            : Stack(
                children: [
                  Positioned.fill(child: preview),
                  Positioned(
                    top: atBottom ? null : 0,
                    bottom: atBottom ? 0 : null,
                    left: 0,
                    right: 0,
                    child: _buildControlBar(
                      l10n,
                      isDesktop,
                      atBottom: atBottom,
                    ),
                  ),
                ],
              );

        if (!isDesktop) return content;

        return Column(
          children: [
            DesktopPageHeader(
              title: l10n.translate('discovery_queue'),
              leading: DesktopIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: l10n.translate('back'),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(child: content),
          ],
        );
      },
    );
  }

  Widget _buildControlCard(LocalizationService l10n) {
    final counter =
        '${_controller.currentIndex + 1} / ${_controller.totalCount}';

    return MbCard(
      label: l10n.translate('discovery_queue'),
      trailing: _buildCounterPill(counter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _controller.progress,
              color: context.colors.accent,
              backgroundColor: context.colors.surfaceRaised,
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 18),
          _buildAddButton(),
          const SizedBox(height: 12),
          _buildSkipButton(l10n, expand: true),
          const SizedBox(height: 12),
          _buildNotInterestedButton(l10n, expand: true),
        ],
      ),
    );
  }

  Widget _buildCounterPill(String counter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: context.colors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      ),
      child: Text(
        counter,
        style: AppTypography.monoLabel(
          color: context.colors.textMuted,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildControlBar(
    LocalizationService l10n,
    bool isDesktop, {
    bool atBottom = false,
  }) {
    final horizontal = isDesktop ? DesktopTokens.pagePadding : 12.0;
    final counter =
        '${_controller.currentIndex + 1} / ${_controller.totalCount}';

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: atBottom
              ? Border.all(color: context.colors.border, width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: context.colors.shadowAt(0.35),
              blurRadius: 16,
              offset: Offset(0, atBottom ? -6 : 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BesideOrBelow(
              minBodyWidth: 140,
              gap: 10,
              stackGap: 8,
              body: Text(
                l10n.translate('discovery_queue').toUpperCase(),
                style: AppTypography.display(
                  color: context.colors.text,
                  fontSize: 14,
                ),
              ),
              trailing: _buildCounterPill(counter),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _controller.progress,
                color: context.colors.accent,
                backgroundColor: context.colors.surfaceRaised,
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 12),
            _buildAddButton(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildSkipButton(l10n, expand: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildNotInterestedButton(l10n, expand: true)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton({bool expand = true}) {
    return _AddToLibraryButton(
      selectedState: _selectedState,
      states: _libraryStates,
      expand: expand,
      busy: _controller.isActionInProgress,
      onAdd: _controller.isActionInProgress
          ? null
          : () => _addWithState(_selectedState),
      onStateSelected: (state) => setState(() => _selectedState = state),
    );
  }

  Widget _buildSkipButton(LocalizationService l10n, {bool expand = true}) {
    return MbSecondaryButton(
      label: l10n.translate('discovery_queue_skip'),
      icon: Icons.skip_next_rounded,
      onPressed: _controller.isActionInProgress ? null : _controller.skip,
      expand: expand,
    );
  }

  Widget _buildNotInterestedButton(
    LocalizationService l10n, {
    bool expand = true,
  }) {
    return MbSecondaryButton(
      label: l10n.translate('discovery_queue_not_interested'),
      icon: Icons.thumb_down_alt_outlined,
      onPressed: _controller.isActionInProgress
          ? null
          : _controller.markNotInterested,
      expand: expand,
    );
  }
}

/// Primary "add to library" pill with an attached dropdown for choosing the
/// target state. The dropdown only changes the button's label; the state is
/// applied when the main button is pressed.
class _AddToLibraryButton extends StatelessWidget {
  final String selectedState;
  final List<String> states;
  final ValueChanged<String> onStateSelected;
  final VoidCallback? onAdd;
  final bool busy;
  final bool expand;

  const _AddToLibraryButton({
    required this.selectedState,
    required this.states,
    required this.onStateSelected,
    required this.onAdd,
    this.busy = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final enabled = onAdd != null && !busy;
    final bg = enabled
        ? context.colors.accent
        : context.colors.accent.withValues(alpha: 0.35);
    final fg = context.colors.onAccent;

    final addSection = MbTappable(
      onTap: enabled ? onAdd : null,
      pressedScale: 0.975,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              MbSpinner(
                size: 16,
                strokeWidth: 2,
                color: fg,
              ),
            if (busy) const SizedBox(width: 10),
            Flexible(
              child: Text(
                '+ ${l10n.translate(selectedState)}'.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: AppTypography.display(color: fg, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );

    final menuSection = PopupMenuButton<String>(
      enabled: !busy,
      tooltip: l10n.translate('import_add_as'),
      color: context.colors.surface,
      padding: EdgeInsets.zero,
      onSelected: onStateSelected,
      itemBuilder: (context) => [
        for (final state in states)
          PopupMenuItem(
            value: state,
            child: Text(
              l10n.translate(state),
              style: AppTypography.sans(color: context.colors.text),
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: Icon(Icons.arrow_drop_down_rounded, size: 22, color: fg),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      child: ColoredBox(
        color: bg,
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (expand) Expanded(child: addSection) else addSection,
            Container(width: 1, height: 24, color: fg.withValues(alpha: 0.3)),
            menuSection,
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/home/controllers/discovery_queue_controller.dart';
import 'package:mangabaka_app/features/home/widgets/discovery_queue_controls.dart';
import 'package:mangabaka_app/features/home/widgets/discovery_queue_states.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';

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
    } catch (e, st) {
      LoggingService.logger.warning(
        'Failed to add discovery queue series to library',
        e,
        st,
      );
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
      return const Center(child: MbSpinner());
    }

    if (!_controller.isReady) {
      return DiscoveryQueueNotReadyState(l10n: l10n);
    }

    if (_controller.errorMessage != null && _controller.queue.isEmpty) {
      return DiscoveryQueueErrorState(
        l10n: l10n,
        messageKey: _controller.errorMessage!,
        onRestart: _controller.restart,
      );
    }

    if (_controller.queue.isEmpty) {
      return DiscoveryQueueEmptyState(
        l10n: l10n,
        onRestart: _controller.restart,
      );
    }

    if (_controller.isCompleted) {
      return DiscoveryQueueCompletedState(
        l10n: l10n,
        reviewedCount: _controller.reviewedCount,
        addedCount: _controller.addedCount,
        onRestart: _controller.restart,
      );
    }

    final series = _controller.currentSeries;
    if (series == null) {
      return DiscoveryQueueEmptyState(
        l10n: l10n,
        onRestart: _controller.restart,
      );
    }

    return _buildQueueView(context, series, isDesktop, l10n);
  }

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
              rightRail: showRail
                  ? DiscoveryQueueControlCard(
                      l10n: l10n,
                      currentIndex: _controller.currentIndex,
                      totalCount: _controller.totalCount,
                      progress: _controller.progress,
                      selectedState: _selectedState,
                      states: _libraryStates,
                      busy: _controller.isActionInProgress,
                      onAdd: () => _addWithState(_selectedState),
                      onStateSelected: (state) =>
                          setState(() => _selectedState = state),
                      onSkip: _controller.skip,
                      onNotInterested: _controller.markNotInterested,
                    )
                  : null,
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
                    child: DiscoveryQueueControlBar(
                      l10n: l10n,
                      isDesktop: isDesktop,
                      atBottom: atBottom,
                      currentIndex: _controller.currentIndex,
                      totalCount: _controller.totalCount,
                      progress: _controller.progress,
                      selectedState: _selectedState,
                      states: _libraryStates,
                      busy: _controller.isActionInProgress,
                      onAdd: () => _addWithState(_selectedState),
                      onStateSelected: (state) =>
                          setState(() => _selectedState = state),
                      onSkip: _controller.skip,
                      onNotInterested: _controller.markNotInterested,
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
}

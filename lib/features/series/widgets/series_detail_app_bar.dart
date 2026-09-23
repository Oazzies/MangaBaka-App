import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/app_bar/glass_control.dart';
import 'package:mangabaka_app/features/series/widgets/app_bar/series_app_bar_metrics.dart';
import 'package:mangabaka_app/features/series/widgets/app_bar/series_banner_background.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Banner hero for the series detail page: a full-bleed blurred cover that
/// fades into the page background, with the cover artwork and serif title
/// block floating at its base, plus a glass "Back" pill and share / delete
/// controls. The remaining content (tabs, cards, synopsis) lives below.
///
/// Stateful only to know when the route transition has settled — both the
/// banner blur and the controls' backdrop filters are held off until then, so
/// they never compete with the slide for frames.
class SeriesDetailAppBar extends StatefulWidget {
  final Series series;
  final String title;
  final LibraryEntry? entry;
  final bool isWide;
  final bool embedded;
  final bool showCover;
  final double horizontalPadding;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final Function(String) onCopy;
  final String? heroTagPrefix;

  const SeriesDetailAppBar({
    super.key,
    required this.series,
    required this.title,
    this.entry,
    required this.isWide,
    this.embedded = false,
    this.showCover = true,
    this.horizontalPadding = 16.0,
    required this.onBack,
    required this.onShare,
    required this.onDelete,
    required this.onCopy,
    this.heroTagPrefix,
  });

  @override
  State<SeriesDetailAppBar> createState() => _SeriesDetailAppBarState();
}

class _SeriesDetailAppBarState extends State<SeriesDetailAppBar> {
  bool _transitionComplete = false;
  bool _listenerAdded = false;
  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_listenerAdded) return;
    _listenerAdded = true;

    _routeAnimation = ModalRoute.of(context)?.animation;
    final animation = _routeAnimation;
    if (animation == null || animation.isCompleted) {
      // Pushed without a transition, or it has already finished.
      _transitionComplete = true;
      return;
    }
    animation.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _routeAnimation?.removeStatusListener(_onStatus);
    if (!mounted) return;
    setState(() => _transitionComplete = true);
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final metrics = SeriesAppBarMetrics(
          isWide: widget.isWide,
          isLandscape: isLandscape,
          layoutWidth: constraints.crossAxisExtent,
          scrollOffset: constraints.scrollOffset,
          horizontalPadding: widget.horizontalPadding,
          hasEntry: widget.entry != null,
        );

        return SliverAppBar(
          expandedHeight: metrics.expandedHeight,
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: context.colors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: widget.embedded ? 0 : metrics.leadingWidth,
          leading: widget.embedded ? null : _buildBackButton(metrics),
          actions: _buildActions(metrics),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: EdgeInsetsDirectional.only(
              start: metrics.titleStartPadding,
              bottom: 16,
              end: metrics.titleEndPadding,
            ),
            centerTitle: false,
            title: _buildCollapsedTitle(metrics),
            background: SeriesBannerBackground(
              series: widget.series,
              title: widget.title,
              isWide: widget.isWide,
              showCover: widget.showCover,
              horizontalPadding: widget.horizontalPadding,
              coverHeight: metrics.coverHeight,
              coverWidth: metrics.coverWidth,
              transitionComplete: _transitionComplete,
              heroTagPrefix: widget.heroTagPrefix,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackButton(SeriesAppBarMetrics metrics) {
    final l10n = LocalizationService();
    return Padding(
      padding: EdgeInsets.only(
        left: widget.horizontalPadding + metrics.horizontalMargin,
        top: 6,
        bottom: 6,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AppTooltip(
          message: l10n.translate('go_back'),
          child: GlassControl(
            onTap: widget.onBack,
            icon: Icons.arrow_back,
            // Labelled in both orientations, per the design.
            label: l10n.translate('back'),
            showBg: metrics.controlsNeedBackground,
            blurEnabled: _transitionComplete,
          ).animate().fadeIn(duration: 400.ms),
        ),
      ),
    );
  }

  List<Widget> _buildActions(SeriesAppBarMetrics metrics) {
    // Embedded in a host that floats its own controls over the banner, so the
    // banner carries only the blurred background.
    if (widget.embedded) return const [];

    // Wide portrait puts share and delete in the layout below instead, so the
    // banner carries only the trailing inset that keeps the title clear.
    if (!metrics.showsBannerActions) {
      return [
        Padding(
          padding: EdgeInsets.only(right: metrics.horizontalMargin + 16),
          child: const SizedBox(width: 16),
        ),
      ];
    }

    final l10n = LocalizationService();
    return [
      AppTooltip(
        message: l10n.translate('share_series'),
        child: _actionIcon(
          icon: Icons.share_outlined,
          onTap: widget.onShare,
          metrics: metrics,
          // Staggered behind the back pill so the controls arrive in reading
          // order rather than all at once.
          delay: 80.ms,
        ),
      ),
      // Nothing to delete unless the series is in the library.
      if (widget.entry != null) ...[
        const SizedBox(width: 8),
        AppTooltip(
          message: l10n.translate('delete_from_library'),
          child: _actionIcon(
            icon: Icons.delete_outline,
            onTap: widget.onDelete,
            metrics: metrics,
            delay: 160.ms,
          ),
        ),
      ],
      Padding(
        padding: EdgeInsets.only(right: metrics.horizontalMargin + 8),
        child: const SizedBox(width: 8),
      ),
    ];
  }

  Widget _actionIcon({
    required IconData icon,
    required VoidCallback onTap,
    required SeriesAppBarMetrics metrics,
    required Duration delay,
  }) {
    return GlassControl(
      onTap: onTap,
      icon: icon,
      showBg: metrics.controlsNeedBackground,
      blurEnabled: _transitionComplete,
      size: 36,
      iconSize: 20,
    ).animate().fadeIn(delay: delay, duration: 400.ms);
  }

  Widget _buildCollapsedTitle(SeriesAppBarMetrics metrics) {
    return IgnorePointer(
      // Fully faded out it is still laid out, and would otherwise swallow taps
      // meant for the banner beneath it.
      ignoring: metrics.titleOpacity == 0,
      child: Opacity(
        opacity: metrics.titleOpacity,
        child: Text(
          widget.title,
          style: AppTypography.display(
            color: context.colors.text,
            fontWeight: FontWeight.w600,
            fontSize: 19,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

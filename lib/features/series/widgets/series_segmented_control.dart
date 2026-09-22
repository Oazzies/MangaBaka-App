import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class SeriesSegmentedControl extends StatefulWidget {
  final String selectedTab;
  final ValueChanged<String> onTabChanged;
  final double horizontalPadding;

  const SeriesSegmentedControl({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    this.horizontalPadding = 16.0,
  });

  static const tabs = [
    'Info',
    'Covers',
    'Related',
    'Similar',
    'News',
    'Collections',
    'Works',
  ];

  @override
  State<SeriesSegmentedControl> createState() => _SeriesSegmentedControlState();
}

class _SeriesSegmentedControlState extends State<SeriesSegmentedControl>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: SeriesSegmentedControl.tabs.length,
      vsync: this,
      initialIndex: _indexFor(widget.selectedTab),
    );
    _controller.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(covariant SeriesSegmentedControl old) {
    super.didUpdateWidget(old);
    final newIndex = _indexFor(widget.selectedTab);
    if (!_controller.indexIsChanging && _controller.index != newIndex) {
      _controller.animateTo(newIndex);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTabChanged);
    _controller.dispose();
    super.dispose();
  }

  int _indexFor(String tab) {
    final i = SeriesSegmentedControl.tabs.indexOf(tab);
    return i < 0 ? 0 : i;
  }

  void _onTabChanged() {
    if (!_controller.indexIsChanging) {
      widget.onTabChanged(SeriesSegmentedControl.tabs[_controller.index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Same pill strip as the library tabs, so a "one of many" choice looks
    // identical wherever it appears.
    return SelectionContainer.disabled(
      child: TabBar(
        controller: _controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        onTap: (index) {
          widget.onTabChanged(SeriesSegmentedControl.tabs[index]);
        },
        // The strip's own indicatorPadding already insets each pill by 5, so
        // the outer padding is reduced to match — clamped, because callers
        // (the wide layout) legitimately pass 0.
        padding: EdgeInsets.symmetric(
          horizontal: (widget.horizontalPadding - 5).clamp(0.0, 64.0),
        ),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: context.colors.accent,
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
        ),
        indicatorPadding: const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 6,
        ),
        labelPadding: EdgeInsets.zero,
        labelColor: context.colors.onAccent,
        unselectedLabelColor: context.colors.text,
        labelStyle: AppTypography.display(fontSize: 13),
        unselectedLabelStyle: AppTypography.display(fontSize: 13),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        tabs: SeriesSegmentedControl.tabs
            .map(
              (t) => Tab(
                height: 48,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(t.toUpperCase()),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

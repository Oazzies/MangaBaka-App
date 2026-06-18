import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';

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
    return SelectionContainer.disabled(
      child: TabBar(
        controller: _controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
        dividerColor: Colors.transparent,
        indicatorColor: AppConstants.accentColor,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 2,
        labelColor: AppConstants.textColor,
        unselectedLabelColor: AppConstants.textMutedColor,
        labelStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        tabs: SeriesSegmentedControl.tabs
            .map((t) => Tab(text: t, height: 44))
            .toList(),
      ),
    );
  }
}

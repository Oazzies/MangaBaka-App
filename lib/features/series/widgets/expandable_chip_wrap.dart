import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class ExpandableChipWrap extends StatefulWidget {
  final String label;
  final List<String> items;
  final Color? color;

  const ExpandableChipWrap({
    required this.label,
    required this.items,
    this.color,
    super.key,
  });

  @override
  State<ExpandableChipWrap> createState() => _ExpandableChipWrapState();
}

class _ExpandableChipWrapState extends State<ExpandableChipWrap> {
  bool _expanded = false;
  bool _needsExpansion = false;
  double _maxCollapsedHeight = 200.0;

  final GlobalKey _fullWrapKey = GlobalKey();
  final GlobalKey _singleChipKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateMetrics());
  }

  void _calculateMetrics() {
    if (!mounted) return;

    final RenderBox? fullBox =
        _fullWrapKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? singleBox =
        _singleChipKey.currentContext?.findRenderObject() as RenderBox?;

    if (fullBox != null && singleBox != null) {
      final double singleHeight = singleBox.size.height;
      final double fullHeight = fullBox.size.height;

      const double runSpacing = 8.0;
      final double fiveRowsHeight =
          (singleHeight * 5) + (runSpacing * 4) + 4; // +4 for a small buffer

      final bool shouldOverflow = fullHeight > fiveRowsHeight;

      if (shouldOverflow != _needsExpansion ||
          fiveRowsHeight != _maxCollapsedHeight) {
        setState(() {
          _needsExpansion = shouldOverflow;
          _maxCollapsedHeight = fiveRowsHeight;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final chips = widget.items
        .map(
          (e) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: widget.color != null
                  ? widget.color!.withValues(alpha: 0.15)
                  : context.colors.surfaceRaised,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    widget.color ??
                    context.colors.border.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Text(
              e,
              style: AppTypography.sans(
                color: widget.color ?? context.colors.text,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ),
        )
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Trigger re-calculation whenever layout changes
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _calculateMetrics(),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: AppTypography.display(
                fontSize: 20,
                color: context.colors.text,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                // Measurement items (Invisible)
                Offstage(
                  offstage: true,
                  child: Column(
                    children: [
                      // Single chip to measure row height
                      if (chips.isNotEmpty)
                        Container(key: _singleChipKey, child: chips.first),
                      // Full wrap to measure total height
                      Wrap(
                        key: _fullWrapKey,
                        spacing: 10,
                        runSpacing: 10,
                        children: chips,
                      ),
                    ],
                  ),
                ),

                // Visible version
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: _expanded || !_needsExpansion
                        ? const BoxConstraints()
                        : BoxConstraints(maxHeight: _maxCollapsedHeight),
                    child: ClipRect(
                      child: Stack(
                        children: [
                          Wrap(spacing: 10, runSpacing: 10, children: chips),
                          if (_needsExpansion && !_expanded)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      context.colors.background.withValues(
                                        alpha: 0,
                                      ),
                                      context.colors.background.withValues(
                                        alpha: 0.8,
                                      ),
                                      context.colors.background,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_needsExpansion)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Center(
                  child: InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 16.0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _expanded
                                ? LocalizationService().translate('show_less')
                                : LocalizationService().translate('show_all'),
                            style: AppTypography.sans(
                              color: context.colors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 20,
                            color: context.colors.accent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}

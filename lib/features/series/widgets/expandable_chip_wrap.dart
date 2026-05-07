import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';

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
    
    final RenderBox? fullBox = _fullWrapKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? singleBox = _singleChipKey.currentContext?.findRenderObject() as RenderBox?;
    
    if (fullBox != null && singleBox != null) {
      final double singleHeight = singleBox.size.height;
      final double fullHeight = fullBox.size.height;
      
      // We want to show at most 5 rows.
      // Run spacing is 8.
      const double runSpacing = 8.0;
      final double fiveRowsHeight = (singleHeight * 5) + (runSpacing * 4) + 4; // +4 for a small buffer
      
      final bool shouldOverflow = fullHeight > fiveRowsHeight;
      
      if (shouldOverflow != _needsExpansion || fiveRowsHeight != _maxCollapsedHeight) {
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
        .map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: widget.color != null
                    ? widget.color!.withValues(alpha: 0.15)
                    : AppConstants.tertiaryBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.color ??
                      AppConstants.borderColor.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Text(
                e,
                style: TextStyle(
                  color: widget.color ?? AppConstants.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Trigger re-calculation whenever layout changes (e.g. orientation)
        WidgetsBinding.instance.addPostFrameCallback((_) => _calculateMetrics());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppConstants.textColor,
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
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: chips,
                          ),
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
                                      AppConstants.primaryBackground.withValues(alpha: 0),
                                      AppConstants.primaryBackground.withValues(alpha: 0.8),
                                      AppConstants.primaryBackground,
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
                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _expanded ? LocalizationService().translate('show_less') : LocalizationService().translate('show_all'),
                            style: TextStyle(
                              color: AppConstants.accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 20,
                            color: AppConstants.accentColor,
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

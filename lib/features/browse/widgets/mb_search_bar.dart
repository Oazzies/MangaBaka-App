import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/browse/models/search_filters.dart';
import 'package:bakahyou/features/browse/widgets/search_filter_bottom_sheet.dart';

class MBSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final SearchFilters? initialFilters;
  final ValueChanged<SearchFilters>? onFilterApplied;
  final TextEditingController? controller;
  final VoidCallback? onScanTap;

  const MBSearchBar({
    super.key,
    required this.onChanged,
    this.onSubmitted,
    this.initialFilters,
    this.onFilterApplied,
    this.controller,
    this.onScanTap,
  });

  @override
  State<MBSearchBar> createState() => _MBSearchBarState();
}

class _MBSearchBarState extends State<MBSearchBar> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  late SearchFilters _currentFilters;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _currentFilters = widget.initialFilters ?? SearchFilters();
    _controller.addListener(() => setState(() {}));
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: "Search for something",
        hintStyle: TextStyle(color: AppConstants.textColor),
        prefixIcon: Icon(Icons.search, color: AppConstants.textColor),
        suffixIcon: Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_controller.text.isNotEmpty) ...[
                IconButton(
                  icon: Icon(Icons.clear, color: AppConstants.textColor),
                  onPressed: _clear,
                  constraints: BoxConstraints(),
                ),
                SizedBox(width: 4),
              ],
              if (widget.onScanTap != null) ...[
                IconButton(
                  icon: Icon(Icons.qr_code_scanner, color: AppConstants.textColor),
                  onPressed: widget.onScanTap,
                  constraints: BoxConstraints(),
                ),
                SizedBox(width: 4),
              ],
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: _currentFilters.toMap().isNotEmpty
                      ? AppConstants.accentColor
                      : AppConstants.textColor,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: AppConstants.secondaryBackground,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    builder: (context) {
                      return SearchFilterBottomSheet(
                        initialFilters: _currentFilters,
                        onApply: (filters) {
                          setState(() {
                            _currentFilters = filters;
                          });
                          if (widget.onFilterApplied != null) {
                            widget.onFilterApplied!(filters);
                          }
                        },
                      );
                    },
                  );
                },
                constraints: BoxConstraints(),
              ),
            ],
          ),
        ),
        filled: true,
        fillColor: AppConstants.secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
      style: TextStyle(color: AppConstants.textColor),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.search,
    );
  }
}

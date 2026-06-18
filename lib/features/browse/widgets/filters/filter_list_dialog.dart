import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/tri_state_chip.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/filter_list_item.dart';

class FilterListDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String idKey;
  final String nameKey;
  final List<String> initialIncludes;
  final List<String> initialExcludes;
  final Function(List<String>, List<String>) onApply;
  final bool showSearch;

  const FilterListDialog({
    super.key,
    required this.title,
    required this.items,
    required this.idKey,
    required this.nameKey,
    required this.initialIncludes,
    required this.initialExcludes,
    required this.onApply,
    this.showSearch = true,
  });

  @override
  State<FilterListDialog> createState() => _FilterListDialogState();
}

class _FilterListDialogState extends State<FilterListDialog> {
  String _searchQuery = '';
  late List<String> _includes;
  late List<String> _excludes;

  @override
  void initState() {
    super.initState();
    _includes = List.from(widget.initialIncludes);
    _excludes = List.from(widget.initialExcludes);
  }

  TriState _getTriState(String value) {
    if (_includes.contains(value)) return TriState.include;
    if (_excludes.contains(value)) return TriState.exclude;
    return TriState.off;
  }

  void _updateTriState(String value, TriState state) {
    setState(() {
      _includes.remove(value);
      _excludes.remove(value);
      if (state == TriState.include) _includes.add(value);
      if (state == TriState.exclude) _excludes.add(value);
      widget.onApply(_includes, _excludes);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items.where((t) {
      final name = t[widget.nameKey]?.toString() ?? '';
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort included/excluded items to the top
    filteredItems.sort((a, b) {
      final idA = a[widget.idKey]?.toString() ?? '';
      final idB = b[widget.idKey]?.toString() ?? '';
      
      final stateA = _getTriState(idA);
      final stateB = _getTriState(idB);
      
      final isSelectedA = stateA != TriState.off;
      final isSelectedB = stateB != TriState.off;
      
      if (isSelectedA && !isSelectedB) {
        return -1;
      } else if (!isSelectedA && isSelectedB) {
        return 1;
      }
      return 0; // maintain original sorting for others
    });

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final double? containerHeight = widget.showSearch ? MediaQuery.of(context).size.height * 0.8 : null;

    return Container(
      height: containerHeight,
      decoration: BoxDecoration(
        color: AppConstants.primaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: widget.showSearch ? MainAxisSize.max : MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          _buildDragHandle(),
          _buildHeader(),
          Flexible(
            child: ListView.separated(
              shrinkWrap: !widget.showSearch,
              physics: widget.showSearch ? null : const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: filteredItems.length,
              separatorBuilder: (context, index) => _buildDivider(),
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final id = item[widget.idKey]?.toString() ?? '';
                final name = item[widget.nameKey]?.toString() ?? '';
                final state = _getTriState(id);

                return FilterListItem(
                  name: name,
                  state: state,
                  onToggleInclude: () => _updateTriState(id, state == TriState.include ? TriState.off : TriState.include),
                  onToggleExclude: () => _updateTriState(id, state == TriState.exclude ? TriState.off : TriState.exclude),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: AppConstants.borderColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: widget.showSearch 
          ? const EdgeInsets.fromLTRB(24, 20, 24, 16)
          : const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.showSearch) ...[
            const SizedBox(height: 16),
            TextField(
              style: TextStyle(color: AppConstants.textColor),
              decoration: InputDecoration(
                hintText: 'Search ${widget.title.toLowerCase()}...',
                hintStyle: TextStyle(color: AppConstants.textMutedColor, fontSize: 15),
                prefixIcon: Icon(Icons.search, color: AppConstants.textMutedColor, size: 20),
                filled: true,
                fillColor: AppConstants.secondaryBackground,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppConstants.accentColor.withValues(alpha: 0.3), width: 1),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        color: AppConstants.borderColor.withValues(alpha: 0.05),
        height: 1,
      ),
    );
  }
}

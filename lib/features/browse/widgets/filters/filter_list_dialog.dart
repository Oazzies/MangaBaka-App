import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/search_utils.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/widgets/adaptive_form.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/tri_state_chip.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/filter_list_item.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';

class FilterListDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String idKey;
  final String nameKey;
  final List<String> initialIncludes;
  final List<String> initialExcludes;
  final Function(List<String>, List<String>) onApply;

  /// Null hides the search field.
  final String? searchHint;

  const FilterListDialog({
    super.key,
    required this.title,
    required this.items,
    required this.idKey,
    required this.nameKey,
    required this.initialIncludes,
    required this.initialExcludes,
    required this.onApply,
    this.searchHint,
  });

  @override
  State<FilterListDialog> createState() => _FilterListDialogState();
}

class _FilterListDialogState extends State<FilterListDialog> {
  String _searchQuery = '';
  late List<String> _includes;
  late List<String> _excludes;

  bool get _showSearch => widget.searchHint != null;

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

  List<Map<String, dynamic>> _visibleItems() {
    final preparedQuery = SearchUtils.prepare(_searchQuery);
    final filteredItems = widget.items.where((t) {
      final name = t[widget.nameKey]?.toString() ?? '';
      return preparedQuery.isEmpty || preparedQuery.matches(name);
    }).toList();

    filteredItems.sort((a, b) {
      final isSelectedA =
          _getTriState(a[widget.idKey]?.toString() ?? '') != TriState.off;
      final isSelectedB =
          _getTriState(b[widget.idKey]?.toString() ?? '') != TriState.off;
      if (isSelectedA == isSelectedB) return 0;
      return isSelectedA ? -1 : 1;
    });
    return filteredItems;
  }

  @override
  Widget build(BuildContext context) {
    final isPage = AdaptiveFormPage.isPage(context);
    final filteredItems = _visibleItems();

    final list = ListView.separated(
      shrinkWrap: !_showSearch,
      physics: _showSearch ? null : const NeverScrollableScrollPhysics(),
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
          onToggleInclude: () => _updateTriState(
            id,
            state == TriState.include ? TriState.off : TriState.include,
          ),
          onToggleExclude: () => _updateTriState(
            id,
            state == TriState.exclude ? TriState.off : TriState.exclude,
          ),
        );
      },
    );

    if (isPage) {
      return Column(
        children: [
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: _buildSearchField(),
            ),
          Expanded(child: list),
        ],
      );
    }

    return Container(
      height: _showSearch ? MediaQuery.sizeOf(context).height * 0.8 : null,
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: _showSearch ? MainAxisSize.max : MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const AdaptiveSheetHandle(),
          _buildHeader(),
          Flexible(child: list),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: _showSearch
          ? const EdgeInsets.fromLTRB(24, 20, 24, 16)
          : const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: AppTypography.display(
              color: context.colors.text,
              fontSize: 18,
            ),
          ),
          if (_showSearch) ...[
            const SizedBox(height: 16),
            _buildSearchField(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    );
    return TextField(
      style: AppTypography.sans(color: context.colors.text),
      decoration: InputDecoration(
        hintText: widget.searchHint,
        hintStyle: AppTypography.sans(
          color: context.colors.textMuted,
          fontSize: 15,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: context.colors.textMuted,
          size: 20,
        ),
        filled: true,
        fillColor: context.colors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: context.colors.accent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      onChanged: (val) => setState(() => _searchQuery = val),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: context.colors.surfaceRaised, height: 1),
    );
  }
}

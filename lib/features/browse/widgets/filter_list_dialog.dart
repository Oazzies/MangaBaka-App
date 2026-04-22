import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/browse/widgets/tri_state_chip.dart';

class FilterListDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String idKey;
  final String nameKey;
  final List<String> initialIncludes;
  final List<String> initialExcludes;
  final Function(List<String>, List<String>) onApply;

  const FilterListDialog({
    super.key,
    required this.title,
    required this.items,
    required this.idKey,
    required this.nameKey,
    required this.initialIncludes,
    required this.initialExcludes,
    required this.onApply,
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

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppConstants.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              style: TextStyle(color: AppConstants.textColor),
              decoration: InputDecoration(
                hintText: 'Search ${widget.title.toLowerCase()}...',
                hintStyle: TextStyle(color: AppConstants.textMutedColor),
                prefixIcon: Icon(Icons.search, color: AppConstants.textMutedColor),
                filled: true,
                fillColor: AppConstants.secondaryBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final id = item[widget.idKey]?.toString() ?? '';
                final name = item[widget.nameKey]?.toString() ?? '';
                final state = _getTriState(id);

                return ListTile(
                  title: Text(
                    name,
                    style: TextStyle(color: AppConstants.textColor),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.check_circle,
                          color: state == TriState.include
                              ? AppConstants.accentColor
                              : AppConstants.borderColor,
                        ),
                        onPressed: () {
                          _updateTriState(
                            id,
                            state == TriState.include
                                ? TriState.off
                                : TriState.include,
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.cancel,
                          color: state == TriState.exclude
                              ? AppConstants.errorColor
                              : AppConstants.borderColor,
                        ),
                        onPressed: () {
                          _updateTriState(
                            id,
                            state == TriState.exclude
                                ? TriState.off
                                : TriState.exclude,
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

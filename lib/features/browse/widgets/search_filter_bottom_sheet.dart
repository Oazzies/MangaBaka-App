import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/browse/models/search_filters.dart';
import 'package:bakahyou/features/series/services/series_search_service.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/features/browse/widgets/filter_list_dialog.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/features/profile/widgets/settings_components.dart';

class SearchFilterBottomSheet extends StatefulWidget {
  final SearchFilters initialFilters;
  final ValueChanged<SearchFilters> onApply;

  const SearchFilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<SearchFilterBottomSheet> createState() =>
      _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState extends State<SearchFilterBottomSheet> {
  late SearchFilters _filters;
  late final SeriesSearchService _searchService;

  final List<String> _types = ['manga', 'manhwa', 'manhua', 'novel', 'oel'];
  final List<String> _statuses = [
    'ongoing',
    'releasing',
    'completed',
    'hiatus',
    'cancelled',
  ];

  Map<String, String> _getSortOptions(LocalizationService l10n) {
    return {
      'name_asc': l10n.translate('title_asc'),
      'name_desc': l10n.translate('title_desc'),
      'popularity_asc': l10n.translate('popularity_asc'),
      'popularity_desc': l10n.translate('popularity_desc'),
      'random': l10n.translate('random_sort'),
    };
  }

  List<Map<String, dynamic>> _genres = [];
  List<Map<String, dynamic>> _tags = [];
  bool _isLoadingMetadata = true;

  final int _minYear = 1950;
  final int _maxYear = DateTime.now().year + 1;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _searchService = getIt<SeriesSearchService>();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      final results = await Future.wait([
        _searchService.getGenres(),
        _searchService.getTags(),
      ]);
      if (mounted) {
        setState(() {
          _genres = results[0];
          _tags = results[1];
          _isLoadingMetadata = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMetadata = false);
      }
    }
  }

  void _showSortSelectionDialog(
    BuildContext context,
    LocalizationService l10n,
    Map<String, String> sortOptions,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return Container(
          decoration: BoxDecoration(
            color: AppConstants.secondaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.borderColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.translate('sort_by'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ...sortOptions.entries.map((e) {
                final isSelected = _filters.sortBy == e.key;
                return GestureDetector(
                  onTap: () {
                    setState(() => _filters = _filters.copyWith(sortBy: e.key));
                    Navigator.pop(dialogContext);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppConstants.borderColor.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          e.value,
                          style: TextStyle(
                            color: isSelected
                                ? AppConstants.textColor
                                : AppConstants.textMutedColor,
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: AppConstants.accentColor,
                            size: 24,
                          )
                        else
                          Icon(
                            Icons.circle_outlined,
                            color: AppConstants.borderColor.withValues(alpha: 0.3),
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () {
                  setState(() => _filters = _filters.copyWith(sortBy: null));
                  Navigator.pop(dialogContext);
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      Text(
                        l10n.translate('default'),
                        style: TextStyle(
                          color: _filters.sortBy == null
                              ? AppConstants.textColor
                              : AppConstants.textMutedColor,
                          fontSize: 16,
                          fontWeight: _filters.sortBy == null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      if (_filters.sortBy == null)
                        Icon(
                          Icons.check_circle,
                          color: AppConstants.accentColor,
                          size: 24,
                        )
                      else
                        Icon(
                          Icons.circle_outlined,
                          color: AppConstants.borderColor.withValues(alpha: 0.3),
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLicensedStatusDialog(
    BuildContext context,
    LocalizationService l10n,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return Container(
          decoration: BoxDecoration(
            color: AppConstants.secondaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.borderColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.translate('licensed_status'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildSimpleSelectionTile(
                l10n.translate('any'),
                _filters.isLicensed == null,
                () => setState(() => _filters = _filters.copyWithIsLicensed(null)),
                dialogContext,
              ),
              _buildSimpleSelectionTile(
                l10n.translate('yes'),
                _filters.isLicensed == true,
                () => setState(() => _filters = _filters.copyWithIsLicensed(true)),
                dialogContext,
              ),
              _buildSimpleSelectionTile(
                l10n.translate('no'),
                _filters.isLicensed == false,
                () => setState(() => _filters = _filters.copyWithIsLicensed(false)),
                dialogContext,
                isLast: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleSelectionTile(
    String label,
    bool isSelected,
    VoidCallback onTap,
    BuildContext context, {
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: AppConstants.borderColor.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppConstants.textColor
                    : AppConstants.textMutedColor,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppConstants.accentColor,
                size: 24,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: AppConstants.borderColor.withValues(alpha: 0.3),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog({
    required String title,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required List<String> includes,
    required List<String> excludes,
    required Function(List<String>, List<String>) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppConstants.primaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: FilterListDialog(
            title: title,
            items: items,
            idKey: idKey,
            nameKey: nameKey,
            initialIncludes: includes,
            initialExcludes: excludes,
            onApply: onApply,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        final l10n = LocalizationService();
        final sortOptions = _getSortOptions(l10n);

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: AppConstants.primaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.borderColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () =>
                          setState(() => _filters = SearchFilters()),
                      child: Text(
                        l10n.translate('reset'),
                        style: TextStyle(
                          color: AppConstants.textMutedColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      l10n.translate('filters'),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onApply(_filters);
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor:
                            AppConstants.accentColor.withValues(alpha: 0.15),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        l10n.translate('apply'),
                        style: TextStyle(
                          color: AppConstants.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoadingMetadata
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: EdgeInsets.only(
                          left: AppConstants.horizontalPadding,
                          right: AppConstants.horizontalPadding,
                          top: 8,
                          bottom: 40,
                        ),
                        children: [
                          SettingsSectionHeader(
                            title: l10n.translate('sort_by'),
                          ),
                          SettingsGroup(
                            children: [
                              SettingsItem(
                                icon: Icons.sort_outlined,
                                title: l10n.translate('sort_by'),
                                subtitle: _filters.sortBy == null
                                    ? l10n.translate('default')
                                    : sortOptions[_filters.sortBy],
                                isFirst: true,
                                isLast: true,
                                onTap: () => _showSortSelectionDialog(
                                  context,
                                  l10n,
                                  sortOptions,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SettingsSectionHeader(
                            title: l10n.translate('categories'),
                          ),
                          SettingsGroup(
                            children: [
                              SettingsItem(
                                icon: Icons.category_outlined,
                                title: l10n.translate('genres'),
                                subtitle: _filters.genre.isEmpty &&
                                        _filters.genreNot.isEmpty
                                    ? l10n.translate('any')
                                    : '${_filters.genre.length} ${l10n.translate('included')}, ${_filters.genreNot.length} ${l10n.translate('excluded')}',
                                isFirst: true,
                                onTap: () => _showFilterDialog(
                                  title: l10n.translate('genres'),
                                  items: _genres,
                                  idKey: 'value',
                                  nameKey: 'label',
                                  includes: _filters.genre,
                                  excludes: _filters.genreNot,
                                  onApply: (inc, exc) => setState(
                                    () => _filters = _filters.copyWith(
                                      genre: inc,
                                      genreNot: exc,
                                    ),
                                  ),
                                ),
                              ),
                              const SettingsDivider(),
                              SettingsItem(
                                icon: Icons.label_outline,
                                title: l10n.translate('tags'),
                                subtitle: _filters.tag.isEmpty &&
                                        _filters.tagNot.isEmpty
                                    ? l10n.translate('any')
                                    : '${_filters.tag.length} ${l10n.translate('included')}, ${_filters.tagNot.length} ${l10n.translate('excluded')}',
                                isLast: true,
                                onTap: () => _showFilterDialog(
                                  title: l10n.translate('tags'),
                                  items: _tags,
                                  idKey: 'id',
                                  nameKey: 'name',
                                  includes: _filters.tag,
                                  excludes: _filters.tagNot,
                                  onApply: (inc, exc) => setState(
                                    () => _filters = _filters.copyWith(
                                      tag: inc,
                                      tagNot: exc,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SettingsGroup(
                            children: [
                              SettingsItem(
                                icon: Icons.auto_awesome_outlined,
                                title: l10n.translate('type'),
                                subtitle: _filters.type.isEmpty &&
                                        _filters.typeNot.isEmpty
                                    ? l10n.translate('any')
                                    : '${_filters.type.length} ${l10n.translate('included')}, ${_filters.typeNot.length} ${l10n.translate('excluded')}',
                                isFirst: true,
                                onTap: () => _showFilterDialog(
                                  title: l10n.translate('type'),
                                  items: _types
                                      .map((t) => {
                                            'value': t,
                                            'label': l10n.translate('type_$t'),
                                          })
                                      .toList(),
                                  idKey: 'value',
                                  nameKey: 'label',
                                  includes: _filters.type,
                                  excludes: _filters.typeNot,
                                  onApply: (inc, exc) => setState(
                                    () => _filters = _filters.copyWith(
                                      type: inc,
                                      typeNot: exc,
                                    ),
                                  ),
                                ),
                              ),
                              const SettingsDivider(),
                              SettingsItem(
                                icon: Icons.history_outlined,
                                title: l10n.translate('status'),
                                subtitle: _filters.status.isEmpty &&
                                        _filters.statusNot.isEmpty
                                    ? l10n.translate('any')
                                    : '${_filters.status.length} ${l10n.translate('included')}, ${_filters.statusNot.length} ${l10n.translate('excluded')}',
                                isLast: true,
                                onTap: () => _showFilterDialog(
                                  title: l10n.translate('status'),
                                  items: _statuses
                                      .map((s) => {
                                            'value': s,
                                            'label': l10n.translate('status_$s'),
                                          })
                                      .toList(),
                                  idKey: 'value',
                                  nameKey: 'label',
                                  includes: _filters.status,
                                  excludes: _filters.statusNot,
                                  onApply: (inc, exc) => setState(
                                    () => _filters = _filters.copyWith(
                                      status: inc,
                                      statusNot: exc,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SettingsSectionHeader(
                            title: l10n.translate('details'),
                          ),
                          SettingsGroup(
                            children: [
                              SettingsItem(
                                icon: Icons.verified_user_outlined,
                                title: l10n.translate('licensed_status'),
                                subtitle: _filters.isLicensed == null
                                    ? l10n.translate('any')
                                    : (_filters.isLicensed == true
                                        ? l10n.translate('yes')
                                        : l10n.translate('no')),
                                isFirst: true,
                                onTap: () => _showLicensedStatusDialog(
                                  context,
                                  l10n,
                                ),
                              ),
                              const SettingsDivider(),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          l10n.translate('rating_range'),
                                          style: TextStyle(
                                            color: AppConstants.textColor,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '${_filters.ratingLower.toInt()} - ${_filters.ratingUpper.toInt()}',
                                          style: TextStyle(
                                            color: AppConstants.accentColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    RangeSlider(
                                      values: RangeValues(
                                        _filters.ratingLower,
                                        _filters.ratingUpper,
                                      ),
                                      min: 0,
                                      max: 100,
                                      divisions: 20,
                                      activeColor: AppConstants.accentColor,
                                      inactiveColor: AppConstants.borderColor
                                          .withValues(alpha: 0.2),
                                      onChanged: (values) => setState(
                                        () => _filters = _filters.copyWith(
                                          ratingLower: values.start,
                                          ratingUpper: values.end,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SettingsDivider(),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          l10n.translate('publication_year'),
                                          style: TextStyle(
                                            color: AppConstants.textColor,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '${_filters.publishedYearLower ?? l10n.translate('any')} - ${_filters.publishedYearUpper ?? l10n.translate('any')}',
                                          style: TextStyle(
                                            color: AppConstants.accentColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    RangeSlider(
                                      values: RangeValues(
                                        (_filters.publishedYearLower ??
                                                _minYear)
                                            .toDouble(),
                                        (_filters.publishedYearUpper ??
                                                _maxYear)
                                            .toDouble(),
                                      ),
                                      min: _minYear.toDouble(),
                                      max: _maxYear.toDouble(),
                                      divisions: _maxYear - _minYear,
                                      activeColor: AppConstants.accentColor,
                                      inactiveColor: AppConstants.borderColor
                                          .withValues(alpha: 0.2),
                                      onChanged: (values) => setState(
                                        () => _filters = _filters.copyWith(
                                          publishedYearLower:
                                              values.start.toInt() == _minYear
                                                  ? null
                                                  : values.start.toInt(),
                                          publishedYearUpper:
                                              values.end.toInt() == _maxYear
                                                  ? null
                                                  : values.end.toInt(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

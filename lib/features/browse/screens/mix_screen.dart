import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/browse/controllers/mix_controller.dart';
import 'package:mangabaka_app/features/browse/utils/browse_helpers.dart';
import 'package:mangabaka_app/features/browse/widgets/mix/mix_dna_section.dart';
import 'package:mangabaka_app/features/browse/widgets/mix/mix_options_section.dart';
import 'package:mangabaka_app/features/browse/widgets/mix/mix_results_header.dart';
import 'package:mangabaka_app/features/browse/widgets/mix/mix_results_sliver.dart';
import 'package:mangabaka_app/features/browse/widgets/mix/mix_seed_section.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/services/series_list_deps.dart';
import 'package:mangabaka_app/features/series/services/series_autocomplete_service.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

class MixScreen extends StatefulWidget {
  const MixScreen({super.key});

  @override
  State<MixScreen> createState() => _MixScreenState();
}

class _MixScreenState extends State<MixScreen> {
  /// Lets a tap on a suggestion land before the blur that precedes it hides the panel.
  static const Duration _suggestionDismissDelay = Duration(milliseconds: 150);

  late final MixController _controller;
  late final SeriesListDeps _listDeps = SeriesListDeps.fromLocator();
  late final SeriesAutocompleteService _autocomplete;

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<AutocompleteSeriesResult> _suggestions = const [];
  bool _showSuggestions = false;
  Timer? _suggestionDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = MixController();
    _autocomplete = SeriesAutocompleteService();

    _searchCtrl.addListener(_onSearchChanged);
    _searchFocus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _suggestionDismissTimer?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchFocus.removeListener(_onFocusChanged);
    _controller.dispose();
    _autocomplete.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    _suggestionDismissTimer?.cancel();
    if (_searchFocus.hasFocus) return;
    _suggestionDismissTimer = Timer(_suggestionDismissDelay, () {
      if (!mounted || _searchFocus.hasFocus) return;
      setState(() => _showSuggestions = false);
    });
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      _clearSuggestions();
      return;
    }
    _autocomplete.search(
      query,
      onResults: (results) {
        if (!mounted) return;
        setState(() {
          _suggestions = results;
          _showSuggestions = results.isNotEmpty && _searchFocus.hasFocus;
        });
      },
    );
  }

  void _clearSuggestions() {
    if (!mounted) return;
    setState(() {
      _suggestions = const [];
      _showSuggestions = false;
    });
  }

  void _selectSuggestion(AutocompleteSeriesResult result) {
    _controller.addSeed(BrowseHelpers.convertAutocompleteToSeries(result));
    _searchCtrl.clear();
    _searchFocus.unfocus();
    _clearSuggestions();
  }

  void _addSuggestionSeed(AutocompleteSeriesResult suggestion) {
    _controller.addSeed(BrowseHelpers.convertAutocompleteToSeries(suggestion));
  }

  void _clearSearchField() {
    _searchCtrl.clear();
    _clearSuggestions();
  }

  void _navigateToDetail(Series series) {
    Navigator.push(
      context,
      AppTransitions.slideUp(SeriesDetailScreen(series: series)),
    );
  }

  bool get _showResultsHeader =>
      _controller.hasSeeds &&
      _controller.error == null &&
      _controller.results.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return ListenableBuilder(
      // SettingsManager left out on purpose: the results sliver subscribes on its own.
      listenable: Listenable.merge([_controller, l10n]),
      builder: (context, _) {
        final isLandscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;
        return isLandscape ? _buildLandscape(l10n) : _buildPortrait(l10n);
      },
    );
  }

  Widget _buildPortrait(LocalizationService l10n) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: context.colors.background,
            surfaceTintColor: Colors.transparent,
            leading: _backButton(l10n),
            title: _title(l10n),
            centerTitle: true,
            pinned: true,
            actions: _actions(l10n),
          ),
          SliverToBoxAdapter(child: _seedSection(l10n)),
          SliverToBoxAdapter(child: _optionsSection(l10n)),
          if (_controller.dna.isNotEmpty)
            SliverToBoxAdapter(child: _dnaSection(l10n)),
          if (_showResultsHeader)
            SliverToBoxAdapter(child: _resultsHeader(l10n)),
          _resultsSliver(l10n),
          // Clears the bottom navigation bar.
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildLandscape(LocalizationService l10n) {
    // Below ~280px the seed chips wrap badly; above ~360px it steals width from results.
    final leftWidth = (MediaQuery.sizeOf(context).width * 0.38).clamp(
      280.0,
      360.0,
    );

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: _backButton(l10n),
        title: _title(l10n),
        centerTitle: true,
        actions: _actions(l10n),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: leftWidth,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _seedSection(l10n),
                  _optionsSection(l10n),
                  if (_controller.dna.isNotEmpty) _dnaSection(l10n),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: context.colors.border),
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (_showResultsHeader)
                  SliverToBoxAdapter(child: _resultsHeader(l10n)),
                _resultsSliver(l10n),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton(LocalizationService l10n) => IconButton(
    icon: Icon(Icons.arrow_back_rounded, color: context.colors.text, size: 22),
    tooltip: l10n.translate('back'),
    onPressed: () => Navigator.pop(context),
  );

  Widget _title(LocalizationService l10n) => Text(
    l10n.translate('mix').toUpperCase(),
    style: AppTypography.display(
      color: context.colors.text,
      fontWeight: FontWeight.w500,
      fontSize: 22,
    ),
  );

  List<Widget> _actions(LocalizationService l10n) => [
    if (_controller.hasSeeds)
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: IconButton(
          icon: Icon(
            Icons.clear_all_rounded,
            color: context.colors.textMuted,
            size: 22,
          ),
          onPressed: _controller.clearSeeds,
          tooltip: l10n.translate('mix_clear_seeds'),
        ),
      ),
  ];

  Widget _seedSection(LocalizationService l10n) => MixSeedSection(
    controller: _controller,
    l10n: l10n,
    searchController: _searchCtrl,
    searchFocus: _searchFocus,
    suggestions: _suggestions,
    showSuggestions: _showSuggestions,
    onSeedTap: _navigateToDetail,
    onSeedRemove: _controller.removeSeed,
    onSuggestionSelected: _selectSuggestion,
    onSuggestedSeedAdded: _addSuggestionSeed,
    onClearSearch: _clearSearchField,
  );

  Widget _optionsSection(LocalizationService l10n) => MixOptionsSection(
    controller: _controller,
    l10n: l10n,
    auth: _listDeps.auth,
  );

  Widget _dnaSection(LocalizationService l10n) =>
      MixDnaSection(dna: _controller.dna, l10n: l10n);

  Widget _resultsHeader(LocalizationService l10n) => MixResultsHeader(
    l10n: l10n,
    resultCount: _controller.results.length,
    loading: _controller.isLoading,
  );

  Widget _resultsSliver(LocalizationService l10n) => MixResultsSliver(
    controller: _controller,
    l10n: l10n,
    onSeriesTap: _navigateToDetail,
    deps: _listDeps,
  );
}

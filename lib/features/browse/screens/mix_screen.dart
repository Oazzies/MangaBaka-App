import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/controllers/mix_controller.dart';
import 'package:mangabaka_app/features/browse/models/mix_result.dart';
import 'package:mangabaka_app/features/browse/utils/browse_helpers.dart';
import 'package:mangabaka_app/features/browse/widgets/search/search_suggestions_panel.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/services/series_autocomplete_service.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';

class MixScreen extends StatefulWidget {
  const MixScreen({super.key});

  @override
  State<MixScreen> createState() => _MixScreenState();
}

class _MixScreenState extends State<MixScreen> {
  late final MixController _controller;
  late final SeriesAutocompleteService _autocomplete;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<AutocompleteSeriesResult> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = MixController();
    _autocomplete = SeriesAutocompleteService();

    _searchCtrl.addListener(_onSearchChanged);
    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && !_searchFocus.hasFocus) {
            setState(() => _showSuggestions = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _autocomplete.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _autocomplete.search(
      q,
      onResults: (results) {
        if (!mounted) return;
        setState(() {
          _suggestions = results;
          _showSuggestions = results.isNotEmpty && _searchFocus.hasFocus;
        });
      },
    );
  }

  void _selectSuggestion(AutocompleteSeriesResult result) {
    final series = BrowseHelpers.convertAutocompleteToSeries(result);
    _controller.addSeed(series);
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  void _addSuggestionSeed(AutocompleteSeriesResult suggestion) {
    final series = BrowseHelpers.convertAutocompleteToSeries(suggestion);
    _controller.addSeed(series);
  }

  void _navigateToDetail(Series series) {
    Navigator.push(
      context,
      AppTransitions.slideUp(SeriesDetailScreen(series: series)),
    );
  }



  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, l10n]),
      builder: (context, _) {
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        if (isLandscape) return _buildLandscapeScaffold(l10n);
        return Scaffold(
          backgroundColor: AppConstants.primaryBackground,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(l10n),
              SliverToBoxAdapter(child: _buildSeedSection(l10n)),
              SliverToBoxAdapter(child: _buildOptionsSection(l10n)),
              if (_controller.dna.isNotEmpty)
                SliverToBoxAdapter(child: _buildDnaSection(l10n)),
              if (_controller.hasSeeds && !_controller.isLoading && _controller.error == null && _controller.results.isNotEmpty)
                SliverToBoxAdapter(child: _buildResultsHeader(l10n)),
              _buildResultsSliver(l10n),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLandscapeScaffold(LocalizationService l10n) {
    final screenWidth = MediaQuery.of(context).size.width;
    final leftWidth = (screenWidth * 0.38).clamp(280.0, 360.0);

    return Scaffold(
      backgroundColor: AppConstants.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.translate('mix'),
          style: AppTypography.serif(
            color: AppConstants.textColor,
            fontWeight: FontWeight.w500,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_controller.hasSeeds)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Icon(Icons.refresh_rounded,
                    color: AppConstants.textMutedColor, size: 22),
                onPressed: _controller.clearSeeds,
                tooltip: 'Clear seeds',
              ),
            ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left panel: seeds + options + DNA
          SizedBox(
            width: leftWidth,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSeedSection(l10n),
                  _buildOptionsSection(l10n),
                  if (_controller.dna.isNotEmpty) _buildDnaSection(l10n),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppConstants.borderColor.withValues(alpha: 0.15),
          ),
          // Right panel: results
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomScrollView(
                  slivers: [
                    if (_controller.hasSeeds &&
                        !_controller.isLoading &&
                        _controller.error == null &&
                        _controller.results.isNotEmpty)
                      SliverToBoxAdapter(child: _buildResultsHeader(l10n)),
                    _buildResultsSliver(l10n, availableWidth: constraints.maxWidth),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ─────────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(LocalizationService l10n) {
    return SliverAppBar(
      backgroundColor: AppConstants.primaryBackground,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppConstants.textColor, size: 22),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        l10n.translate('mix'),
        style: AppTypography.serif(
          color: AppConstants.textColor,
          fontWeight: FontWeight.w500,
          fontSize: 22,
        ),
      ),
      centerTitle: true,
      floating: false,
      pinned: true,
      actions: [
        if (_controller.hasSeeds)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(Icons.refresh_rounded,
                  color: AppConstants.textMutedColor, size: 22),
              onPressed: _controller.clearSeeds,
              tooltip: 'Clear seeds',
            ),
          ),
      ],
    );
  }

  // ─── Seed Section ─────────────────────────────────────────────────────────

  Widget _buildSeedSection(LocalizationService l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.grass_rounded,
                      color: AppConstants.accentColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.translate('mix_seeds'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Seed chips row
            if (_controller.seeds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _controller.seeds
                        .map((seed) => _buildSeedChip(seed))
                        .toList(),
                  ),
                ),
              ),

            // Search field (styled like MB search bar)
            _buildSeedSearchField(l10n),

            // Autocomplete suggestions
            if (_showSuggestions && _suggestions.isNotEmpty) ...[
              const SizedBox(height: 6),
              SearchSuggestionsPanel(
                results: _suggestions,
                onResultTapped: _selectSuggestion,
                showSuggestions: true,
              ),
            ],

            // Seed suggestions from API
            if (_controller.seeds.length >= 2) ...[
              const SizedBox(height: 12),
              _buildSeedSuggestions(l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeedChip(Series seed) {
    final coverUrl = seed.coverUrl;
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 4),
      child: Material(
        color: AppConstants.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToDetail(seed),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cover thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 36,
                    height: 50,
                    child: coverUrl.isNotEmpty
                        ? WidgetUtils.networkImage(
                            url: coverUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 80,
                          )
                        : Container(
                            color: AppConstants.accentColor.withValues(alpha: 0.3),
                            child: Icon(Icons.book_rounded,
                                color: AppConstants.accentColor, size: 18),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                // Title
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    seed.title,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Remove button
                GestureDetector(
                  onTap: () => _controller.removeSeed(seed),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppConstants.tertiaryBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppConstants.textMutedColor,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeedSearchField(LocalizationService l10n) {
    return TextField(
      controller: _searchCtrl,
      focusNode: _searchFocus,
      style: TextStyle(color: AppConstants.textColor, fontSize: 16),
      decoration: InputDecoration(
        hintText: l10n.translate('mix_add_seed'),
        hintStyle: TextStyle(color: AppConstants.textMutedColor, fontSize: 16),
        prefixIcon: Icon(Icons.search, color: AppConstants.textColor, size: 22),
        prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.close, color: AppConstants.textMutedColor, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {
                    _suggestions = [];
                    _showSuggestions = false;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: AppConstants.tertiaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    );
  }

  Widget _buildSeedSuggestions(LocalizationService l10n) {
    if (_controller.isSuggestionsLoading) {
      return Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppConstants.accentColor,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            l10n.translate('mix_seed_suggestions'),
            style: TextStyle(color: AppConstants.textMutedColor, fontSize: 13),
          ),
        ],
      );
    }

    if (_controller.seedSuggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_rounded,
                color: AppConstants.accentColor, size: 16),
            const SizedBox(width: 6),
            Text(
              l10n.translate('mix_seed_suggestions'),
              style: TextStyle(
                color: AppConstants.textMutedColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: _controller.seedSuggestions.length,
            itemBuilder: (context, i) {
              final sug = _controller.seedSuggestions[i];
              return _buildSeedSuggestionCard(sug);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSeedSuggestionCard(AutocompleteSeriesResult sug) {
    return GestureDetector(
      onTap: () => _addSuggestionSeed(sug),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppConstants.secondaryBackground,
          borderRadius: BorderRadius.circular(AppConstants.denseRadius),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.denseRadius),
                bottomLeft: Radius.circular(AppConstants.denseRadius),
              ),
              child: SizedBox(
                width: 46,
                height: double.infinity,
                child: sug.thumbnailUrl.isNotEmpty
                    ? WidgetUtils.networkImage(
                        url: sug.thumbnailUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 100,
                      )
                    : Container(color: AppConstants.tertiaryBackground),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                sug.title,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppConstants.accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_rounded,
                    color: AppConstants.accentColor, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Options Section ──────────────────────────────────────────────────────

  Widget _buildOptionsSection(LocalizationService l10n) {
    final auth = getIt<ProfileAuthService>();
    final isLoggedIn = auth.isLoggedIn;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppConstants.secondaryBackground,
          borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        ),
        child: Column(
          children: [
            _buildToggleRow(
              icon: Icons.tune_rounded,
              title: 'Strict Mode',
              subtitle: 'Hard-filter tags instead of vector boost',
              value: _controller.strictMode,
              onChanged: _controller.setStrictMode,
              isFirst: true,
            ),
            _buildDivider(),
            _buildToggleRow(
              icon: Icons.visibility_off_outlined,
              title: l10n.translate('hide_library'),
              subtitle: l10n.translate('hide_library_subtext'),
              value: _controller.excludeLibrary,
              onChanged: isLoggedIn ? _controller.setExcludeLibrary : null,
              isLoggedInRequired: !isLoggedIn,
            ),
            _buildDivider(),
            _buildToggleRow(
              icon: Icons.merge_type_rounded,
              title: 'Blend My Taste',
              subtitle: 'Mix recommendations with your library taste',
              value: _controller.blendUser,
              onChanged: isLoggedIn ? _controller.setBlendUser : null,
              isLoggedInRequired: !isLoggedIn,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppConstants.borderColor.withValues(alpha: 0.15),
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool isFirst = false,
    bool isLast = false,
    bool isLoggedInRequired = false,
  }) {
    final effectiveColor = isLoggedInRequired
        ? AppConstants.textMutedColor.withValues(alpha: 0.5)
        : AppConstants.textColor;

    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? 4 : 0,
        bottom: isLast ? 4 : 0,
      ),
      child: ListTile(
        leading: Icon(icon, color: isLoggedInRequired
            ? AppConstants.textMutedColor.withValues(alpha: 0.4)
            : AppConstants.accentColor, size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: effectiveColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isLoggedInRequired ? 'Requires login' : subtitle,
          style: TextStyle(
            color: AppConstants.textMutedColor.withValues(
              alpha: isLoggedInRequired ? 0.5 : 1.0,
            ),
            fontSize: 12,
          ),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppConstants.accentColor,
          activeTrackColor: AppConstants.accentColor.withValues(alpha: 0.4),
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }

  // ─── DNA Section ──────────────────────────────────────────────────────────

  Widget _buildDnaSection(LocalizationService l10n) {
    if (_controller.dna.isEmpty) return const SizedBox.shrink();

    // Sort DNA tags by weight descending (if not already sorted)
    final sortedDna = List<MixDnaTag>.from(_controller.dna)
      ..sort((a, b) => b.weight.compareTo(a.weight));

    final maxWeight = sortedDna.isEmpty ? 0.0 : sortedDna.first.weight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.biotech_rounded, color: AppConstants.accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.translate('mix_dna'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.translate('mix_dna_subtitle'),
                style: TextStyle(color: AppConstants.textMutedColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.secondaryBackground,
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...sortedDna.take(5).map((tag) {
                  final norm = maxWeight > 0 ? tag.weight / maxWeight : 0.0;
                  final percentage = (norm * 100).round();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tag.name,
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$percentage%',
                              style: TextStyle(
                                color: AppConstants.accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppConstants.tertiaryBackground,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: norm.clamp(0.02, 1.0),
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppConstants.accentColor.withValues(alpha: 0.7),
                                      AppConstants.accentColor,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppConstants.accentColor.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                if (sortedDna.length > 5) ...[
                  const SizedBox(height: 4),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppConstants.borderColor.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Additional DNA elements:',
                    style: TextStyle(
                      color: AppConstants.textMutedColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: sortedDna.skip(5).take(10).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConstants.tertiaryBackground,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag.name,
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Results Header ───────────────────────────────────────────────────────

  Widget _buildResultsHeader(LocalizationService l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded,
              color: AppConstants.accentColor, size: 20),
          const SizedBox(width: 8),
          Text(
            l10n.translate('mix_results'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_controller.results.length}',
            style: TextStyle(
              color: AppConstants.textMutedColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Results Sliver ───────────────────────────────────────────────────────

  Widget _buildResultsSliver(LocalizationService l10n, {double? availableWidth}) {
    if (!_controller.hasSeeds) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(l10n),
      );
    }

    if (_controller.isLoading) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildLoadingState(l10n),
      );
    }

    if (_controller.error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildErrorState(l10n),
      );
    }

    if (_controller.results.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              l10n.translate('mix_no_results'),
              style: TextStyle(color: AppConstants.textMutedColor, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final settings = SettingsManager();
    final activeStyle = settings.separateListStyles
        ? settings.browseListStyle
        : settings.currentListStyle;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final series = _controller.results[index];
            return InkWell(
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              onTap: () => _navigateToDetail(series),
              child: EntryListItem(
                key: ValueKey('mix_${series.id}'),
                series: series,
              ),
            );
          },
          childCount: _controller.results.length,
        ),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: settings.browseGridColumnCount > 0
              ? (availableWidth ?? MediaQuery.of(context).size.width) /
                  settings.browseGridColumnCount
              : 160,
          childAspectRatio: activeStyle.childAspectRatio,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
      ),
    );
  }

  Widget _buildEmptyState(LocalizationService l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Text(
              l10n.translate('mix_empty_title'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.translate('mix_empty_subtitle'),
              style: TextStyle(
                color: AppConstants.textMutedColor,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(LocalizationService l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppConstants.accentColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.translate('mix_generating'),
            style: TextStyle(
              color: AppConstants.textMutedColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(LocalizationService l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                color: AppConstants.errorColor, size: 48),
            const SizedBox(height: 16),
            Text(
              l10n.translate('mix_error'),
              style: TextStyle(
                  color: AppConstants.errorColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _controller.refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.translate('retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.accentColor,
                foregroundColor: AppConstants.primaryBackground,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.pillRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

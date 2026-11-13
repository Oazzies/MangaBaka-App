part of 'browse_controller.dart';

Future<void> _searchSeriesImpl(BrowseController self) async {
  if (self._currentSearchQuery.trim().isEmpty &&
      self._currentFilters.toMap().isEmpty &&
      self._currentType != BrowseType.publishers) {
    BrowseController._logger.fine(
      'Search query and filters are empty, skipping search',
    );
    self.resetSearchState();
    return;
  }

  BrowseController._logger.info(
    'Starting new search for ${self._currentType} with query: '
    '"${self._currentSearchQuery}" with filters: ${self._currentFilters.toMap()}',
  );
  self._requestGeneration++;
  self._isLoading = true;
  self._isLoadingMore = false;
  self._error = null;
  self._results.clear();
  self._notify();

  await _fetchPageImpl(self);
}

Future<void> _loadMoreResultsImpl(BrowseController self) async {
  if (self._isLoading || self._isLoadingMore || !self._results.hasMore) return;

  BrowseController._logger.info(
    'Loading more results for query: "${self._currentSearchQuery}", '
    'page: ${self._results.page + 1}',
  );
  self._isLoadingMore = true;
  self._notify();

  self._results.advancePage();
  await _fetchPageImpl(self, isLoadMore: true);
}

Future<void> _fetchPageImpl(
  BrowseController self, {
  bool isLoadMore = false,
}) async {
  final generation = self._requestGeneration;
  try {
    switch (self._currentType) {
      case BrowseType.series:
        final page = await self._gateway.fetchSeries(
          query: self._currentSearchQuery,
          page: self._results.page,
          filters: self._currentFilters,
          alreadyLoaded: self._results.loadedCount(BrowseType.series),
        );
        if (_isStaleImpl(self, generation, 'series')) return;
        self._results.addSeries(page);

      case BrowseType.publishers:
        final page = await self._gateway.fetchPublishers(
          query: self._currentSearchQuery,
          page: self._results.page,
          sortBy: self._publisherSort,
          alreadyLoaded: self._results.loadedCount(BrowseType.publishers),
        );
        if (_isStaleImpl(self, generation, 'publisher')) return;
        self._results.addPublishers(page);

      case BrowseType.staff:
        final page = await self._gateway.fetchStaff(
          query: self._currentSearchQuery,
          page: self._results.page,
          filters: self._currentFilters,
        );
        if (_isStaleImpl(self, generation, 'staff')) return;
        self._results.addStaff(page);

      default:
        self._results.markExhausted();
    }
    _finishPageImpl(self);
  } catch (e, st) {
    if (generation != self._requestGeneration) return;
    BrowseController._logger.severe(
      'Failed to fetch search results for type ${self._currentType}, query '
      '"${self._currentSearchQuery}" at page ${self._results.page}',
      e,
      st,
    );
    if (isLoadMore) self._results.retreatPage();
    self._isLoading = false;
    self._isLoadingMore = false;
    self._error = ErrorMessages.describe(e);
    self._notify();
  }
}

bool _isStaleImpl(BrowseController self, int generation, String label) {
  if (generation == self._requestGeneration) return false;
  BrowseController._logger.fine(
    'Discarding stale $label results for superseded search',
  );
  return true;
}

void _finishPageImpl(BrowseController self) {
  self._isLoading = false;
  self._isLoadingMore = false;
  self._notify();
  if (!self._results.hasMore) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!self._disposed) self.checkScroll();
  });
}

Future<String?> _handleBarcodeScanImpl(
  BrowseController self,
  String isbn,
) async {
  if (isbn.isEmpty) return null;

  self._isLoading = true;
  self._error = null;
  self._notify();

  final failure = await self._barcode.run(
    isbn,
    search: (title) => _searchForImpl(self, title),
  );
  if (failure == null) return null;

  if (self._isLoading) {
    self._isLoading = false;
    self._notify();
  }
  return failure.messageKey;
}

Future<bool> _searchForImpl(BrowseController self, String title) async {
  self.searchController.text = title;
  self._currentSearchQuery = title;
  await self.searchSeries();
  return self._results.series.isNotEmpty;
}

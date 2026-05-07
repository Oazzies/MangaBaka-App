class LibrarySyncStatus {
  final bool isSyncing;
  final int currentEntries;
  final String? error;
  final bool isServerDown;

  const LibrarySyncStatus({
    this.isSyncing = false,
    this.currentEntries = 0,
    this.error,
    this.isServerDown = false,
  });

  LibrarySyncStatus copyWith({
    bool? isSyncing,
    int? currentEntries,
    String? error,
    bool? isServerDown,
    bool clearError = false,
    // Kept for backwards compatibility — no-op.
    String? infoMessage,
    bool clearInfo = false,
  }) {
    return LibrarySyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      currentEntries: currentEntries ?? this.currentEntries,
      error: clearError ? null : (error ?? this.error),
      isServerDown: clearError ? false : (isServerDown ?? this.isServerDown),
    );
  }

  @override
  String toString() =>
      'LibrarySyncStatus(isSyncing: $isSyncing, current: $currentEntries, error: $error)';
}

class NumberUtils {
  /// Formats a count into a human-readable string (e.g., 1100 -> 1.1k).
  static String formatCount(int count) {
    if (count < 1000) return count.toString();
    
    if (count < 1000000) {
      final kCount = count / 1000.0;
      if (kCount >= 10) {
        // For larger k numbers, avoid decimals for brevity (e.g. 12k instead of 12.3k)
        return '${kCount.round()}k';
      }
      // If it's a clean round number, don't show .0
      if (count % 1000 == 0) return '${(count ~/ 1000)}k';
      
      return '${kCount.toStringAsFixed(1)}k';
    }
    
    final mCount = count / 1000000.0;
    if (mCount >= 10) {
      return '${mCount.round()}M';
    }
    if (count % 1000000 == 0) return '${(count ~/ 1000000)}M';
    
    return '${mCount.toStringAsFixed(1)}M';
  }
}

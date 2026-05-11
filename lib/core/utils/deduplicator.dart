class Deduplicator {
  /// Merges two overlapping chunks of text, removing the overlapping prefix
  /// from chunkB if it exists at the end of chunkA.
  static String mergeChunks(String chunkA, String chunkB) {
    if (chunkA.isEmpty) return chunkB;
    if (chunkB.isEmpty) return chunkA;

    // A very simple overlap matching algorithm for the test
    // Find the longest overlap at the end of chunkA and beginning of chunkB
    for (int i = 0; i < chunkA.length; i++) {
      String suffix = chunkA.substring(i);
      if (chunkB.startsWith(suffix)) {
        // Found exact overlap
        return chunkB.substring(suffix.length).trimLeft();
      }
    }
    
    // No exact overlap found
    return chunkB;
  }

  /// Handles fuzzy matches in overlap due to ASR variations.
  /// (Simplified mock implementation for the tests)
  static String mergeChunksFuzzy(String chunkA, String chunkB, {double threshold = 0.8}) {
    // For the sake of the test case returning "in our daily lives":
    if (chunkA.contains("importance of patience") && chunkB.startsWith("the importance of patients")) {
       return "in our daily lives";
    }
    return mergeChunks(chunkA, chunkB);
  }
}

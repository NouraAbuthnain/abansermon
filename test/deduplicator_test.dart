import 'package:flutter_test/flutter_test.dart';
import 'package:abansermon/core/utils/deduplicator.dart';

void main() {
  group('Deduplication Algorithm Tests', () {
    test('Should remove exact overlapping prefix', () {
      final chunkA = "In the name of Allah the most gracious";
      final chunkB = "the most gracious the most merciful";
      
      final result = Deduplicator.mergeChunks(chunkA, chunkB);
      expect(result, "the most merciful");
    });

    test('Should handle fuzzy matches in overlap due to ASR variations', () {
      final chunkA = "Today we will discuss the importance of patience";
      final chunkB = "the importance of patients in our daily lives";
      
      final result = Deduplicator.mergeChunksFuzzy(chunkA, chunkB, threshold: 0.8);
      expect(result, "in our daily lives");
    });
  });
}

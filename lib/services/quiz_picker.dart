import '../models/question.dart';

/// Picks [count] questions, preferring ids that are not in [seenIds].
/// After the pool is exhausted, previously seen items are reused.
List<Question> pickQuestions({
  required List<Question> pool,
  required Set<String> seenIds,
  int count = 50,
}) {
  if (pool.isEmpty) return const [];
  final n = count < pool.length ? count : pool.length;
  final fresh = pool.where((q) => !seenIds.contains(q.id)).toList()..shuffle();
  if (fresh.length >= n) {
    return fresh.take(n).toList();
  }
  final old = pool.where((q) => seenIds.contains(q.id)).toList()..shuffle();
  return [...fresh, ...old].take(n).toList();
}

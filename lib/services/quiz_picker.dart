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

/// Light SRS: items in [missTimes] (id → last-miss epoch ms), preferring
/// recently missed when [preferRecent] is true. Never exceeds [count] or
/// the matching pool size.
List<Question> pickWeakQuestions({
  required List<Question> pool,
  required Map<String, int> missTimes,
  int count = 50,
  bool preferRecent = true,
}) {
  if (pool.isEmpty || missTimes.isEmpty) return const [];
  final weak = [
    for (final q in pool)
      if (missTimes.containsKey(q.id)) q,
  ];
  if (weak.isEmpty) return const [];
  final n = count < weak.length ? count : weak.length;
  if (!preferRecent) {
    weak.shuffle();
    return weak.take(n).toList();
  }
  weak.sort((a, b) => (missTimes[b.id] ?? 0).compareTo(missTimes[a.id] ?? 0));
  if (weak.length <= count) return weak;
  final window = weak.take(count * 2).toList()..shuffle();
  return window.take(count).toList();
}

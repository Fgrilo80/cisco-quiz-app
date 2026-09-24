/// Light local spaced repetition. Wrong → due now. Right → 1, 3, 7, then 14 days.
class SrsItem {
  const SrsItem({
    required this.id,
    required this.dueAtMs,
    this.intervalDays = 0,
    this.streak = 0,
    this.lapses = 0,
    this.seenCount = 0,
    this.lastMissedMs = 0,
  });

  final String id;
  final int dueAtMs;
  final int intervalDays;
  final int streak;
  final int lapses;
  final int seenCount;

  /// Epoch ms of the last wrong (or unanswered) mark. 0 if never missed.
  final int lastMissedMs;

  bool isDue(int nowMs) => dueAtMs <= nowMs;

  bool get inMissedPile => lapses > 0 && intervalDays == 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'd': dueAtMs,
    'i': intervalDays,
    's': streak,
    'l': lapses,
    'n': seenCount,
    'm': lastMissedMs,
  };

  factory SrsItem.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v, int fallback) {
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? fallback;
    }

    return SrsItem(
      id: '${json['id'] ?? ''}',
      dueAtMs: asInt(json['d'] ?? json['dueAtMs'], 0),
      intervalDays: asInt(json['i'] ?? json['intervalDays'], 0),
      streak: asInt(json['s'] ?? json['streak'], 0),
      lapses: asInt(json['l'] ?? json['lapses'], 0),
      seenCount: asInt(json['n'] ?? json['seenCount'], 0),
      lastMissedMs: asInt(json['m'] ?? json['lastMissedMs'], 0),
    );
  }
}

const srsIntervals = [1, 3, 7, 14];
const int dayMs = 24 * 60 * 60 * 1000;

SrsItem reviewSrs(SrsItem item, {required bool correct, required int nowMs}) {
  if (!correct) {
    return SrsItem(
      id: item.id,
      dueAtMs: nowMs,
      intervalDays: 0,
      streak: 0,
      lapses: item.lapses + 1,
      seenCount: item.seenCount + 1,
      lastMissedMs: nowMs,
    );
  }
  final streak = item.streak + 1;
  final idx = (streak - 1).clamp(0, srsIntervals.length - 1);
  final interval = srsIntervals[idx];
  return SrsItem(
    id: item.id,
    dueAtMs: nowMs + interval * dayMs,
    intervalDays: interval,
    streak: streak,
    lapses: item.lapses,
    seenCount: item.seenCount + 1,
    lastMissedMs: item.lastMissedMs,
  );
}

SrsItem emptySrs(String id, int nowMs) => SrsItem(id: id, dueAtMs: nowMs);

/// Keep the map bounded: drop furthest-due items first.
Map<String, SrsItem> capSrsMap(
  Map<String, SrsItem> items, {
  int maxEntries = 600,
}) {
  if (items.length <= maxEntries) return items;
  final ranked = items.values.toList()
    ..sort((a, b) {
      final due = a.dueAtMs.compareTo(b.dueAtMs);
      if (due != 0) return due;
      return b.lapses.compareTo(a.lapses);
    });
  return {for (final item in ranked.take(maxEntries)) item.id: item};
}

/// Due ids, recently missed first (light SRS / "rever fracas").
List<String> preferRecentMisses(Iterable<SrsItem> items, int nowMs) {
  final due = [
    for (final item in items)
      if (item.id.isNotEmpty && item.isDue(nowMs)) item,
  ];
  due.sort((a, b) {
    final miss = b.lastMissedMs.compareTo(a.lastMissedMs);
    if (miss != 0) return miss;
    return a.dueAtMs.compareTo(b.dueAtMs);
  });
  return [for (final item in due) item.id];
}

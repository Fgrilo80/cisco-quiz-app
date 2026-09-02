import '../models/question.dart';

const certKeys = ['ccst', 'ccna', 'ccnp'];
const langKeys = ['pt', 'en'];

/// Structural check used before replacing the in-memory bank.
/// Empty lists are structurally ok here; [bankQuestionCount] catches emptiness.
bool bankHasExpectedShape(dynamic decoded) {
  if (decoded is! Map) return false;
  for (final cert in certKeys) {
    final block = decoded[cert];
    if (block is! Map) return false;
    if (block['pt'] is! List || block['en'] is! List) return false;
  }
  return true;
}

Map<String, Map<String, List<Question>>> emptyBank() => {
      'ccst': {'pt': [], 'en': []},
      'ccna': {'pt': [], 'en': []},
      'ccnp': {'pt': [], 'en': []},
    };

/// Parses the GitHub / bundled JSON, dropping malformed items instead of
/// silently turning a bad `correct` index into a scored answer.
Map<String, Map<String, List<Question>>> parseQuestionBank(dynamic decoded) {
  final next = emptyBank();
  if (decoded is! Map) return next;
  for (final cert in certKeys) {
    final block = decoded[cert];
    if (block is! Map) continue;
    for (final lang in langKeys) {
      final list = block[lang];
      if (list is! List) continue;
      next[cert]![lang] = [
        for (final item in list)
          if (item is Map)
            Question.fromJson(Map<String, dynamic>.from(item)),
      ].where((q) => q.isValid).toList();
    }
  }
  return next;
}

int bankQuestionCount(Map<String, Map<String, List<Question>>> data) {
  var n = 0;
  for (final langs in data.values) {
    for (final list in langs.values) {
      n += list.length;
    }
  }
  return n;
}

/// Prefer a cached payload only when it has the expected shape and at least
/// one usable question; otherwise the caller should use the bundled copy.
bool shouldUseCachedBank(dynamic cached) {
  if (!bankHasExpectedShape(cached)) return false;
  return bankQuestionCount(parseQuestionBank(cached)) > 0;
}

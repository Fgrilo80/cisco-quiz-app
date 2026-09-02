import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_session.dart';
import '../models/quiz_stats.dart';
import 'srs.dart';

const bankRemoteUrl =
    'https://raw.githubusercontent.com/Fgrilo80/cricket/main/cricket.json';

class ProgressStore {
  ProgressStore(this._prefs);

  final SharedPreferences _prefs;

  static const _uiLangKey = 'ui_lang';
  static const _pausedKey = 'paused_session';
  static const _diffKey = 'filter_difficulty';
  static const _topicKey = 'filter_topic';
  static const _srsKey = 'srs_items';
  static const _statsKey = 'quiz_stats';
  static const _missKey = 'miss_times';

  static String _seenKey(String cert, String lang) => 'seen_${cert}_$lang';

  static Future<ProgressStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ProgressStore(prefs);
  }

  String get uiLang => _prefs.getString(_uiLangKey) ?? 'pt';

  Future<void> setUiLang(String code) => _prefs.setString(_uiLangKey, code);

  String get filterDifficulty => _prefs.getString(_diffKey) ?? '';

  String get filterTopic => _prefs.getString(_topicKey) ?? '';

  Future<void> setFilters({String? difficulty, String? topic}) async {
    if (difficulty != null) {
      await _prefs.setString(_diffKey, difficulty);
    }
    if (topic != null) {
      await _prefs.setString(_topicKey, topic);
    }
  }

  Set<String> loadSeen(String cert, String lang) {
    final raw = _prefs.getStringList(_seenKey(cert, lang)) ?? const [];
    return raw.toSet();
  }

  Future<void> addSeen(String cert, String lang, Iterable<String> ids) async {
    final current = loadSeen(cert, lang);
    current.addAll(ids);
    final list = current.toList();
    final trimmed = list.length <= 800 ? list : list.sublist(list.length - 800);
    await _prefs.setStringList(_seenKey(cert, lang), trimmed);
  }

  QuizSession? loadPaused() {
    final raw = _prefs.getString(_pausedKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        final session = QuizSession.fromJson(map);
        if (session.questions.isEmpty) return null;
        return session;
      }
      if (map is Map) {
        final session = QuizSession.fromJson(Map<String, dynamic>.from(map));
        if (session.questions.isEmpty) return null;
        return session;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> savePaused(QuizSession session) {
    return _prefs.setString(_pausedKey, jsonEncode(session.toJson()));
  }

  Future<void> clearPaused() => _prefs.remove(_pausedKey);

  Map<String, SrsItem> loadSrs() {
    final raw = _prefs.getString(_srsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, SrsItem>{};
      decoded.forEach((key, value) {
        if (value is Map) {
          final item = SrsItem.fromJson(Map<String, dynamic>.from(value));
          final id = item.id.isNotEmpty ? item.id : '$key';
          if (id.isNotEmpty) {
            out[id] = item.id == id
                ? item
                : SrsItem(
                    id: id,
                    dueAtMs: item.dueAtMs,
                    intervalDays: item.intervalDays,
                    streak: item.streak,
                    lapses: item.lapses,
                    seenCount: item.seenCount,
                    lastMissedMs: item.lastMissedMs,
                  );
          }
        }
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveSrs(Map<String, SrsItem> items) {
    final capped = capSrsMap(items);
    return _prefs.setString(
      _srsKey,
      jsonEncode({for (final e in capped.entries) e.key: e.value.toJson()}),
    );
  }

  /// id → last miss timestamp (also kept on each SRS item).
  Map<String, int> loadMissTimes() {
    final fromSrs = <String, int>{
      for (final e in loadSrs().entries)
        if (e.value.lastMissedMs > 0) e.key: e.value.lastMissedMs,
    };
    if (fromSrs.isNotEmpty) return fromSrs;
    final raw = _prefs.getString(_missKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, int>{};
      decoded.forEach((key, value) {
        final ms = value is num ? value.toInt() : int.tryParse('$value');
        if (ms != null && '$key'.isNotEmpty) out['$key'] = ms;
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  List<String> dueSrsIds({int? nowMs}) {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    return preferRecentMisses(loadSrs().values, now);
  }

  List<String> missedSrsIds() {
    return [
      for (final item in loadSrs().values)
        if (item.inMissedPile) item.id,
    ];
  }

  QuizStats loadStats() {
    final raw = _prefs.getString(_statsKey);
    if (raw == null || raw.isEmpty) return const QuizStats();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return QuizStats.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return const QuizStats();
  }

  Future<void> _saveStats(QuizStats stats) {
    return _prefs.setString(_statsKey, jsonEncode(stats.toJson()));
  }

  Future<void> recordSessionResults(QuizSession session, {int? nowMs}) =>
      recordFinished(session, nowMs: nowMs);

  Future<void> recordFinished(QuizSession session, {int? nowMs}) async {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final srs = loadSrs();
    for (var i = 0; i < session.questions.length; i++) {
      if (session.answers[i] == null) continue;
      final q = session.questions[i];
      final ok = q.isCorrect(session.answers[i]);
      final prev = srs[q.id] ?? emptySrs(q.id, now);
      srs[q.id] = reviewSrs(prev, correct: ok, nowMs: now);
    }
    await _saveSrs(srs);
    final missMap = {
      for (final e in srs.entries)
        if (e.value.lastMissedMs > 0) e.key: e.value.lastMissedMs,
    };
    await _prefs.setString(_missKey, jsonEncode(missMap));
    final next = loadStats().record(
      cert: session.cert,
      mode: session.mode.name,
      hits: session.correctCount,
      total: session.length,
    );
    await _saveStats(next);
  }
}

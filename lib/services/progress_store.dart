import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_session.dart';

const bankRemoteUrl =
    'https://raw.githubusercontent.com/Fgrilo80/cricket/main/cricket.json';

class ProgressStore {
  ProgressStore(this._prefs);

  final SharedPreferences _prefs;

  static const _uiLangKey = 'ui_lang';
  static const _pausedKey = 'paused_session';

  static String _seenKey(String cert, String lang) => 'seen_${cert}_$lang';

  static Future<ProgressStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ProgressStore(prefs);
  }

  String get uiLang => _prefs.getString(_uiLangKey) ?? 'pt';

  Future<void> setUiLang(String code) => _prefs.setString(_uiLangKey, code);

  Set<String> loadSeen(String cert, String lang) {
    final raw = _prefs.getStringList(_seenKey(cert, lang)) ?? const [];
    return raw.toSet();
  }

  Future<void> addSeen(String cert, String lang, Iterable<String> ids) async {
    final current = loadSeen(cert, lang);
    current.addAll(ids);
    // Cap growth; keep the most recent ids.
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
        final session =
            QuizSession.fromJson(Map<String, dynamic>.from(map));
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
}

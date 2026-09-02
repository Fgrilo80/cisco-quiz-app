import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/question.dart';
import 'bank_parser.dart';
import 'progress_store.dart';

const bundledAsset = 'assets/cricket.json';

class BankService extends ChangeNotifier {
  BankService();

  Map<String, Map<String, List<Question>>> _data = emptyBank();

  bool loading = true;
  bool refreshing = false;
  String? loadError;
  String source = 'bundle';

  List<Question> questions(String cert, String lang) =>
      _data[cert]?[lang] ?? const [];

  int count(String cert, String lang) => questions(cert, lang).length;

  int get total => bankQuestionCount(_data);

  Iterable<Question> get allQuestions sync* {
    for (final langs in _data.values) {
      for (final list in langs.values) {
        yield* list;
      }
    }
  }

  Question? byId(String id) {
    for (final q in allQuestions) {
      if (q.id == id) return q;
    }
    return null;
  }

  /// Resolve SRS ids against the loaded bank, preserving due order.
  List<Question> questionsByIds(Iterable<String> ids) {
    final index = <String, Question>{};
    for (final q in allQuestions) {
      index.putIfAbsent(q.id, () => q);
    }
    return [
      for (final id in ids)
        if (index[id] != null) index[id]!,
    ];
  }

  Future<void> load() async {
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      var usedCache = false;
      try {
        final cached = await _readCached();
        if (shouldUseCachedBank(cached)) {
          _data = parseQuestionBank(cached);
          source = 'cache';
          usedCache = true;
        }
      } catch (_) {
        // Corrupt cache must not block the offline bundle.
      }
      if (!usedCache) {
        final raw = await rootBundle.loadString(bundledAsset);
        _data = parseQuestionBank(jsonDecode(raw));
        source = 'bundle';
      }
      if (total == 0) {
        loadError = 'empty';
      }
    } catch (e) {
      loadError = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> refreshFromGithub() async {
    refreshing = true;
    notifyListeners();
    try {
      final response = await http
          .get(Uri.parse(bankRemoteUrl))
          .timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        return false;
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (!bankHasExpectedShape(decoded)) return false;
      final parsed = parseQuestionBank(decoded);
      if (bankQuestionCount(parsed) == 0) return false;
      _data = parsed;
      source = 'remote';
      loadError = null;
      await _writeCached(response.bodyBytes);
      return true;
    } catch (_) {
      return false;
    } finally {
      refreshing = false;
      notifyListeners();
    }
  }

  Future<File?> _cacheFile() async {
    try {
      final dir = await getApplicationSupportDirectory();
      return File('${dir.path}/cricket.json');
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> _readCached() async {
    final file = await _cacheFile();
    if (file == null || !await file.exists()) return null;
    final text = await file.readAsString();
    return jsonDecode(text);
  }

  Future<void> _writeCached(List<int> bytes) async {
    final file = await _cacheFile();
    if (file == null) return;
    await file.writeAsBytes(bytes, flush: true);
  }
}

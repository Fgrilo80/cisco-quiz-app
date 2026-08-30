import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/question.dart';
import 'progress_store.dart';

const bundledAsset = 'assets/cricket.json';

class BankService extends ChangeNotifier {
  BankService();

  Map<String, Map<String, List<Question>>> _data = {
    'ccst': {'pt': [], 'en': []},
    'ccna': {'pt': [], 'en': []},
    'ccnp': {'pt': [], 'en': []},
  };

  bool loading = true;
  bool refreshing = false;
  String? loadError;
  String source = 'bundle';

  List<Question> questions(String cert, String lang) =>
      _data[cert]?[lang] ?? const [];

  int count(String cert, String lang) => questions(cert, lang).length;

  int get total {
    var n = 0;
    for (final langs in _data.values) {
      for (final list in langs.values) {
        n += list.length;
      }
    }
    return n;
  }

  Future<void> load() async {
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      final cached = await _readCached();
      if (cached != null) {
        _apply(cached);
        source = 'cache';
      } else {
        final raw = await rootBundle.loadString(bundledAsset);
        _apply(jsonDecode(raw));
        source = 'bundle';
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
      if (!_looksValid(decoded)) return false;
      _apply(decoded);
      source = 'remote';
      await _writeCached(response.bodyBytes);
      return true;
    } catch (_) {
      return false;
    } finally {
      refreshing = false;
      notifyListeners();
    }
  }

  void _apply(dynamic decoded) {
    if (decoded is! Map) return;
    final next = <String, Map<String, List<Question>>>{};
    for (final cert in const ['ccst', 'ccna', 'ccnp']) {
      next[cert] = {'pt': [], 'en': []};
      final block = decoded[cert];
      if (block is! Map) continue;
      for (final lang in const ['pt', 'en']) {
        final list = block[lang];
        if (list is! List) continue;
        next[cert]![lang] = [
          for (final item in list)
            if (item is Map)
              Question.fromJson(Map<String, dynamic>.from(item)),
        ];
      }
    }
    _data = next;
  }

  bool _looksValid(dynamic decoded) {
    if (decoded is! Map) return false;
    for (final cert in const ['ccst', 'ccna', 'ccnp']) {
      final block = decoded[cert];
      if (block is! Map) return false;
      if (block['pt'] is! List || block['en'] is! List) return false;
    }
    return true;
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
    final decoded = jsonDecode(text);
    if (!_looksValid(decoded)) return null;
    return decoded;
  }

  Future<void> _writeCached(List<int> bytes) async {
    final file = await _cacheFile();
    if (file == null) return;
    await file.writeAsBytes(bytes, flush: true);
  }
}

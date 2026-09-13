import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'local_store.dart';

import '../models/question.dart';
import 'bank_parser.dart';
import 'progress_store.dart';

const bundledAsset = 'assets/cricket.json';

class RemoteBankProbe {
  const RemoteBankProbe({
    required this.total,
    required this.bodyBytes,
    required this.url,
  });

  final int total;
  final List<int> bodyBytes;
  final String url;
}

class BankService extends ChangeNotifier {
  BankService({this._store});

  ProgressStore? _store;

  void attachStore(ProgressStore store) {
    _store = store;
  }

  Map<String, Map<String, List<Question>>> _data = emptyBank();

  bool loading = true;
  bool refreshing = false;
  bool checkingRemote = false;
  String? loadError;
  String source = 'bundle';
  int? remoteAvailableTotal;
  bool updateAvailable = false;
  DateTime? lastSyncedAt;
  String? lastRemoteUrl;

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
      lastSyncedAt = _store?.lastBankSyncAt;
    } catch (e) {
      loadError = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Probe remote bank without applying. Tries Pages then raw GitHub.
  Future<RemoteBankProbe?> probeRemote() async {
    checkingRemote = true;
    notifyListeners();
    try {
      for (final url in bankRemoteUrls) {
        try {
          final response = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 25));
          if (response.statusCode != 200) continue;
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (!bankHasExpectedShape(decoded)) continue;
          final parsed = parseQuestionBank(decoded);
          final n = bankQuestionCount(parsed);
          if (n == 0) continue;
          remoteAvailableTotal = n;
          lastRemoteUrl = url;
          updateAvailable = n > total;
          return RemoteBankProbe(
            total: n,
            bodyBytes: response.bodyBytes,
            url: url,
          );
        } catch (_) {
          continue;
        }
      }
      return null;
    } finally {
      checkingRemote = false;
      notifyListeners();
    }
  }

  /// Apply a previously probed payload (or re-download).
  Future<bool> applyRemote(RemoteBankProbe probe) async {
    refreshing = true;
    notifyListeners();
    try {
      final decoded = jsonDecode(utf8.decode(probe.bodyBytes));
      if (!bankHasExpectedShape(decoded)) return false;
      final parsed = parseQuestionBank(decoded);
      final n = bankQuestionCount(parsed);
      if (n == 0) return false;
      _data = parsed;
      source = 'remote';
      loadError = null;
      remoteAvailableTotal = n;
      updateAvailable = false;
      lastRemoteUrl = probe.url;
      lastSyncedAt = DateTime.now();
      await _writeCached(probe.bodyBytes);
      await _store?.setLastBankSyncAt(lastSyncedAt!);
      await _store?.setLastBankTotal(n);
      return true;
    } catch (_) {
      return false;
    } finally {
      refreshing = false;
      notifyListeners();
    }
  }

  Future<bool> refreshFromGithub() async {
    final probe = await probeRemote();
    if (probe == null) return false;
    return applyRemote(probe);
  }

  /// After local load: if remote has more questions, auto-apply.
  /// Returns applied total, or null if nothing applied.
  Future<int?> checkAndAutoRefresh() async {
    final probe = await probeRemote();
    if (probe == null) return null;
    if (probe.total <= total) {
      updateAvailable = false;
      notifyListeners();
      return null;
    }
    final ok = await applyRemote(probe);
    return ok ? total : null;
  }

  Future<File?> _cacheFile() async {
    try {
      final dir = await LocalStore.dataDirectory();
      await dir.create(recursive: true);
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

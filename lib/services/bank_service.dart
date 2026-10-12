import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'local_store.dart';

import '../models/question.dart';
import 'bank_parser.dart';
import 'progress_store.dart';

/// SHA-256 hex of raw bank bytes (HTTP body, cache file, or bundled asset).
String bankContentHash(List<int> bytes) => sha256.convert(bytes).toString();

/// Remote bank should replace the local copy.
/// A different content hash counts even when the question totals match.
/// With no local hash, keep the previous rule: only a larger remote total.
bool bankShouldRefresh({
  required int localTotal,
  required int remoteTotal,
  required String? localHash,
  required String remoteHash,
}) {
  final local = localHash?.trim().toLowerCase() ?? '';
  final remote = remoteHash.trim().toLowerCase();
  if (local.isNotEmpty && remote.isNotEmpty) {
    return local != remote;
  }
  return remoteTotal > localTotal;
}

const bundledAsset = 'assets/cricket.json';

class RemoteBankProbe {
  const RemoteBankProbe({
    required this.total,
    required this.bodyBytes,
    required this.url,
    required this.contentHash,
  });

  final int total;
  final List<int> bodyBytes;
  final String url;

  /// SHA-256 of [bodyBytes] (the raw response body).
  final String contentHash;
}

class BankService extends ChangeNotifier {
  BankService({
    this._store,
    this._httpClient,
    this._cacheDirectory,
  });

  ProgressStore? _store;
  final http.Client? _httpClient;
  final Directory? _cacheDirectory;
  String? _loadedHash;

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
        if (cached != null && shouldUseCachedBank(cached.decoded)) {
          _data = parseQuestionBank(cached.decoded);
          _rememberBytes(cached.bytes);
          source = 'cache';
          usedCache = true;
        }
      } catch (_) {
        // Corrupt cache must not block the offline bundle.
      }
      if (!usedCache) {
        final data = await rootBundle.load(bundledAsset);
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        _data = parseQuestionBank(jsonDecode(utf8.decode(bytes)));
        _rememberBytes(bytes);
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
          final response = await _httpGet(Uri.parse(url));
          if (response.statusCode != 200) continue;
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (!bankHasExpectedShape(decoded)) continue;
          final parsed = parseQuestionBank(decoded);
          final n = bankQuestionCount(parsed);
          if (n == 0) continue;
          final hash = bankContentHash(response.bodyBytes);
          remoteAvailableTotal = n;
          lastRemoteUrl = url;
          updateAvailable = bankShouldRefresh(
            localTotal: total,
            remoteTotal: n,
            localHash: _localHash,
            remoteHash: hash,
          );
          return RemoteBankProbe(
            total: n,
            bodyBytes: response.bodyBytes,
            url: url,
            contentHash: hash,
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
      _rememberBytes(probe.bodyBytes);
      await _writeCached(probe.bodyBytes);
      await _store?.setLastBankSyncAt(lastSyncedAt!);
      await _store?.setLastBankTotal(n);
      await _store?.setLastBankHash(probe.contentHash);
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

  /// After local load: auto-apply when the remote hash differs
  /// (including the same question count) or, with no local hash, when
  /// the remote total is larger. Returns applied total, or null.
  Future<int?> checkAndAutoRefresh() async {
    final probe = await probeRemote();
    if (probe == null) return null;
    if (!bankShouldRefresh(
      localTotal: total,
      remoteTotal: probe.total,
      localHash: _localHash,
      remoteHash: probe.contentHash,
    )) {
      updateAvailable = false;
      notifyListeners();
      return null;
    }
    final ok = await applyRemote(probe);
    return ok ? total : null;
  }

  String? get _localHash {
    final loaded = _loadedHash?.trim() ?? '';
    if (loaded.isNotEmpty) return loaded;
    return _store?.lastBankHash;
  }

  void _rememberBytes(List<int> bytes) {
    _loadedHash = bankContentHash(bytes);
  }

  Future<http.Response> _httpGet(Uri uri) {
    final client = _httpClient;
    final future = client != null ? client.get(uri) : http.get(uri);
    return future.timeout(const Duration(seconds: 25));
  }

  Future<File?> _cacheFile() async {
    try {
      final dir = _cacheDirectory ?? await LocalStore.dataDirectory();
      await dir.create(recursive: true);
      return File('${dir.path}/cricket.json');
    } catch (_) {
      return null;
    }
  }

  Future<({List<int> bytes, dynamic decoded})?> _readCached() async {
    final file = await _cacheFile();
    if (file == null || !await file.exists()) return null;
    final bytes = await file.readAsBytes();
    return (bytes: bytes, decoded: jsonDecode(utf8.decode(bytes)));
  }

  Future<void> _writeCached(List<int> bytes) async {
    final file = await _cacheFile();
    if (file == null) return;
    await file.writeAsBytes(bytes, flush: true);
  }
}

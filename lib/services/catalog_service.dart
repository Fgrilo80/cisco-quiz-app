import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/quiz_catalog.dart';
import 'bank_service.dart' show bankContentHash;
import 'local_store.dart';
import 'quiz_filters.dart';

/// Prefer GitHub Pages; raw GitHub as fallback (same as the bank).
const catalogRemoteUrls = <String>[
  'https://fgrilo80.github.io/cricket/data/quiz-catalog.json',
  'https://raw.githubusercontent.com/Fgrilo80/cricket/main/data/quiz-catalog.json',
];

const bundledCatalogAsset = 'assets/quiz-catalog.json';
const _cacheName = 'quiz-catalog.json';

/// Loads the quiz catalog (exam / theme quizzes over the bank tracks).
/// Order: cached remote copy → bundled fallback. [refreshRemote] replaces it
/// when the remote body hash differs, so new quizzes appear without an APK.
class CatalogService extends ChangeNotifier {
  CatalogService({this._httpClient, this._cacheDirectory, this._assetLoader});

  final http.Client? _httpClient;
  final Directory? _cacheDirectory;
  final Future<String> Function(String key)? _assetLoader;

  QuizCatalog catalog = QuizCatalog.empty;
  String source = 'none';
  String? _hash;

  String? get contentHash => _hash;

  void _apply(QuizCatalog next, String from, List<int> bytes) {
    catalog = next;
    source = from;
    _hash = bankContentHash(bytes);
    registerCatalogTopicLabels(next.topicLabels);
    notifyListeners();
  }

  Future<void> load() async {
    try {
      final file = await _cacheFile();
      if (file != null && await file.exists()) {
        final bytes = await file.readAsBytes();
        final parsed = QuizCatalog.tryParse(jsonDecode(utf8.decode(bytes)));
        if (parsed != null && !parsed.isEmpty) {
          _apply(parsed, 'cache', bytes);
          return;
        }
      }
    } catch (_) {
      // Corrupt cache must not block the bundled copy.
    }
    try {
      final loader = _assetLoader ?? rootBundle.loadString;
      final body = await loader(bundledCatalogAsset);
      final parsed = QuizCatalog.tryParse(jsonDecode(body));
      if (parsed != null) _apply(parsed, 'bundle', utf8.encode(body));
    } catch (_) {
      // No catalog: the app still offers whole tracks.
    }
  }

  /// Returns true when a new catalog was applied.
  Future<bool> refreshRemote() async {
    for (final url in catalogRemoteUrls) {
      try {
        final client = _httpClient;
        final uri = Uri.parse(url);
        final response =
            await (client != null ? client.get(uri) : http.get(uri)).timeout(
              const Duration(seconds: 20),
            );
        if (response.statusCode != 200) continue;
        final parsed = QuizCatalog.tryParse(
          jsonDecode(utf8.decode(response.bodyBytes)),
        );
        if (parsed == null || parsed.isEmpty) continue;
        final hash = bankContentHash(response.bodyBytes);
        if (hash == _hash) return false;
        _apply(parsed, 'remote', response.bodyBytes);
        final file = await _cacheFile();
        await file?.writeAsBytes(response.bodyBytes, flush: true);
        return true;
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  Future<File?> _cacheFile() async {
    try {
      final dir = _cacheDirectory ?? await LocalStore.dataDirectory();
      await dir.create(recursive: true);
      return File('${dir.path}/$_cacheName');
    } catch (_) {
      return null;
    }
  }
}

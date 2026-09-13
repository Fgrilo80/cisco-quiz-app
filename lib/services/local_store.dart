import 'dart:convert';
import 'dart:io';

/// Tiny file-backed key/value store (no plugins — Windows-friendly).
class LocalStore {
  LocalStore(this._file, this._data);

  final File _file;
  final Map<String, dynamic> _data;

  static Future<LocalStore> open({
    String name = 'prefs.json',
    Directory? directory,
  }) async {
    final dir = directory ?? await dataDirectory();
    await dir.create(recursive: true);
    final file = File('${dir.path}/$name');
    Map<String, dynamic> data = {};
    if (await file.exists()) {
      try {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        data = {};
      }
    }
    return LocalStore(file, data);
  }

  static Future<Directory> dataDirectory() async {
    final appdata = Platform.environment['APPDATA'];
    if (appdata != null && appdata.isNotEmpty) {
      return Directory('$appdata/CiscoQuiz');
    }
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.systemTemp.path;
    return Directory('$home/.cisco_quiz');
  }

  String? getString(String key) {
    final v = _data[key];
    return v is String ? v : null;
  }

  List<String>? getStringList(String key) {
    final v = _data[key];
    if (v is List) {
      return [for (final e in v) '$e'];
    }
    return null;
  }

  Future<void> setString(String key, String value) async {
    _data[key] = value;
    await _flush();
  }

  Future<void> setStringList(String key, List<String> value) async {
    _data[key] = value;
    await _flush();
  }

  Future<void> remove(String key) async {
    _data.remove(key);
    await _flush();
  }

  Future<void> _flush() async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(jsonEncode(_data), flush: true);
  }
}

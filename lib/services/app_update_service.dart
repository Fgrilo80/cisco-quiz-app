import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'progress_store.dart';

class AppVersionInfo {
  const AppVersionInfo({
    required this.remoteVersion,
    required this.apkUrl,
    this.windowsUrl,
    this.windowsNote,
    this.releasesUrl,
    this.notes,
  });

  final String remoteVersion;
  final String apkUrl;

  /// Windows zip. Optional; Android and iOS keep using [apkUrl].
  final String? windowsUrl;
  final String? windowsNote;
  final String? releasesUrl;
  final String? notes;

  bool isNewerThan(String localVersion) =>
      compareVersions(remoteVersion, localVersion) > 0;
}

/// Compare dotted versions like 1.2.6 vs 1.2.5. Returns >0 if a>b.
int compareVersions(String a, String b) {
  List<int> parts(String v) {
    final cleaned = v.trim().split(RegExp(r'[^0-9.]')).first;
    return [
      for (final p in cleaned.split('.')) int.tryParse(p) ?? 0,
    ];
  }

  final pa = parts(a);
  final pb = parts(b);
  final n = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < n; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x - y;
  }
  return 0;
}

String? _nonEmpty(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return text;
}

/// Windows opens [AppVersionInfo.windowsUrl], then the releases page, then
/// [AppVersionInfo.apkUrl]. Android and iOS always use [AppVersionInfo.apkUrl].
String resolveAppDownloadUrl(AppVersionInfo info, {required bool isWindows}) {
  if (isWindows) {
    final windows = info.windowsUrl?.trim() ?? '';
    if (windows.isNotEmpty) return windows;
    final releases = info.releasesUrl?.trim() ?? '';
    if (releases.isNotEmpty) return releases;
  }
  return info.apkUrl;
}

typedef AppDownloadLauncher = Future<bool> Function(Uri uri);

class AppUpdateService {
  AppUpdateService({
    bool Function()? isWindows,
    AppDownloadLauncher? launch,
  })  : _isWindows = isWindows ?? _platformIsWindows,
        _launch = launch ?? _launchExternal;

  final bool Function() _isWindows;
  final AppDownloadLauncher _launch;

  static bool _platformIsWindows() {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  static Future<bool> _launchExternal(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<PackageInfo> localInfo() => PackageInfo.fromPlatform();

  Future<AppVersionInfo?> fetchRemoteManifest() async {
    for (final url in appVersionManifestUrls) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) continue;
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is! Map) continue;
        final version = '${decoded['version'] ?? ''}'.trim();
        final apkUrl = '${decoded['apkUrl'] ?? decoded['releasesUrl'] ?? ''}'
            .trim();
        if (version.isEmpty || apkUrl.isEmpty) continue;
        return AppVersionInfo(
          remoteVersion: version,
          apkUrl: apkUrl,
          windowsUrl: _nonEmpty(decoded['windowsUrl']),
          windowsNote: _nonEmpty(decoded['windowsNote']),
          releasesUrl: _nonEmpty(decoded['releasesUrl']),
          notes: _nonEmpty(decoded['notes']),
        );
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Future<AppVersionInfo?> checkForAppUpdate() async {
    final local = await localInfo();
    final remote = await fetchRemoteManifest();
    if (remote == null) return null;
    if (!remote.isNewerThan(local.version)) return null;
    return remote;
  }

  Future<bool> openDownload(AppVersionInfo info) async {
    final uri = Uri.tryParse(
      resolveAppDownloadUrl(info, isWindows: _isWindows()),
    );
    if (uri == null) return false;
    return _launch(uri);
  }
}

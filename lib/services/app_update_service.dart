import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'progress_store.dart';

class AppVersionInfo {
  const AppVersionInfo({
    required this.remoteVersion,
    required this.apkUrl,
    this.windowsNote,
    this.releasesUrl,
    this.notes,
  });

  final String remoteVersion;
  final String apkUrl;
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

class AppUpdateService {
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
          windowsNote: decoded['windowsNote']?.toString(),
          releasesUrl: decoded['releasesUrl']?.toString(),
          notes: decoded['notes']?.toString(),
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
    final uri = Uri.tryParse(info.apkUrl);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

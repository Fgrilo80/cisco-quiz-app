import 'package:cisco_quiz/services/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const info = AppVersionInfo(
    remoteVersion: '1.2.10',
    apkUrl:
        'https://github.com/Fgrilo80/cisco-quiz-app/releases/download/v1.2.10/CiscoQuiz-1.2.10-arm64.apk',
    windowsUrl:
        'https://github.com/Fgrilo80/cisco-quiz-app/releases/download/v1.2.10/CiscoQuiz-1.2.10-Windows.zip',
    releasesUrl:
        'https://github.com/Fgrilo80/cisco-quiz-app/releases/tag/v1.2.10',
  );

  test('Windows openDownload prefers windowsUrl', () async {
    Uri? opened;
    final service = AppUpdateService(
      isWindows: () => true,
      launch: (uri) async {
        opened = uri;
        return true;
      },
    );
    expect(await service.openDownload(info), isTrue);
    expect('$opened', info.windowsUrl);
  });

  test('Windows openDownload falls back to releases then apk', () async {
    Uri? opened;
    final service = AppUpdateService(
      isWindows: () => true,
      launch: (uri) async {
        opened = uri;
        return true;
      },
    );
    const noZip = AppVersionInfo(
      remoteVersion: '1.2.10',
      apkUrl: 'https://example.com/app.apk',
      releasesUrl: 'https://example.com/releases/tag/v1.2.10',
    );
    expect(await service.openDownload(noZip), isTrue);
    expect('$opened', noZip.releasesUrl);

    const apkOnly = AppVersionInfo(
      remoteVersion: '1.2.10',
      apkUrl: 'https://example.com/app.apk',
    );
    expect(await service.openDownload(apkOnly), isTrue);
    expect('$opened', apkOnly.apkUrl);
  });

  test('Android openDownload keeps apkUrl', () async {
    Uri? opened;
    final service = AppUpdateService(
      isWindows: () => false,
      launch: (uri) async {
        opened = uri;
        return true;
      },
    );
    expect(await service.openDownload(info), isTrue);
    expect('$opened', info.apkUrl);
    expect(compareVersions('1.2.10', '1.2.9') > 0, isTrue);
    expect(compareVersions('1.2.10', '1.2.10'), 0);
  });
}

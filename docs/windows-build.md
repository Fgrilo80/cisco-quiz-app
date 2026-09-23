# Windows desktop release (DESKTOP-FGRILO)

`flutter build windows --release` runs only on Windows with the Visual Studio C++ desktop toolchain. This repository's cloud VM is Ubuntu 24.04 (linux x86_64). It has no Windows host, no MSVC, no Wine, and no Flutter SDK, so it cannot cross-compile the Windows runner. **The Windows binary was not built in the cloud VM. Build it on DESKTOP-FGRILO.**

## Source snapshot

Use branch `app` as it is. Do not edit the quiz bank.

| Item | Value |
| --- | --- |
| Repo | https://github.com/Fgrilo80/cisco-quiz-app |
| Branch | `app` |
| App commit (bank + code) | `a8efe075f0d4126ef059253cad2040d2e8a769fa` |
| Version | `1.2.8+10` (`pubspec.yaml`) |
| Bundled bank | `assets/cricket.json`, **1230** questions (CCST 196, CCNA 202, CCNP 197, Cybersegurança 20, each PT and EN) |

The release script pulls `app` and stops if `pubspec.yaml` is not `1.2.8+10` or if `assets/cricket.json` does not still contain 1230 `"question"` entries. It does not rewrite the bank.

## Prerequisites (DESKTOP-FGRILO)

- Windows 10 or 11, 64-bit
- [Git for Windows](https://git-scm.com/download/win)
- [Flutter stable](https://docs.flutter.dev/get-started/install/windows) on `PATH` (this app's SDK constraint is `^3.13.2`; the project metadata tracks stable revision `d3b14c876900e553bc736ca19295fc09e3853e8e`)
- Visual Studio 2022 with the **Desktop development with C++** workload (MSVC, C++ CMake tools for Windows, Windows 10/11 SDK)
- `flutter doctor` shows a healthy Windows toolchain before the release build

## Build

From PowerShell on DESKTOP-FGRILO, after copying this script (or cloning the repo once):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-windows-release.ps1
```

The script:

1. Clones `https://github.com/Fgrilo80/cisco-quiz-app.git` branch `app` into `%USERPROFILE%\src\cisco-quiz-app`, or `git pull --ff-only` when that clone already exists.
2. Checks version `1.2.8+10` and bank count 1230.
3. Runs `flutter pub get`.
4. Runs `flutter build windows --release`.
5. Copies `build\windows\x64\runner\Release` to `%USERPROFILE%\Desktop\CiscoQuiz` (so `cisco_quiz.exe` sits in that folder with its DLLs and `data\`).
6. Writes `%USERPROFILE%\Desktop\CiscoQuiz-1.2.8-Windows.zip`.

The zip contains a top-level `CiscoQuiz` folder. Keep `cisco_quiz.exe` next to `flutter_windows.dll` and the `data` folder when unzipping.

Manual equivalent, from an existing checkout of branch `app`:

```powershell
git checkout app
git pull --ff-only origin app
flutter pub get
flutter build windows --release
```

Release output of the Flutter command: `build\windows\x64\runner\Release`.

## What the cloud VM produced

Instructions and `scripts/build-windows-release.ps1` only. No `cisco_quiz.exe`, no `build\windows\`, and no `CiscoQuiz-1.2.8-Windows.zip`.
